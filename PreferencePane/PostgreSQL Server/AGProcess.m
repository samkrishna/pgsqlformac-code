// AGProcess.m
//
// Copyright (c) 2002 Aram Greenman. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "AGProcess.h"
#import <Foundation/Foundation.h>
#include <mach/mach_host.h>
#include <mach/mach_port.h>
#include <mach/mach_traps.h>
#include <mach/task.h>
#include <mach/thread_act.h>
#include <mach/vm_map.h>
#include <sys/param.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <signal.h>
#include <unistd.h>

static kern_return_t
AGGetMachTaskMemoryUsage(task_t task, unsigned *virtual_size, unsigned *resident_size, double *percent) {
	kern_return_t error;
	struct task_basic_info t_info;
	struct host_basic_info h_info;
	struct vm_region_basic_info_64 vm_info;
	mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT, h_info_count = HOST_BASIC_INFO_COUNT, vm_info_count = VM_REGION_BASIC_INFO_COUNT_64;
	vm_address_t address = 0x70000000;
	vm_size_t size, fw_size = 0x20000000, fw_text_size = 0x10000000;
	mach_port_t object_name;
	
	if ((error = task_info(task, TASK_BASIC_INFO, (task_info_t)&t_info, &t_info_count)) != KERN_SUCCESS)
		return error;
	if ((error = host_info(mach_host_self(), HOST_BASIC_INFO, (host_info_t)&h_info, &h_info_count)) != KERN_SUCCESS)
		return error;
		
	// check for firmware split libraries
	// this is copied from the ps source code
	if ((error = vm_region_64(task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)&vm_info, &vm_info_count, &object_name)) != KERN_SUCCESS)
		return error;
	
	if (vm_info.reserved && size == fw_text_size && t_info.virtual_size > fw_size)
		t_info.virtual_size -= fw_size;
		
	if (virtual_size != NULL) *virtual_size = t_info.virtual_size;
	if (resident_size != NULL) *resident_size = t_info.resident_size;
	if (percent != NULL) *percent = (double)t_info.resident_size / h_info.memory_size;
	
	return error;
}

static kern_return_t
AGGetMachThreadCPUUsage(thread_t thread, double *user_time, double *system_time, double *percent) {
	kern_return_t error;
	struct thread_basic_info th_info;
	mach_msg_type_number_t th_info_count = THREAD_BASIC_INFO_COUNT;
	
	if ((error = thread_info(thread, THREAD_BASIC_INFO, (thread_info_t)&th_info, &th_info_count)) != KERN_SUCCESS)
		return error;
	
	if (user_time != NULL) *user_time = th_info.user_time.seconds + th_info.user_time.microseconds / 1e6;
	if (system_time != NULL) *system_time = th_info.system_time.seconds + th_info.system_time.microseconds / 1e6;
	if (percent != NULL) *percent = (double)th_info.cpu_usage / TH_USAGE_SCALE;
	
	return error;
}

static kern_return_t
AGGetMachTaskCPUUsage(task_t task, double *user_time, double *system_time, double *percent) {
	kern_return_t error;
	struct task_basic_info t_info;
	thread_array_t th_array;
	mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT, th_count;
	int i;
	double my_user_time = 0, my_system_time = 0, my_percent = 0;
	
	if ((error = task_info(task, TASK_BASIC_INFO, (task_info_t)&t_info, &t_info_count)) != KERN_SUCCESS)
		return error;
	if ((error = task_threads(task, &th_array, &th_count)) != KERN_SUCCESS)
		return error;
	
	// sum time for live threads
	for (i = 0; i < th_count; i++) {
		double th_user_time, th_system_time, th_percent;
		if ((error = AGGetMachThreadCPUUsage(th_array[i], &th_user_time, &th_system_time, &th_percent)) != KERN_SUCCESS)
			break;
		my_user_time += th_user_time;
		my_system_time += th_system_time;
		my_percent += th_percent;
	}
	
	// destroy thread array
	for (i = 0; i < th_count; i++)
		mach_port_deallocate(mach_task_self(), th_array[i]);
	vm_deallocate(mach_task_self(), (vm_address_t)th_array, sizeof(thread_t) * th_count);
	
	// check last error
	if (error != KERN_SUCCESS)
		return error;
	
	// add time for dead threads
	my_user_time += t_info.user_time.seconds + t_info.user_time.microseconds / 1e6;
	my_system_time += t_info.system_time.seconds + t_info.system_time.microseconds / 1e6;
	
	if (user_time != NULL) *user_time = my_user_time;
	if (system_time != NULL) *system_time = my_system_time;
	if (percent != NULL) *percent = my_percent;
		
	return error;
}

static kern_return_t
AGGetMachThreadPriority(thread_t thread, int *current_priority, int *base_priority) {
	kern_return_t error;
	struct thread_basic_info th_info;
	mach_msg_type_number_t th_info_count = THREAD_BASIC_INFO_COUNT;
	int my_current_priority = 0;
    int my_base_priority = 0;
	
	if ((error = thread_info(thread, THREAD_BASIC_INFO, (thread_info_t)&th_info, &th_info_count)) != KERN_SUCCESS)
		return error;
	
	switch (th_info.policy) {
        case POLICY_TIMESHARE: {
            struct policy_timeshare_info pol_info;
            mach_msg_type_number_t pol_info_count = POLICY_TIMESHARE_INFO_COUNT;
            
            if ((error = thread_info(thread, THREAD_SCHED_TIMESHARE_INFO, (thread_info_t)&pol_info, &pol_info_count)) != KERN_SUCCESS)
                return error;
            my_current_priority = pol_info.cur_priority;
            my_base_priority = pol_info.base_priority;
            break;
        } case POLICY_RR: {
            struct policy_rr_info pol_info;
            mach_msg_type_number_t pol_info_count = POLICY_RR_INFO_COUNT;
            
            if ((error = thread_info(thread, THREAD_SCHED_RR_INFO, (thread_info_t)&pol_info, &pol_info_count)) != KERN_SUCCESS)
                return error;
            my_current_priority = my_base_priority = pol_info.base_priority;
            break;
        } case POLICY_FIFO: {
            struct policy_fifo_info pol_info;
            mach_msg_type_number_t pol_info_count = POLICY_FIFO_INFO_COUNT;
            
            if ((error = thread_info(thread, THREAD_SCHED_FIFO_INFO, (thread_info_t)&pol_info, &pol_info_count)) != KERN_SUCCESS)
                return error;
            my_current_priority = my_base_priority = pol_info.base_priority;
            break;
        }
	}
	
	if (current_priority != NULL) *current_priority = my_current_priority;
	if (base_priority != NULL) *base_priority = my_base_priority;
		
	return error;
}

static kern_return_t
AGGetMachTaskPriority(task_t task, int *current_priority, int *base_priority) {
	kern_return_t error;
	thread_array_t th_array;
	mach_msg_type_number_t th_count;
	int i;
	int my_current_priority = 0, my_base_priority = 0;
	
	if ((error = task_threads(task, &th_array, &th_count)) != KERN_SUCCESS)
		return error;
	
	for (i = 0; i < th_count; i++) {
		int th_current_priority, th_base_priority;
		if ((error = AGGetMachThreadPriority(th_array[i], &th_current_priority, &th_base_priority)) != KERN_SUCCESS)
			break;
		if (th_current_priority > my_current_priority)
			my_current_priority = th_current_priority;
		if (th_base_priority > my_base_priority)
			my_base_priority = th_base_priority;
	}
	
	// destroy thread array
	for (i = 0; i < th_count; i++)
		mach_port_deallocate(mach_task_self(), th_array[i]);
	vm_deallocate(mach_task_self(), (vm_address_t)th_array, sizeof(thread_t) * th_count);
	
	// check last error
	if (error != KERN_SUCCESS)
		return error;
	
	if (current_priority != NULL) *current_priority = my_current_priority;
	if (base_priority != NULL) *base_priority = my_base_priority;
	
	return error;
}

static kern_return_t
AGGetMachThreadState(thread_t thread, int *state) {
	kern_return_t error;
	struct thread_basic_info th_info;
	mach_msg_type_number_t th_info_count = THREAD_BASIC_INFO_COUNT;
	int my_state;
	
	if ((error = thread_info(thread, THREAD_BASIC_INFO, (thread_info_t)&th_info, &th_info_count)) != KERN_SUCCESS)
		return error;
		
	switch (th_info.run_state) {
	case TH_STATE_RUNNING:
		my_state = AGProcessStateRunnable;
		break;
	case TH_STATE_UNINTERRUPTIBLE:
		my_state = AGProcessStateUninterruptible;
		break;
	case TH_STATE_WAITING:
		my_state = th_info.sleep_time > 20 ? AGProcessStateIdle : AGProcessStateSleeping;
		break;
	case TH_STATE_STOPPED:
		my_state = AGProcessStateSuspended;
		break;
	case TH_STATE_HALTED:
		my_state = AGProcessStateZombie;
		break;
	default:
		my_state = AGProcessStateUnknown;
	}
	
	if (state != NULL) *state = my_state;
	
	return error;
}

static kern_return_t
AGGetMachTaskState(task_t task, int *state) {
	kern_return_t error;
	thread_array_t th_array;
	mach_msg_type_number_t th_count;
	int i;
	int my_state = INT_MAX;
	
	if ((error = task_threads(task, &th_array, &th_count)) != KERN_SUCCESS)
		return error;
	
	for (i = 0; i < th_count; i++) {
		int th_state;
		if ((error = AGGetMachThreadState(th_array[i], &th_state)) != KERN_SUCCESS)
			break;
		// most active state takes precedence
		if (th_state < my_state)
			my_state = th_state;
	}
	
	// destroy thread array
	for (i = 0; i < th_count; i++)
		mach_port_deallocate(mach_task_self(), th_array[i]);
	vm_deallocate(mach_task_self(), (vm_address_t)th_array, sizeof(thread_t) * th_count);
	
	// check last error
	if (error != KERN_SUCCESS)
		return error;
		
	if (state != NULL) *state = my_state;
	
	return error;
}

static kern_return_t
AGGetMachTaskThreadCount(task_t task, int *count) {
	kern_return_t error;
	thread_array_t th_array;
	mach_msg_type_number_t th_count;
	int i;
	
	if ((error = task_threads(task, &th_array, &th_count)) != KERN_SUCCESS)
		return error;
	
	for (i = 0; i < th_count; i++)
		mach_port_deallocate(mach_task_self(), th_array[i]);
	vm_deallocate(mach_task_self(), (vm_address_t)th_array, sizeof(thread_t) * th_count);
	
	if (count != NULL) *count = th_count;
	
	return error;
}

@interface AGProcess (Private)
+ (NSArray *)processesForThirdLevelName:(int)name value:(int)value;
- (void)doProcargs;
@end

@implementation AGProcess (Private)
	
+ (NSArray *)processesForThirdLevelName:(int)name value:(int)value {
	AGProcess *proc;
	NSMutableArray *processes = [NSMutableArray array];
	int mib[4] = { CTL_KERN, KERN_PROC, name, value };
	struct kinfo_proc *info;
	size_t length;
	int level, count, i;
	
	// KERN_PROC_ALL has 3 elements, all others have 4
	level = name == KERN_PROC_ALL ? 3 : 4;
	
	if (sysctl(mib, level, NULL, &length, NULL, 0) < 0)
		return processes;
	if (!(info = NSZoneMalloc(NULL, length)))
		return processes;
	if (sysctl(mib, level, info, &length, NULL, 0) < 0) {
		NSZoneFree(NULL, info);
		return processes;
	}
	
	// number of processes
	count = length / sizeof(struct kinfo_proc);
		
	for (i = 0; i < count; i++) {
        proc = [[self alloc] initWithProcessIdentifier:info[i].kp_proc.p_pid];
		if (proc)
            [processes addObject:proc];
	}
	
	NSZoneFree(NULL, info);
	return processes;
}

- (void)doProcargs {       
	id args = [NSMutableArray array];
	id env = [NSMutableDictionary dictionary];
	size_t length = 4096; // max buffer accepted by sysctl() KERN_PROCARGS
	char buffer[length + 1];
	int mib[3] = { CTL_KERN, KERN_PROCARGS, process };
	int offset, last_offset, i;
	BOOL word;
	char c;
	
	// make sure this is only executed once for an instance
	if (command)
		return;
		
	if (sysctl(mib, 3, buffer, &length, NULL, 0) < 0) {  
		// probably a zombie or exited proc, try to at least get the accounting name
		struct kinfo_proc info;
		size_t length = sizeof(struct kinfo_proc);
		int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process };
		
		if (sysctl(mib, 4, &info, &length, NULL, 0) < 0)
			command = [[NSString alloc] init];
		else
			command = [[NSString alloc] initWithCString:info.kp_proc.p_comm encoding:NSUTF8StringEncoding];
		
	} else {
		// find the comm string, should be the first non-garbage string in the buffer
		offset = last_offset = 0;
		buffer[length] = NULL; // prevent buffer overrun
		
		do {
			for ( ; offset < length; offset++) {
				if (buffer[offset]) { // found a chunk of data
					last_offset = offset;
					word = YES;
					for ( ; offset < length; offset++) {
						if (!(c = buffer[offset])) // reached end of data
							break;
						if (!(isprint(c))) // found a non-printing character
							word = NO;
					}
					if (word)
						break;
				}
			}
			command = [[NSString stringWithCString:buffer + last_offset encoding:NSMacOSRomanStringEncoding] lastPathComponent];
		} while ([command isEqualToString:@"LaunchCFMApp"]);  // skip LaunchCFMApp
		
		
		// get rest of args and env
		for ( ; offset < length; offset++) {
			if (buffer[offset]) {
				NSString *string = [NSString stringWithCString:buffer + offset encoding:NSMacOSRomanStringEncoding];
				[args addObject:string];
				offset += [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
			}
		}
		
		// count backwards past env
		// first string which does not contain an '=' should usually be the last arg             	

		// ** THIS IS THE CRASH POINT ***
		
		for (i = [args count] - 1; i > 0; i--) {
			NSString *string = args[i];
			NSInteger index = [string rangeOfString:@"="].location;
			if (index == NSNotFound)
				break;
			if (index >= 0) {
				env[[string substringToIndex:index]] = [string substringFromIndex:index + 1];
			}
		}
		args = [args subarrayWithRange:NSMakeRange(0, i + 1)];
	}
	
	if (![args count])
		args = @[command];
	arguments = args;
	environment = env;
}    

@end

@implementation AGProcess
	
- (id)initWithProcessIdentifier:(int)pid {
	if (self = [super init]) {
		process = pid;
		if (task_for_pid(mach_task_self(), process, &task) != KERN_SUCCESS)
			task = MACH_PORT_NULL;
		if ([self state] == AGProcessStateExited) {
			return nil;
		}
	}
	return self;
}

+ (AGProcess *)currentProcess {
	return [self processForProcessIdentifier:getpid()];
}

+ (NSArray *)allProcesses {
	return [self processesForThirdLevelName:KERN_PROC_ALL value:0];
}

+ (NSArray *)userProcesses {
	return [self processesForUser:geteuid()];
}

+ (AGProcess *)processForProcessIdentifier:(int)pid {
	return [[self alloc] initWithProcessIdentifier:pid];
}
	
+ (NSArray *)processesForProcessGroup:(int)pgid {
	return [self processesForThirdLevelName:KERN_PROC_PGRP value:pgid];
}
	
+ (NSArray *)processesForTerminal:(int)tty {
	return [self processesForThirdLevelName:KERN_PROC_TTY value:tty];
}
	
+ (NSArray *)processesForUser:(int)uid {
	return [self processesForThirdLevelName:KERN_PROC_UID value:uid];
}
	
+ (NSArray *)processesForRealUser:(int)ruid {
	return [self processesForThirdLevelName:KERN_PROC_RUID value:ruid];
}
	
+ (NSArray *)processesForCommand:(NSString *)comm {
	NSArray *all = [self allProcesses];
	NSMutableArray *result = [NSMutableArray array];
	int i, count = [all count];
	for (i = 0; i < count; i++)
		if ([[all[i] command] isEqualToString:comm])
			[result addObject:all[i]];
	return result;
}
	
+ (AGProcess *)processForCommand:(NSString *)comm {
	NSArray *processes = [self processesForCommand:comm];
	if ([processes count])
		return processes[0];
	return nil;
}
	
- (int)processIdentifier {
	return process;
}
	
- (int)parentProcessIdentifier {
	struct kinfo_proc info;
	size_t length = sizeof(struct kinfo_proc);
	int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process };
	if (sysctl(mib, 4, &info, &length, NULL, 0) < 0)
		return AGProcessValueUnknown;
	if (length == 0)
		return AGProcessValueUnknown;
	return info.kp_eproc.e_ppid;
}
	
- (int)processGroup {
	struct kinfo_proc info;
	size_t length = sizeof(struct kinfo_proc);
	int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process };
	if (sysctl(mib, 4, &info, &length, NULL, 0) < 0)
		return AGProcessValueUnknown;
	if (length == 0)
		return AGProcessValueUnknown;
	return info.kp_eproc.e_pgid;
}
	
- (int)terminal {
	struct kinfo_proc info;
	size_t length = sizeof(struct kinfo_proc);
	int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process };
	if (sysctl(mib, 4, &info, &length, NULL, 0) < 0)
		return AGProcessValueUnknown;
	if (length == 0 || info.kp_eproc.e_tdev == 0)
		return AGProcessValueUnknown;
	return info.kp_eproc.e_tdev;
}
	
- (int)terminalProcessGroup {
	struct kinfo_proc info;
	size_t length = sizeof(struct kinfo_proc);
	int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process };
	if (sysctl(mib, 4, &info, &length, NULL, 0) < 0)
		return AGProcessValueUnknown;
	if (length == 0 || info.kp_eproc.e_tpgid == 0)
		return AGProcessValueUnknown;
	return info.kp_eproc.e_tpgid;
}

- (int)userIdentifier {
	struct kinfo_proc info;
	size_t length = sizeof(struct kinfo_proc);
	int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process };
	if (sysctl(mib, 4, &info, &length, NULL, 0) < 0)
		return AGProcessValueUnknown;
	if (length == 0)
		return AGProcessValueUnknown;
	return info.kp_eproc.e_ucred.cr_uid;
}
	
- (int)realUserIdentifier {
	struct kinfo_proc info;
	size_t length = sizeof(struct kinfo_proc);
	int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process };
	if (sysctl(mib, 4, &info, &length, NULL, 0) < 0)
		return AGProcessValueUnknown;
	if (length == 0)
		return AGProcessValueUnknown;
	return info.kp_eproc.e_pcred.p_ruid;
}
	
- (NSString *)command {
	[self doProcargs];
	return command;
}
	
- (NSArray *)arguments {
	[self doProcargs];
	return arguments;
}
	
- (NSDictionary *)environment {
	[self doProcargs];
	return environment;
}
	
- (AGProcess *)parent {
	return [[self class] processForProcessIdentifier:[self parentProcessIdentifier]];
}
	
- (NSArray *)children {
	NSArray *all = [[self class] allProcesses];
	NSMutableArray *children = [NSMutableArray array];
	int i, count = [all count];
	for (i = 0; i < count; i++)
		if ([all[i] parentProcessIdentifier] == process)
			[children addObject:all[i]];
	return children;
}
	
- (NSArray *)siblings {
	NSArray *all = [[self class] allProcesses];
	NSMutableArray *siblings = [NSMutableArray array];
	int i, count = [all count], ppid = [self parentProcessIdentifier];
	for (i = 0; i < count; i++)
		if ([all[i] parentProcessIdentifier] == ppid)
			[siblings addObject:all[i]];
	return siblings;
}
	
- (double)percentCPUUsage {
	double percent;
	if (AGGetMachTaskCPUUsage(task, NULL, NULL, &percent) != KERN_SUCCESS)
		return AGProcessValueUnknown;
	return percent;
}
	
- (double)totalCPUTime {
	double user, system;
	if (AGGetMachTaskCPUUsage(task, &user, &system, NULL) != KERN_SUCCESS)
		return AGProcessValueUnknown;
	return user + system;
}

- (double)userCPUTime {
	double user;
	if (AGGetMachTaskCPUUsage(task, &user, NULL, NULL) != KERN_SUCCESS)
		return AGProcessValueUnknown;
	return user;
}
	
- (double)systemCPUTime {
	double system;
	if (AGGetMachTaskCPUUsage(task, NULL, &system, NULL) != KERN_SUCCESS)
		return AGProcessValueUnknown;
	return system;
}    
	
- (double)percentMemoryUsage {
	double percent;
	if (AGGetMachTaskMemoryUsage(task, NULL, NULL, &percent) != KERN_SUCCESS)
		return AGProcessValueUnknown;
	return percent;
}
	
- (unsigned)virtualMemorySize {
	unsigned size;
	if (AGGetMachTaskMemoryUsage(task, &size, NULL, NULL) != KERN_SUCCESS)
		return AGProcessValueUnknown;
	return size;
}
	
- (unsigned)residentMemorySize {
	unsigned size;
	if (AGGetMachTaskMemoryUsage(task, NULL, &size, NULL) != KERN_SUCCESS)
		return AGProcessValueUnknown;
	return size;
}
	
- (int)state {
	int state;
	struct kinfo_proc info;
	size_t length = sizeof(struct kinfo_proc);
	int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process };
	if (sysctl(mib, 4, &info, &length, NULL, 0) < 0)
		return AGProcessStateExited;
	if (length == 0)
		return AGProcessStateExited;
	if (info.kp_proc.p_stat == SZOMB)
		return AGProcessStateZombie;
	if (AGGetMachTaskState(task, &state) != KERN_SUCCESS)
		return AGProcessStateUnknown;
	return state;
}
	
- (int)priority {
	int priority;
	if (AGGetMachTaskPriority(task, &priority, NULL) != KERN_SUCCESS)
		return AGProcessValueUnknown;
	return priority;
}

- (int)basePriority {
	int priority;
	if (AGGetMachTaskPriority(task, NULL, &priority) != KERN_SUCCESS)
		return AGProcessValueUnknown;
	return priority;
}
	
- (int)threadCount {
	int count;
	if (AGGetMachTaskThreadCount(task, &count) != KERN_SUCCESS)
		return AGProcessValueUnknown;
	return count;
} 
	
- (BOOL)suspend {
	return [self kill:SIGSTOP];
}
	
- (BOOL)resume {
	return [self kill:SIGCONT];
}
	
- (BOOL)interrupt {
	return [self kill:SIGINT];
}
	
- (BOOL)terminate {
	return [self kill:SIGTERM];
}
	
- (BOOL)kill:(int)signal {
	return kill(process, signal) == 0;
}
	
- (unsigned)hash {
	return process;
}
	
- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[self class]])
		return NO;
	return process == [(AGProcess *)object processIdentifier];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ process = %d, task = %u, command = %@, arguments = %@, environment = %@", [super description], process, task, [self command], [self arguments], [self environment]];
}
	
- (void)dealloc {
	mach_port_deallocate(mach_task_self(), task);
}
	
- (id)copyWithZone:(NSZone *)zone {
	return self;
}
	
@end
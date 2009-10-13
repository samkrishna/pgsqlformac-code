// AGProcess.h
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

#import <Foundation/NSObject.h>
#include <mach/mach_types.h>

enum {
	AGProcessValueUnknown = 0xffffffff
};

enum {
	AGProcessStateUnknown,
	AGProcessStateRunnable,
	AGProcessStateUninterruptible,
	AGProcessStateSleeping,
	AGProcessStateIdle,
	AGProcessStateSuspended,
	AGProcessStateZombie,
	AGProcessStateExited
};

@class NSString, NSArray, NSDictionary;

@interface AGProcess : NSObject <NSCopying> {
	int process;
	task_t task;
	NSString *command;
	NSArray *arguments;
	NSDictionary *environment;
}

- (id)initWithProcessIdentifier:(int)pid;

+ (AGProcess *)currentProcess;
+ (NSArray *)allProcesses;
+ (NSArray *)userProcesses;

+ (AGProcess *)processForProcessIdentifier:(int)pid;
+ (NSArray *)processesForProcessGroup:(int)pgid;
+ (NSArray *)processesForTerminal:(int)tty;
+ (NSArray *)processesForUser:(int)uid;
+ (NSArray *)processesForRealUser:(int)ruid;

+ (AGProcess *)processForCommand:(NSString *)comm;
+ (NSArray *)processesForCommand:(NSString *)comm;

- (int)processIdentifier;
- (int)parentProcessIdentifier;
- (int)processGroup;
- (int)terminal;
- (int)terminalProcessGroup;
- (int)userIdentifier;
- (int)realUserIdentifier;

- (double)percentCPUUsage;
- (double)totalCPUTime;
- (double)userCPUTime;
- (double)systemCPUTime;
//- (double)wallClockTime;

- (double)percentMemoryUsage;
- (unsigned)virtualMemorySize;
- (unsigned)residentMemorySize;

- (int)state;
- (int)priority;
- (int)basePriority;
- (int)threadCount;

- (NSString *)command;
- (NSArray *)arguments;
- (NSDictionary *)environment;

- (AGProcess *)parent;
- (NSArray *)children;
- (NSArray *)siblings;

- (BOOL)suspend;
- (BOOL)resume;
- (BOOL)interrupt;
- (BOOL)terminate;
- (BOOL)kill:(int)signal;

- (unsigned)hash;
- (BOOL)isEqual:(id)object;

@end
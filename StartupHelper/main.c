#include <stdio.h>

#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <asl.h>

#define LOCAL_BUFFER_SIZE 1024

int main (int argc, const char * argv[]) {
    
    aslclient log_client = asl_open("PostgresqlForMac", "The PostgresqlForMac Log Facility", ASL_OPT_STDERR);
    if (log_client == NULL)
    {
        return -1;
    }
    
    int result = setuid(0);
    if (result < 0)
    {
        asl_log(log_client, NULL, ASL_LEVEL_ERR, "StartupHelper failed setuid(0).");
        asl_close(log_client);
        return -1;
    }
    
    /* form command */
	char* szCommand = (char *)malloc(LOCAL_BUFFER_SIZE);
    if (szCommand == NULL)
    {
        asl_log(log_client, NULL, ASL_LEVEL_ERR, "StartupHelper memory alloc error.");
        asl_close(log_client);
        return -1;
    }

    *szCommand = '\0';
    for (int x = 1; x < argc; x++)
    {
        result = snprintf(szCommand, LOCAL_BUFFER_SIZE, "%s %s", szCommand, argv[x]);
        if (result >= LOCAL_BUFFER_SIZE)
        {
            asl_log(log_client, NULL, ASL_LEVEL_ERR, "StartupHelper attempted buffer overflow.");
            asl_close(log_client);
            free(szCommand);
            return -1;
        }
    }
    
#ifdef DEBUG
    /* log the command */
    asl_log(log_client, NULL, ASL_LEVEL_INFO, "StartupHelper formed the command: %s", szCommand);
#endif
    
    /* Execute Command */
    result = system(szCommand);
    if ((result < 0) || (result == 127))
    {
        asl_log(log_client, NULL, ASL_LEVEL_ERR, "StartupHelper command failed: %s", szCommand);
        asl_close(log_client);
    }
    free(szCommand);
    return result;
}

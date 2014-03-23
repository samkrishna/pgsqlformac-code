#include <stdio.h>

#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <asl.h>

int main (int argc, const char * argv[]) {
    
    int result = setuid(0);
    if (result < 0)
    {
        aslclient log_client = asl_open("PostgresqlForMac", "The PostgresqlForMac Log Facility", ASL_OPT_STDERR);
        if (log_client != NULL)
        {
            asl_log(log_client, NULL, ASL_LEVEL_WARNING, "StartupHelper setuid(0) retsults < 0.");
            asl_close(log_client);
        }
    }

    /* form command */
	char* szCommand = (char *)malloc(512);
	int x = 0;
	for (x = 1; x < argc; x++)
	{
		sprintf(szCommand, "%s %s", szCommand, argv[x]);
	}
    
    /* Execute Command */
	result = system(szCommand);
    if ((result < 0) || (result == 127))
    {
        aslclient log_client = asl_open("PostgresqlForMac", "The PostgresqlForMac Log Facility", ASL_OPT_STDERR);
        if (log_client != NULL)
        {
            asl_log(log_client, NULL, ASL_LEVEL_ERR, "StartupHelper command failed: %s", szCommand);
            asl_close(log_client);
        }
    }
	free(szCommand);
    return result;
}

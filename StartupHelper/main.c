#include <stdio.h>

#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

int main (int argc, const char * argv[]) {
    // insert code here...
    // printf("Calling the StartupItem %s with parameter %s.\n", argv[1], argv[2]);
	setuid(0);
	
	char* szCommand = (char *)malloc(strlen(argv[1]) + strlen(argv[2] + 2));
	
	int x = 0;
	for (x = 1; x < argc; x++)
	{
		sprintf(szCommand, "%s %s", szCommand, argv[x]);
	}
	
	// printf("%s\n", szCommand);
	system(szCommand);
	
	free(szCommand);
	
    return 0;
}

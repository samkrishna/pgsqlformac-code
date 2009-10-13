#include <stdio.h>

#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

int main (int argc, const char * argv[]) {
    // insert code here...
    setuid(0);
	char* szCommand = (char *)malloc(512);
	int x = 0;
	for (x = 1; x < argc; x++)
	{
		sprintf(szCommand, "%s %s", szCommand, argv[x]);
	}
	system(szCommand);
	free(szCommand);
    return 0;
}

#include <string.h>
#include "postgres.h"
#include "fmgr.h"
#include "newid.h"

/* by value */

PG_FUNCTION_INFO_V1(newid);
         
Datum
newid(PG_FUNCTION_ARGS)
{
	char *sBuff = malloc(42);
	sprintf(sBuff, "%s", getNewGUID());
    text *pRes = (text *)palloc(40 + VARHDRSZ);
	VARATT_SIZEP(pRes) = 40;
	memcpy(VARDATA(pRes), (void *)sBuff, 40 - VARHDRSZ);

    PG_RETURN_TEXT_P(pRes);
}

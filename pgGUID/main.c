/*
 *  newid.c
 *  guid
 *
 *  Created by Andy Satori on 9/29/04.
 *  Copyright 2004-2005 Druware Software Designs. All rights reserved.
 *  
 *  For further licensing information, See the COPYRIGHT file that was 
 *  shipped with this code.
 *
 */
 
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

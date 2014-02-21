//
//  PGSQLAdminUser.m
//  Create User
//
//  Created by Andy Satori on 2/18/14.
//
//

#import "PGSQLAdminUser.h"

@implementation PGSQLAdminUser

@end

/*
 
 http://www.postgresql.org/docs/9.3/static/sql-createuser.html
 
 CREATE USER name [ [ WITH ] option [ ... ] ]
 
 where option can be:
 
 SUPERUSER | NOSUPERUSER
 | CREATEDB | NOCREATEDB
 | CREATEROLE | NOCREATEROLE
 | CREATEUSER | NOCREATEUSER
 | INHERIT | NOINHERIT
 | LOGIN | NOLOGIN
 | REPLICATION | NOREPLICATION
 | CONNECTION LIMIT connlimit
 | [ ENCRYPTED | UNENCRYPTED ] PASSWORD 'password'
 | VALID UNTIL 'timestamp'
 | IN ROLE role_name [, ...]
 | IN GROUP role_name [, ...]
 | ROLE role_name [, ...]
 | ADMIN role_name [, ...]
 | USER role_name [, ...]
 | SYSID uid
 
 */

/*          file: PGSQLAdminUser.h
 *   description: This is the object representation of a user in the PGSQLAdmin
 *                toolchain for the PostgreSQL for Mac project
 *         notes: The terms user and role are interchangeable within PGSQL, 
 *                however, for simplicity and common frame of refrence with the 
 *                most common 'general' reference of MSSQL, we will create 
 *                objects that for both group and user built upon the role
 *                concept
 *
 * License *********************************************************************
 *
 * Copyright (c) 2005-2014, Andy 'Dru' Satori @ Druware Software Designs
 * All rights reserved.
 *
 * Redistribution and use in source or binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions in source or binary form must reproduce the above
 *    copyright notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the distribution.
 * 2. Neither the name of the Druware Software Designs nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 *******************************************************************************
 *
 * history:
 *   WHO MM/DD/YY Description
 *   --- -------- --------------------------------------------------------------
 *   dru 02/22/14 started rough in of the object and the SQL to build it
 *
 * todo:
 *   ---------------------------------------------------------------------------
 *   + create user methodology 
 *   + edit/update user methodology
 *   + delete user methodology
 *   + permissions checking to display associated role permissions
 *
 ******************************************************************************/

#import <PGSQLKit/PGSQLKit.h>
#import <PGSQLKit/PGSQLDataObject.h>
#import <PGSQLKit/PGSQLRecordset.h>

@interface PGSQLAdminUser : PGSQLDataObject
{
    
}

#pragma mark customer initializers

- (id)initWithConnection:(PGSQLConnection *)pgConn;
- (id)initWithConnection:(PGSQLConnection *)pgConn
                   forId:(NSNumber *)referenceId;
- (id)initWithConnection:(PGSQLConnection *)pgConn
               forRecord:(PGSQLRecordset *)rs;
- (id)initWithConnection:(PGSQLConnection *)pgConn
                  forUid:(NSString *)referenceId;

#pragma mark persistance methods (rdbms, xml)

- (BOOL)save;
- (NSXMLElement *)xmlForObject;
- (BOOL)loadFromXml:(NSXMLElement *)xmlElement;

#pragma mark custom properties

@property (copy)            NSString    *login;
@property (copy)            NSString    *password;
@property (assign)          BOOL         shouldEncryptPassword;
@property (assign)          BOOL         isSuperUser;
@property (assign)          BOOL         canCreateDB;
@property (assign)          BOOL         canCreateRole;
@property (assign)          BOOL         canCreateUser;
@property (assign)          BOOL         shoudInherit;
@property (assign)          BOOL         shouldReplicate;
@property (copy)            NSNumber    *connectionLimit;
@property (copy)            NSDate      *expires;
@property (copy)            NSString    *databaseName;

#pragma mark custom accessors / property overrides

- (NSNumber *)sessionId;
- (NSString *)sessionUid;
- (NSNumber *)userId;
- (NSDate *)createdTS;
- (NSDate *)expiredTS;
- (BOOL)isExpired;


#pragma mark custom methods and implmentation

@end



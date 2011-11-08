//
//  TXLDatabase.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 17.09.10.
//  Copyright 2010 Fraunhofer ISST. All rights reserved.
//
//  This file is part of OpenTXL.
//	
//  OpenTXL is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//	
//  OpenTXL is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with OpenTXL. If not, see <http://www.gnu.org/licenses/>.
//

#import "TXLDatabase.h"
#import "TXLDBHandle.h"
#import "TXLInteger.h"

#import <spatialite/sqlite3.h>
#import <spatialite/gaiageo.h>
#import <spatialite.h>

#include <pthread.h>

NSString * const TXLDatabaseErrorDomain = @"org.opentxl.TXLDatabaseErrorDomain";
NSString * const SQLiteErrorDomain = @"org.opentxl.SQLiteErrorDomain";


#pragma mark -
#pragma mark Helper Function for Blocking Access to the SQLite DB

int sqlite3_blocking_prepare_v2(sqlite3 *db, const char *zSql, int nSql, sqlite3_stmt **ppStmt, const char **pz);
int sqlite3_blocking_step(sqlite3_stmt *pStmt);


@interface TXLDatabase ()

#pragma mark -
#pragma mark Database Management

@property (retain) NSString* databasePath;
@property (readonly) TXLDBHandle *dbHandle;

#pragma mark -
#pragma mark Error Handling

- (NSError *)errorFromSQLiteError:(int)err_no
                    withStatement:(NSString *)sql
                       parameters:(NSArray *)parameters;

#pragma mark -
#pragma mark Executing SQL

- (NSArray *)columnTypesForStatement:(sqlite3_stmt *)statement;

- (NSArray *)columnNamesForStatement:(sqlite3_stmt *)statement;

- (int)typeForStatement:(sqlite3_stmt *)statement
                 column:(int)column;

- (int)columnTypeToInt:(NSString *)columnType;

- (void)copyValuesFromStatement:(sqlite3_stmt *)statement
                          toRow:(NSMutableDictionary *)row
                    columnTypes:(NSArray *)columnTypes
                    columnNames:(NSArray *)columnNames;

- (id)valueFromStatement:(sqlite3_stmt *)statement
                  column:(int)column
             columnTypes:(NSArray *)columnTypes;

- (BOOL)bindArguments:(NSArray *)arguments
          toStatement:(sqlite3_stmt *)statement
                error:(NSError **)error;
@end


@implementation TXLDatabase

@synthesize databasePath;

+ (void)initialize {
#ifdef DEBUG
    spatialite_init(0);
#else
    spatialite_init(1);
#endif
}

- (id)initWithPath:(NSString *)path {
    if ((self = [self init])) {
        self.databasePath = path;
    }
    return self;
}

- (void)dealloc {
    self.databasePath = nil;
    [super dealloc]; 
}

#pragma mark -
#pragma mark Private Methods

#pragma mark -
#pragma mark Database Management

- (TXLDBHandle *)dbHandle {
    NSThread *thread = [NSThread currentThread];
    TXLDBHandle *dbHandle = [[thread threadDictionary] objectForKey:@"org.opentxl.TXLDBHandle"];
    if (dbHandle == nil) {
        dbHandle = [[[TXLDBHandle alloc] initWithPath:self.databasePath] autorelease];
        [[thread threadDictionary] setObject:dbHandle forKey:@"org.opentxl.TXLDBHandle"];
    }
    return dbHandle;
}

#pragma mark -
#pragma mark Error Handling

- (NSError *)errorFromSQLiteError:(int)err_no
                    withStatement:(NSString *)sql
                       parameters:(NSArray *)parameters {
    NSString *msg = [NSString stringWithUTF8String:sqlite3_errmsg(self.dbHandle.handle)];
    //NSLog(@"SQLite error: %@\nfor statement: %@\nwith parameters: %@", msg, sql, parameters);
    return [NSError errorWithDomain:SQLiteErrorDomain
                               code:err_no
                           userInfo:[NSDictionary dictionaryWithObject:msg forKey:NSLocalizedDescriptionKey]];
}

#pragma mark -
#pragma mark Transactions

- (BOOL)beginTransaction:(NSError **)error {
    return nil != [self executeSQL:@"begin immediate transaction" error:error];
}

- (BOOL)commit:(NSError **)error {
    return nil != [self executeSQL:@"commit transaction" error:error]; 
}

- (BOOL)rollback:(NSError **)error {
    return nil != [self executeSQL:@"rollback transaction" error:error];
}

#pragma mark -
#pragma mark Tables

- (NSArray *)tables {
    NSError *error;
    return [self executeSQL:@"select * from sqlite_master where type = 'table'" error:&error];
}

- (NSArray *)tableNames {
    return [[self tables] valueForKey:@"name"];
}

#pragma mark -
#pragma mark Misc

- (NSUInteger)lastInsertRowid {
    return sqlite3_last_insert_rowid(self.dbHandle.handle);
}

#pragma mark -
#pragma mark Executing SQL

- (NSArray *)executeSQL:(NSString *)sql
                  error:(NSError **)error {
    return [self executeSQL:sql
             withParameters:nil
                      error:error];
}

- (NSArray *)executeSQLWithParameters:(NSString *)sql
                                error:(NSError **)error, ... {
    va_list argumentList;
    va_start(argumentList, error);
    NSMutableArray *arguments = [NSMutableArray array];
    id argument;
    while ((argument = va_arg(argumentList, id))) {
        [arguments addObject:argument];
    }
    va_end(argumentList);
    return [self executeSQL:sql
             withParameters:arguments
                      error:error];
}

- (NSArray *)executeSQL:(NSString *)sql
         withParameters:(NSArray *)parameters
                  error:(NSError **)error {
    NSMutableArray *rows = [NSMutableArray array];

    BOOL success = [self executeSQL:sql
                     withParameters:parameters
                              error:error
                      resultHandler:^(NSDictionary *row, BOOL *stop){
                          [rows addObject:row];
                      }];
    
    if (success) {
        return rows;
    } else {
        return nil;
    }
}

- (BOOL)executeSQL:(NSString *)sql
    withParameters:(NSArray *)parameters
             error:(NSError **)error
     resultHandler:(void(^)(NSDictionary *row, BOOL *stop))block {
    
    sqlite3_stmt *statement = NULL;
    
	// try retrieving a prepared statement, may be nil, if not previously enqueued
	statement = [self.dbHandle dequeueReusableStatementForSQL:sql];
	
	if (statement == nil) {
		// no statement was retrieved
        int err_no = sqlite3_blocking_prepare_v2(self.dbHandle.handle,
                                                 [sql UTF8String],
                                                 -1,
                                                 &statement,
                                                 NULL);
        
		if (err_no != SQLITE_OK) {
			// An error occured while preparing the statement
			sqlite3_finalize(statement);
            if (error != nil) {
                *error = [self errorFromSQLiteError:err_no
                                      withStatement:sql
                                         parameters:parameters];
            }
            return NO;
		}
	}
	
    // Binding arguments to prepared statement
	if (![self bindArguments:parameters
                 toStatement:statement
                       error:error]) {
        // Could not bind argument to the statement.
        // Enqueue sattement for later use.
        [self.dbHandle enqueueReusableStatement:statement
                                          forSQL:sql];
        return NO;
    };
	
    
	BOOL needsToFetchColumnTypesAndNames = YES;
	NSArray *columnTypes = nil;
	NSArray *columnNames = nil;
	
    BOOL stop = NO;
    int err_no = 0;
    
    // Iterate over the results of the statement. The result handler
    // will be called for each row in the result set.
	while (!stop && (err_no = sqlite3_blocking_step(statement)) == SQLITE_ROW) {
        
        NSAutoreleasePool *pool = [NSAutoreleasePool new];

        // Fetch the column names and types if not already cached.
		if (needsToFetchColumnTypesAndNames) {
			columnTypes = [[self columnTypesForStatement:statement] retain];
			columnNames = [[self columnNamesForStatement:statement] retain];
			needsToFetchColumnTypesAndNames = NO;
		}
		
        // Get the values and call the result handler
		NSMutableDictionary *row = [NSMutableDictionary new];
		[self copyValuesFromStatement:statement
								toRow:row
						  columnTypes:columnTypes
						  columnNames:columnNames];
		block(row, &stop);
		[row release];

        [pool drain];
	}
    [columnTypes release];
    [columnNames release];

    // Enqueue statement where it is placed in the pool of prepared statements
    // and also reset to be enabled for reuse.
    [self.dbHandle enqueueReusableStatement:statement
                                      forSQL:sql];
    
    // Check if an error occured
    if (!(err_no == SQLITE_DONE || err_no == SQLITE_ROW)) {
        if (error != nil) {
            *error = [self errorFromSQLiteError:err_no
                                  withStatement:sql
                                     parameters:parameters];
        }
        return NO;
    } else {
        return YES;
    }
}


- (NSArray *)columnTypesForStatement:(sqlite3_stmt *)statement {
    int columnCount = sqlite3_column_count(statement);
    NSMutableArray *columnTypes = [NSMutableArray arrayWithCapacity:columnCount];
    for (int i = 0; i < columnCount; i++) {
        [columnTypes addObject:[NSNumber numberWithInt:[self typeForStatement:statement column:i]]];
    }
    return columnTypes;
}

- (NSArray *)columnNamesForStatement:(sqlite3_stmt *)statement {
    int columnCount = sqlite3_column_count(statement);
    NSMutableArray *columnNames = [NSMutableArray arrayWithCapacity:columnCount];
    for (int i = 0; i < columnCount; i++) {
        [columnNames addObject:[NSString stringWithUTF8String:sqlite3_column_name(statement, i)]];
    }
    return columnNames;
}

- (int)typeForStatement:(sqlite3_stmt *)statement
                 column:(int)column {
    const char *columnType = sqlite3_column_decltype(statement, column);
    if (columnType != NULL) {
        return [self columnTypeToInt:[[NSString stringWithUTF8String:columnType] uppercaseString]];
    }
    return 0;
}

- (int)columnTypeToInt:(NSString *)columnType {
    if ([columnType isEqual:@"INTEGER"]) {
        return SQLITE_INTEGER;
    } else if ([columnType isEqual:@"REAL"]) {
        return SQLITE_FLOAT;
    } else if ([columnType isEqual:@"TEXT"]) {
        return SQLITE_TEXT;
    } else if ([columnType isEqual:@"BLOB"]) {
        return SQLITE_BLOB;
    } else if ([columnType isEqual:@"NULL"]) {
        return SQLITE_NULL;
    }
    return SQLITE_TEXT;
}

- (void)copyValuesFromStatement:(sqlite3_stmt *)statement
                          toRow:(NSMutableDictionary *)row
                    columnTypes:(NSArray *)columnTypes
                    columnNames:(NSArray *)columnNames {
    int columnCount = sqlite3_column_count(statement);
    
    for (int i = 0; i < columnCount; i++) {
        id value = [self valueFromStatement:statement column:i columnTypes:columnTypes];
        if (value) {
            [row setValue:value forKey:[columnNames objectAtIndex:i]];
        }
    }
}

- (id)valueFromStatement:(sqlite3_stmt *)statement
                  column:(int)column
             columnTypes:(NSArray *)columnTypes {
    int columnType = [[columnTypes objectAtIndex:column] intValue];
    
    // The type for this column is not defined in the table
    // declaration. Therefor we use the type of the value.
    if (columnType == 0) {
        columnType = sqlite3_column_type(statement, column);
    }
    
    if (columnType == SQLITE_INTEGER) {
        return [TXLInteger integerWithValue:sqlite3_column_int(statement, column)];
    } else if (columnType == SQLITE_FLOAT) {
        return [NSNumber numberWithDouble:sqlite3_column_double(statement, column)];
    } else if (columnType == SQLITE_TEXT) {
        const char *text = (const char *)sqlite3_column_text(statement, column);
        if (text) {
            return [NSString stringWithUTF8String:text];
        } else {
            return nil;
        }
    } else if (columnType == SQLITE_BLOB) {
        return [NSData dataWithBytes:sqlite3_column_blob(statement, column)
                              length:sqlite3_column_bytes(statement, column)];
    } else if (columnType == SQLITE_NULL) {
        return [NSNull null];
    }
    
    NSLog(@"Unrecoginzed SQL column type: %i", columnType);
    
    return nil;
}

- (BOOL)bindArguments:(NSArray *)arguments
          toStatement:(sqlite3_stmt *)statement
                error:(NSError **)error {
    
    int expectedArguments = sqlite3_bind_parameter_count(statement);
    
    // Check if the number of bound parameters does match.
    // If not, create an error and return NO.
    if (expectedArguments != [arguments count]) {
        
        NSDictionary *error_dict = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Number of parameters in the statement does not match the number of given arguments.", nil)
                                                               forKey:NSLocalizedDescriptionKey];
        
        if (error != nil) {
            *error = [NSError errorWithDomain:TXLDatabaseErrorDomain
                                         code:TXL_DATABASE_ERROR_PARAMETER_MISSMATCH
                                     userInfo:error_dict];            
        }
        
        return NO;
    }    
    
    // Bind argument to the statement
    for (int i = 1; i <= expectedArguments; i++) {
        
        id argument = [arguments objectAtIndex:i -1];
        
        if ([argument isKindOfClass:[NSString class]]) {
            // NSString
            sqlite3_bind_text(statement, i, [argument UTF8String], -1, SQLITE_TRANSIENT);
            
        } else if ([argument isKindOfClass:[NSData class]]) {
            // NSData
            sqlite3_bind_blob(statement, i, [argument bytes], [argument length], SQLITE_TRANSIENT);
            
        } else if ([argument isKindOfClass:[NSNumber class]]) {
            // NSNumber
            sqlite3_bind_double(statement, i, [argument doubleValue]);
            
        } else if ([argument isKindOfClass:[TXLInteger class]]) {
            // TXLInteger
            sqlite3_bind_int64(statement, i, [argument integerValue]);
            
        } else if ([argument isKindOfClass:[NSNull class]]) {
            // NSNull
            sqlite3_bind_null(statement, i);
            
        } else {
            // Error: Unrecognized object type
            NSDictionary *error_dict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"TXLDatabase doesn't know how to handle object: %@", nil), argument] 
                                                                   forKey:NSLocalizedDescriptionKey];
            if (error != nil) {
                *error = [NSError errorWithDomain:TXLDatabaseErrorDomain
                                             code:TXL_DATABASE_ERROR_UNRECOGNIZED_OBJECT_TYPE
                                         userInfo:error_dict];                
            }
            return NO;
        }
    }
    
    return YES;
}

@end


#pragma mark -
#pragma mark Helper Function for Blocking Access to the SQLite DB

#if 1

int sqlite3_blocking_prepare_v2(sqlite3 *db, const char *zSql, int nSql, sqlite3_stmt **ppStmt, const char **pz) {
    return sqlite3_prepare_v2(db, zSql, nSql, ppStmt, pz);
}

int sqlite3_blocking_step(sqlite3_stmt *pStmt) {
    return sqlite3_step(pStmt);
}

#else

// http://www.sqlite.org/unlock_notify.html


/*
 ** A pointer to an instance of this structure is passed as the user-context
 ** pointer when registering for an unlock-notify callback.
 */
typedef struct UnlockNotification UnlockNotification;
struct UnlockNotification {
    int fired;                           /* True after unlock event has occured */
    pthread_cond_t cond;                 /* Condition variable to wait on */
    pthread_mutex_t mutex;               /* Mutex to protect structure */
};

/*
 ** This function is an unlock-notify callback registered with SQLite.
 */
static void unlock_notify_cb(void **apArg, int nArg){
    int i;
    for(i=0; i<nArg; i++){
        UnlockNotification *p = (UnlockNotification *)apArg[i];
        pthread_mutex_lock(&p->mutex);
        p->fired = 1;
        pthread_cond_signal(&p->cond);
        pthread_mutex_unlock(&p->mutex);
    }
}

/*
 ** This function assumes that an SQLite API call (either sqlite3_prepare_v2() 
 ** or sqlite3_step()) has just returned SQLITE_LOCKED. The argument is the
 ** associated database connection.
 **
 ** This function calls sqlite3_unlock_notify() to register for an 
 ** unlock-notify callback, then blocks until that callback is delivered 
 ** and returns SQLITE_OK. The caller should then retry the failed operation.
 **
 ** Or, if sqlite3_unlock_notify() indicates that to block would deadlock 
 ** the system, then this function returns SQLITE_LOCKED immediately. In 
 ** this case the caller should not retry the operation and should roll 
 ** back the current transaction (if any).
 */
static int wait_for_unlock_notify(sqlite3 *db){
    int rc;
    UnlockNotification un;
    
    /* Initialize the UnlockNotification structure. */
    un.fired = 0;
    pthread_mutex_init(&un.mutex, 0);
    pthread_cond_init(&un.cond, 0);
    
    /* Register for an unlock-notify callback. */
    rc = sqlite3_unlock_notify(db, unlock_notify_cb, (void *)&un);
    assert( rc==SQLITE_LOCKED || rc==SQLITE_OK );
    
    /* The call to sqlite3_unlock_notify() always returns either SQLITE_LOCKED 
     ** or SQLITE_OK. 
     **
     ** If SQLITE_LOCKED was returned, then the system is deadlocked. In this
     ** case this function needs to return SQLITE_LOCKED to the caller so 
     ** that the current transaction can be rolled back. Otherwise, block
     ** until the unlock-notify callback is invoked, then return SQLITE_OK.
     */
    if( rc==SQLITE_OK ){
        pthread_mutex_lock(&un.mutex);
        if( !un.fired ){
            pthread_cond_wait(&un.cond, &un.mutex);
        }
        pthread_mutex_unlock(&un.mutex);
    }
    
    /* Destroy the mutex and condition variables. */
    pthread_cond_destroy(&un.cond);
    pthread_mutex_destroy(&un.mutex);
    
    return rc;
}

/*
 ** This function is a wrapper around the SQLite function sqlite3_step().
 ** It functions in the same way as step(), except that if a required
 ** shared-cache lock cannot be obtained, this function may block waiting for
 ** the lock to become available. In this scenario the normal API step()
 ** function always returns SQLITE_LOCKED.
 **
 ** If this function returns SQLITE_LOCKED, the caller should rollback
 ** the current transaction (if any) and try again later. Otherwise, the
 ** system may become deadlocked.
 */
int sqlite3_blocking_step(sqlite3_stmt *pStmt){
    int rc;
    while( SQLITE_LOCKED==(rc = sqlite3_step(pStmt)) ){
        rc = wait_for_unlock_notify(sqlite3_db_handle(pStmt));
        if( rc!=SQLITE_OK ) break;
        sqlite3_reset(pStmt);
    }
    return rc;
}

/*
 ** This function is a wrapper around the SQLite function sqlite3_prepare_v2().
 ** It functions in the same way as prepare_v2(), except that if a required
 ** shared-cache lock cannot be obtained, this function may block waiting for
 ** the lock to become available. In this scenario the normal API prepare_v2()
 ** function always returns SQLITE_LOCKED.
 **
 ** If this function returns SQLITE_LOCKED, the caller should rollback
 ** the current transaction (if any) and try again later. Otherwise, the
 ** system may become deadlocked.
 */
int sqlite3_blocking_prepare_v2(
                                sqlite3 *db,              /* Database handle. */
                                const char *zSql,         /* UTF-8 encoded SQL statement. */
                                int nSql,                 /* Length of zSql in bytes. */
                                sqlite3_stmt **ppStmt,    /* OUT: A pointer to the prepared statement */
                                const char **pz           /* OUT: End of parsed string */
                                ){
    int rc;
    while( SQLITE_LOCKED==(rc = sqlite3_prepare_v2(db, zSql, nSql, ppStmt, pz)) ){
        rc = wait_for_unlock_notify(db);
        if( rc!=SQLITE_OK ) break;
    }
    return rc;
}

#endif


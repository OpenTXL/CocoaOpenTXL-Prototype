//
//  TXLResultSet.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 11.10.10.
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

#import "TXLResultSet.h"
#import "TXLMovingObjectSequence.h" 
#import "TXLMovingObject.h"
#import "TXLQuery.h" 
#import "TXLRevision.h" 
#import "TXLDatabase.h"
#import "TXLInteger.h"
#import "TXLManager.h"
#import "TXLQueryHandle.h"
#import "TXLTerm.h"

@interface TXLResultSet () 
- (id)initWithQueryHandle:(TXLQueryHandle *)qh
             withRevision:(TXLRevision *)rev;
- (NSString *)nameForVarWithPrimaryKey:(NSUInteger)pk;
@end 

@implementation TXLResultSet

@synthesize queryHandle;
@synthesize revision;

#pragma mark -
#pragma mark Memory Managment

- (void)dealloc {
    [revision release]; 
    [super dealloc];
}

#pragma mark -
#pragma mark Count

- (NSUInteger)count {
    // Count the number of rows in the table for this
    // result set which are valid in this revision.
    
    TXLDatabase *database = [[TXLManager sharedManager] database]; 
    
    NSError *error;
    
    NSUInteger query_pk = self.queryHandle.queryPrimaryKey;
    NSString *tableName = [NSString stringWithFormat:@"txl_resultset_%d", query_pk]; 
    NSString *tableName_created = [NSString stringWithFormat:@"txl_resultset_%d_created", query_pk]; 
    NSString *tableName_removed = [NSString stringWithFormat:@"txl_resultset_%d_removed", query_pk]; 
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) as c FROM %@ as r \
                     INNER JOIN %@ as rc ON (r.id = rc.resultset_id AND rc.revision_id <= ?) \
                     LEFT JOIN %@ as rm ON (r.id = rm.resultset_id) \
                     WHERE (rm.revision_id IS NULL) OR (rm.revision_id > ?)",
                     tableName,
                     tableName_created,
                     tableName_removed]; 
    
    TXLInteger *revision_id = [TXLInteger integerWithValue:revision.primaryKey];
    NSArray *result = [database executeSQLWithParameters:sql error:&error, 
                       revision_id,
                       revision_id,  
                       nil];
    
    if (result == nil) {
        [NSException exceptionWithName:@"TXLResultSetException"
                                reason:[error localizedDescription]
                              userInfo:nil];
    }
    
    if ([result count] == 1) { 
        return [[[result objectAtIndex:0] objectForKey:@"c" ] intValue]; 
    } 
    
    return 0;
}

#pragma mark -
#pragma mark Result

- (NSDictionary *)valuesAtIndex:(NSUInteger)idx {
    // Return the row at index idx of the table for
    // this result set (valid rows at this revision).
    
    TXLDatabase *database = [[TXLManager sharedManager] database]; 
    
    NSError *error;
    
    __block NSDictionary *result = nil; 
    
    NSUInteger query_pk = self.queryHandle.queryPrimaryKey;
    NSString *tableName = [NSString stringWithFormat:@"txl_resultset_%d", query_pk]; 
    NSString *tableName_created = [NSString stringWithFormat:@"txl_resultset_%d_created", query_pk]; 
    NSString *tableName_removed = [NSString stringWithFormat:@"txl_resultset_%d_removed", query_pk]; 
    
    NSString *sql = [NSString stringWithFormat:@"SELECT r.* FROM %@ as r \
                     INNER JOIN %@ as rc ON (r.id = rc.resultset_id AND rc.revision_id <= ?) \
                     LEFT JOIN %@ as rm ON (r.id = rm.resultset_id) \
                     WHERE (rm.revision_id IS NULL) OR (rm.revision_id > ?) \
                     LIMIT %d,1",
                     tableName,
                     tableName_created,
                     tableName_removed,
                     idx]; 
    
    TXLInteger *revision_id = [TXLInteger integerWithValue:revision.primaryKey];
    
    BOOL success = [database executeSQL:sql 
                         withParameters:[NSArray arrayWithObjects:revision_id, revision_id, nil]
                                  error:&error
                          resultHandler:^(NSDictionary *row, BOOL *stop) {
                              NSMutableDictionary *r = [NSMutableDictionary dictionary];
                              for (NSString *key in [row allKeys]) {
                                  if ([key hasPrefix:@"var_"]) {
                                      
                                      NSUInteger pk = [[key substringFromIndex:4] integerValue];
                                      
                                      [r setObject:[TXLTerm termWithPrimaryKey:[[row objectForKey:key] integerValue]]
                                            forKey:[self nameForVarWithPrimaryKey:pk]];
                                  }
                              }
                              result = [r retain];
                              *stop = TRUE;
                          }];
    [result autorelease];
    if (!success) {
        [NSException exceptionWithName:@"TXLResultSetException"
                                reason:[error localizedDescription]
                              userInfo:nil];
    }
    
    return result; 
}

- (TXLMovingObjectSequence *)movingObjectSequenceAtIndex:(NSUInteger)idx {
    // Return the moving object sequence at index idx of
    // the table for this result set (valid rows at this revision).
    
    TXLDatabase *database = [[TXLManager sharedManager] database]; 
    
    NSError *error;
    
    NSUInteger query_pk = self.queryHandle.queryPrimaryKey;
    NSString *tableName = [NSString stringWithFormat:@"txl_resultset_%d", query_pk]; 
    NSString *tableName_created = [NSString stringWithFormat:@"txl_resultset_%d_created", query_pk]; 
    NSString *tableName_removed = [NSString stringWithFormat:@"txl_resultset_%d_removed", query_pk]; 
    
    NSString *sql = [NSString stringWithFormat:@"SELECT r.mos_id FROM %@ as r \
                     INNER JOIN %@ as rc ON (r.id = rc.resultset_id AND rc.revision_id <= ?) \
                     LEFT JOIN %@ as rm ON (r.id = rm.resultset_id) \
                     WHERE (rm.revision_id IS NULL) OR (rm.revision_id > ?) \
                     LIMIT %d,1",
                     tableName,
                     tableName_created,
                     tableName_removed,
                     idx];
    
    TXLInteger *revision_id = [TXLInteger integerWithValue:revision.primaryKey];
    
    __block NSUInteger mos_pk = 0;
    
    BOOL success = [database executeSQL:sql 
          withParameters:[NSArray arrayWithObjects:revision_id, revision_id, nil]
                   error:&error
           resultHandler:^(NSDictionary *row, BOOL *stop) {
               mos_pk = [[row objectForKey:@"mos_id"] integerValue];
               *stop = TRUE;
           }];
    
    if (!success) {
        [NSException exceptionWithName:@"TXLResultSetException"
                                reason:[error localizedDescription]
                              userInfo:nil];
    }
    
    if (mos_pk == 0) {
        return [TXLMovingObjectSequence sequenceWithMovingObject:[TXLMovingObject omnipresentMovingObject]];
    } else { 
        return [TXLMovingObjectSequence sequenceWithPrimaryKey:mos_pk];
    }
}


#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Autorelease Constructor

+ (TXLResultSet *)resultSetForQueryHandle:(TXLQueryHandle *)qh
                             withRevision:(TXLRevision *)rev {
    return [[[self alloc] initWithQueryHandle:qh
                                 withRevision:rev] autorelease];
}

#pragma mark -
#pragma mark -
#pragma mark Private Methods

- (id)initWithQueryHandle:(TXLQueryHandle *)qh
             withRevision:(TXLRevision *)rev {
    if ((self = [super init])) { 
        queryHandle = qh;
        revision = [rev retain]; 
    } 
    return self;
}

- (NSString *)nameForVarWithPrimaryKey:(NSUInteger)pk {
    TXLDatabase *db = [[TXLManager sharedManager] database];
    NSArray *result = [db executeSQL:@"SELECT name FROM txl_query_variable WHERE id = ?"
                      withParameters:[NSArray arrayWithObject:[TXLInteger integerWithValue:pk]]
                               error:nil];
    if ([result count] == 1) {
        return [[result objectAtIndex:0] objectForKey:@"name"];
    } else {
        return nil;
    }
}
@end

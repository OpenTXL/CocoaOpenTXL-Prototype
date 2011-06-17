//
//  TXLManagerTest.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 22.09.10.
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

#import <GHUnit/GHUnit.h>

#import "TXLDatabase.h"
#import "TXLManager.h"
#import "TXLRevision.h"
#import "TXLQueryHandle.h"

#define SQL(x) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

#define SQL_LOG(x, ...) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQLWithParameters:x error:&error, __VA_ARGS__]; GHAssertNotNil(result, [error localizedDescription]); GHTestLog(@"%@", result);}

@interface TXLManagerTest : GHAsyncTestCase {

}
@end

@implementation TXLManagerTest

- (void)setUp {
    for (NSString *name in [[[TXLManager sharedManager] database] tableNames]) {
        
        // delete content for tables
        if ([name hasPrefix:@"txl_context"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_statement"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_query"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_geometry"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_movingobject"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_movingobjectsequence"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_snapshot"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_term"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        // delete tables
        if ([name hasPrefix:@"txl_resultset"]) {
            NSString *expr = [NSString stringWithFormat:@"DROP TABLE %@", name];
            SQL(expr);
        }
    }
    [TXLManager sharedManager].delegate = self;
}

- (void)tearDown {
    
    if ([TXLManager sharedManager].processing) {
        [self prepare];
        [self waitForStatus:kGHUnitWaitStatusSuccess
                    timeout:120.0];
    }
    
    [TXLManager sharedManager].delegate = nil;
}



- (void)testTables {
    TXLDatabase *database = [[TXLManager sharedManager] database];
    
    GHAssertTrue([database.tableNames containsObject:@"txl_revision"], @"Database should contain table 'txl_revision'.");
    GHAssertTrue([database.tableNames containsObject:@"txl_context"], @"Database should contain table 'txl_context'.");
    GHAssertTrue([database.tableNames containsObject:@"txl_term"], @"Database should contain table 'txl_term'.");
    GHAssertTrue([database.tableNames containsObject:@"txl_statement"], @"Database should contain table 'txl_statement'.");
    GHAssertTrue([database.tableNames containsObject:@"txl_statement_created"], @"Database should contain table 'txl_statement_created'.");
    GHAssertTrue([database.tableNames containsObject:@"txl_statement_removed"], @"Database should contain table 'txl_statement_removed'.");
    GHAssertTrue([database.tableNames containsObject:@"txl_movingobject"], @"Database should contain table 'txl_movingobject'.");
    GHAssertTrue([database.tableNames containsObject:@"txl_movingobjectsequence"], @"Database should contain table 'txl_movingobjectsequence'.");
    GHAssertTrue([database.tableNames containsObject:@"txl_query"], @"Database should contain table 'txl_query'.");
}

- (void)testRegisterQuery {
    
    NSError *error;
    
    TXLQueryHandle *qh = [[TXLManager sharedManager] registerQueryWithName:@"testRegisterQuery"
                                                                expression:@"SELECT ?foo FROM <txl://localhost/> WHERE {?foo a <http://example.com/foo>}"
                                                                parameters:nil
                                                                   options:nil
                                                                     error:&error];
    GHAssertNotNil(qh, [error localizedDescription]);
    
    TXLQueryHandle *qh2 = [[TXLManager sharedManager] queryWithName:@"testRegisterQuery"
                                                              error:&error];
    GHAssertNotNil(qh2, [error localizedDescription]);
    GHAssertEquals(qh.queryPrimaryKey, qh2.queryPrimaryKey, nil);
    
    [[TXLManager sharedManager] unregisterQueryWithName:@"testRegisterQuery"];
    
    qh2 = [[TXLManager sharedManager] queryWithName:@"testRegisterQuery" error:&error];
    GHAssertNil(qh2, nil);
}

- (void)testRevisionSuccessorPrecursor {
    
    // create a new revision
    SQL(@"INSERT INTO txl_revision (previous) SELECT revision FROM txl_revision_head WHERE id = 1");
    TXLRevision *rev1 = [[TXLManager sharedManager] headRevision];
    
    // create a new revision
    SQL(@"INSERT INTO txl_revision (previous) SELECT revision FROM txl_revision_head WHERE id = 1");
    TXLRevision *rev2 = [[TXLManager sharedManager] headRevision];
    
    // create a new revision
    SQL(@"INSERT INTO txl_revision (previous) SELECT revision FROM txl_revision_head WHERE id = 1");
    TXLRevision *rev3 = [[TXLManager sharedManager] headRevision];
    
    
    GHAssertEqualObjects(rev1.successor, rev2, nil);
    GHAssertEqualObjects(rev2.successor, rev3, nil);
    
    GHAssertEqualObjects(rev3.precursor, rev2, nil);
    GHAssertEqualObjects(rev2.precursor, rev1, nil);
}

- (void)testRevisionBeforeAfter {
    
    // create a new revision
    SQL(@"INSERT INTO txl_revision (previous) SELECT revision FROM txl_revision_head WHERE id = 1");
    TXLRevision *rev1 = [[TXLManager sharedManager] headRevision];
    
    sleep(1);
    
    // create a new revision
    SQL(@"INSERT INTO txl_revision (previous) SELECT revision FROM txl_revision_head WHERE id = 1");
    TXLRevision *rev2 = [[TXLManager sharedManager] headRevision];
    
    sleep(1);
    
    // create a new revision
    SQL(@"INSERT INTO txl_revision (previous) SELECT revision FROM txl_revision_head WHERE id = 1");
    TXLRevision *rev3 = [[TXLManager sharedManager] headRevision];
    
    GHAssertEqualObjects([[TXLManager sharedManager] revisionBefore:rev2.timestamp], rev1, nil);
    GHAssertEqualObjects([[TXLManager sharedManager] revisionAfter:rev2.timestamp], rev3, nil);
    GHAssertNil([[TXLManager sharedManager] revisionAfter:rev3.timestamp], nil);
}

#pragma mark Processing

- (void)didStartProcessing {
    GHTestLog(@"Start Processing.");
}

- (void)didEndProcessing {
    GHTestLog(@"End Processing.");
    [self notify:kGHUnitWaitStatusSuccess];
}

@end

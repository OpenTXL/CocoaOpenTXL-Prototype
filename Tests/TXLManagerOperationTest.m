//
//  TXLManagerOperationTest.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 09.12.10.
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

#import "TXLManager.h"
#import "TXLStatement.h"
#import "TXLTerm.h"
#import "TXLMovingObject.h"
#import "TXLRevision.h"
#import "TXLContext.h"
#import "TXLDatabase.h"
#import "TXLInteger.h"

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import "NSDate+dateWithString.h"
#endif

#define SQL(x) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

@interface TXLManagerOperationTest : GHAsyncTestCase {
    
}

@end


@implementation TXLManagerOperationTest

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

#pragma mark -
#pragma mark Change Notification

- (void)didChangeContext:(TXLContext *)ctx
              inRevision:(TXLRevision *)rev {
        
}

#pragma mark Processing

- (void)didStartProcessing {
    GHTestLog(@"Start Processing.");
}

- (void)didEndProcessing {
    GHTestLog(@"End Processing.");
    [self notify:kGHUnitWaitStatusSuccess];
}

#pragma mark -
#pragma mark Tests

- (void)testUpdate {
    
    /* 
        This test checks if the update operation inserts a
        situation without temporal or spatial restriction
        correctly into the database.
     
        The update operation is done twice to se if the previsous
        inserted situation is removed corectly from the context.
     
        To verify the operation the content of the tables
            - txl_statement,
            - txl_statement_created and
            - txl_statement_removed
        is checked.
     */
    
    TXLDatabase *db = [[TXLManager sharedManager] database];
    __block NSError *error;
    __block TXLRevision *rev1;
    __block TXLRevision *rev2;
    
    // Check precondition
    // ---------------------------------------
    
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement" error:&error] count], nil);
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement_created" error:&error] count], nil);
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error] count], nil);
    
    // ---------------------------------------
    // Setup data for test
    
    // Create terms
    TXLTerm *subject1 = [TXLTerm termWithLiteral:@"subject1"];
    TXLTerm *subject2 = [TXLTerm termWithLiteral:@"subject2"];
    TXLTerm *predicate = [TXLTerm termWithLiteral:@"predicate"];
    TXLTerm *object = [TXLTerm termWithLiteral:@"object"];
    
    // Create a statement
    TXLStatement *statement1 = [TXLStatement statementWithSubject:subject1
                                                        predicate:predicate
                                                           object:object];
    
    TXLStatement *statement2 = [TXLStatement statementWithSubject:subject2
                                                        predicate:predicate
                                                           object:object];
    
    NSArray *statements1 = [NSArray arrayWithObject:statement1];
    NSArray *statements2 = [NSArray arrayWithObject:statement2];
    
    // Create a context
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                    host:@"TXLManagerOperationTest"
                                                                    path:[NSArray arrayWithObject:@"testUpdate"]
                                                                   error:nil];
    
    // ---------------------------------------
    // 1st update of the Context
    // ---------------------------------------
    GHTestLog(@"1st update of the Context");
    
    [self prepare];
    [context updateWithStatements:statements1
                  completionBlock:^(TXLRevision *r, NSError *e){
                      rev1 = [r retain];
                      error = [e retain];
                      // ---------------------------------------
                      // Notify the successful end of the operation.
                      [self notify:kGHUnitWaitStatusSuccess];
    }];
    
    // ---------------------------------------
    // Wait for completion
    
    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:100000.0];
    
    [rev1 autorelease];
    [error autorelease];
    
    // ---------------------------------------
    // Check new revision
    GHAssertNotNil(rev1, @"revision == nil indicates an error: %@", [error localizedDescription]);
    
    // ---------------------------------------
    // Check content of the corresponding tables.
    
    NSArray *result_statement;
    NSArray *result_statement_removed;
    NSArray *result_statement_created;
    
    
    // Check table txl_statement
    
    result_statement = [db executeSQL:@"SELECT * FROM txl_statement" error:&error];
    GHAssertNotNil(result_statement, [error localizedDescription]);
    GHAssertEquals([result_statement count], (NSUInteger)1, @"Expecting one entry in the table txl_statement.");
    
    TXLInteger *stPk1 = [[result_statement objectAtIndex:0] objectForKey:@"id"];
    GHAssertNotNil(stPk1, @"No primary key for statement 1.");
    
    GHAssertEquals([[[result_statement objectAtIndex:0] objectForKey:@"subject_id"] unsignedIntegerValue], subject1.primaryKey, nil);
    GHAssertEquals([[[result_statement objectAtIndex:0] objectForKey:@"predicate_id"] unsignedIntegerValue], predicate.primaryKey, nil);
    GHAssertEquals([[[result_statement objectAtIndex:0] objectForKey:@"object_id"] unsignedIntegerValue], object.primaryKey, nil);
    
    GHAssertEquals([[[result_statement objectAtIndex:0] objectForKey:@"context_id"] unsignedIntegerValue], context.primaryKey, nil);
    
	TXLMovingObject *mo = [TXLMovingObject movingObjectWithPrimaryKey:[[[result_statement objectAtIndex:0] objectForKey:@"mo_id"] unsignedIntegerValue]];
    GHAssertTrue([mo isOmnipresent], nil);
        
    // Check table txl_statement_removed
    
    result_statement_removed = [db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error];
    GHAssertNotNil(result_statement_removed, [error localizedDescription]);
    GHAssertEquals([result_statement_removed count], (NSUInteger)0, @"Expecting no entry in the table result_statement_removed.");
    
    
    // Check table txl_statement_created
    
    result_statement_created = [db executeSQL:@"SELECT * FROM txl_statement_created" error:&error];
    GHAssertNotNil(result_statement_created, [error localizedDescription]);
    GHAssertEquals([result_statement_created count], (NSUInteger)1, @"Expecting one entry in the table result_statement_created.");
    
    GHAssertEqualObjects([[result_statement_created objectAtIndex:0] objectForKey:@"statement_id"], stPk1, nil);
    
    GHAssertEquals([[[result_statement_created objectAtIndex:0] objectForKey:@"revision_id"] unsignedIntegerValue], rev1.primaryKey, nil);
    
    
    // ---------------------------------------
    // 2nd update of the Context
    // ---------------------------------------
    GHTestLog(@"2nd update of the Context");
    
    [self prepare];
    [context updateWithStatements:statements2
                  completionBlock:^(TXLRevision *r, NSError *e){
                      rev2 = [r retain];
                      error = [e retain];
                      // ---------------------------------------
                      // Notify the successful end of the operation.
                      [self notify:kGHUnitWaitStatusSuccess];
    }];
    
    // ---------------------------------------
    // Wait for completion
    
    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:10.0];
    
    [rev2 autorelease];
    [error autorelease];
    
    // ---------------------------------------
    // Check content of the corresponding tables.
    
    
    // Check table txl_statement
    
    result_statement = [db executeSQL:@"SELECT * FROM txl_statement ORDER BY id" error:&error];
    GHAssertNotNil(result_statement, [error localizedDescription]);
    GHTestLog(@"result_statement: %@", result_statement);
    GHAssertEquals([result_statement count], (NSUInteger)2, @"Expecting 2 entries in the table txl_statement.");
    
    GHAssertEqualObjects([[result_statement objectAtIndex:0] objectForKey:@"id"], stPk1, nil);
    
    GHAssertEquals([[[result_statement objectAtIndex:0] objectForKey:@"subject_id"] unsignedIntegerValue], subject1.primaryKey, nil);
    GHAssertEquals([[[result_statement objectAtIndex:0] objectForKey:@"predicate_id"] unsignedIntegerValue], predicate.primaryKey, nil);
    GHAssertEquals([[[result_statement objectAtIndex:0] objectForKey:@"object_id"] unsignedIntegerValue], object.primaryKey, nil);
    
    GHAssertEquals([[[result_statement objectAtIndex:0] objectForKey:@"context_id"] unsignedIntegerValue], context.primaryKey, nil);
    
	mo = [TXLMovingObject movingObjectWithPrimaryKey:[[[result_statement objectAtIndex:0] objectForKey:@"mo_id"] unsignedIntegerValue]];
    GHAssertTrue([mo isOmnipresent], nil);
    
    TXLInteger *stPk2 = [[result_statement objectAtIndex:1] objectForKey:@"id"];
    GHAssertNotNil(stPk2, @"No primary key for statement 2.");
    GHAssertNotEqualObjects(stPk1, stPk2, nil);
    
    GHAssertEquals([[[result_statement objectAtIndex:1] objectForKey:@"subject_id"] unsignedIntegerValue], subject2.primaryKey, nil);
    GHAssertEquals([[[result_statement objectAtIndex:1] objectForKey:@"predicate_id"] unsignedIntegerValue], predicate.primaryKey, nil);
    GHAssertEquals([[[result_statement objectAtIndex:1] objectForKey:@"object_id"] unsignedIntegerValue], object.primaryKey, nil);
    
    GHAssertEquals([[[result_statement objectAtIndex:1] objectForKey:@"context_id"] unsignedIntegerValue], context.primaryKey, nil);
    
	mo = [TXLMovingObject movingObjectWithPrimaryKey:[[[result_statement objectAtIndex:1] objectForKey:@"mo_id"] unsignedIntegerValue]];
    GHAssertTrue([mo isOmnipresent], nil);
	 
    // Check table txl_statement_removed
    
    result_statement_removed = [db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error];
    GHAssertNotNil(result_statement_removed, [error localizedDescription]);
    GHAssertEquals([result_statement_removed count], (NSUInteger)1, @"Expecting one entry in the table result_statement_removed.");
    
    GHAssertEqualObjects([[result_statement_removed objectAtIndex:0] objectForKey:@"statement_id"], stPk1, nil);
    GHAssertEquals([[[result_statement_removed objectAtIndex:0] objectForKey:@"revision_id"] unsignedIntegerValue], rev2.primaryKey, nil);
    
    
    // Check table txl_statement_created
    
    result_statement_created = [db executeSQL:@"SELECT * FROM txl_statement_created ORDER BY id" error:&error];
    GHAssertNotNil(result_statement_created, [error localizedDescription]);
    GHAssertEquals([result_statement_created count], (NSUInteger)2, @"Expecting two entries in the table result_statement_created.");
    
    GHAssertEqualObjects([[result_statement_created objectAtIndex:0] objectForKey:@"statement_id"], stPk1, nil);
    GHAssertEquals([[[result_statement_created objectAtIndex:0] objectForKey:@"revision_id"] unsignedIntegerValue], rev1.primaryKey, nil);
    
    GHAssertEqualObjects([[result_statement_created objectAtIndex:1] objectForKey:@"statement_id"], stPk2, nil);
    GHAssertEquals([[[result_statement_created objectAtIndex:1] objectForKey:@"revision_id"] unsignedIntegerValue], rev2.primaryKey, nil);
}

- (void)testUpdateWithMovingObject {
    
    // This test updates a context twice. The first update inserts a situation with
    // no temporal restriction. Therefore the context should contain only the
    // statement of this update. The second update has inserts a situation with
    // a temporal restriction from 11h to 15h in the interval from 11h to the distant
    // future.
    //
    // After these operations, the context contains the following two situations:
    //
    //   --------------- s1 -----||----- s2 ----|
    //   nil ---------------- 11h||11h ------15h|
    // 
    // s1: subject, predicate, object-1
    // s2: subject, predicate, object-2
    //
    
    TXLDatabase *db = [[TXLManager sharedManager] database];
    NSError *error;
    __block TXLRevision *rev1;
    __block TXLRevision *rev2;
    
    // Check precondition
    // ---------------------------------------
    
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement" error:&error] count], nil);
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement_created" error:&error] count], nil);
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error] count], nil);
    
    // ---------------------------------------
    // Setup data for test
    
    // create terms
    TXLTerm *subject = [TXLTerm termWithLiteral:@"subject"];
    TXLTerm *predicate = [TXLTerm termWithLiteral:@"predicate"];
    TXLTerm *object1 = [TXLTerm termWithLiteral:@"object-1"];
    TXLTerm *object2 = [TXLTerm termWithLiteral:@"object-2"];
    
    // create statements
    TXLStatement *statement1 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object1];
    
    TXLStatement *statement2 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object2];
    
    NSArray *statements1 = [NSArray arrayWithObject:statement1];
    NSArray *statements2 = [NSArray arrayWithObject:statement2];
    
    // create context
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                    host:@"TXLManagerOperationTest"
                                                                    path:[NSArray arrayWithObject:@"testUpdateWithMovingObject"]
                                                                   error:nil];
    
    // moving object to restrict the second update of the context
    TXLMovingObject *mo = [TXLMovingObject movingObjectWithBegin:[NSDate dateWithString:@"2010-09-29 11:00:00 +0200"]
                                                             end:[NSDate dateWithString:@"2010-09-29 15:00:00 +0200"]];
    
    // ---------------------------------------
    
    // update context with the first situation
    // without a moving object. after this update,
    // the context contains the statement 1 without
    // any spatial or temporal restriction.
    
    [self prepare];
    [context updateWithStatements:statements1 completionBlock:^(TXLRevision *rev, NSError *error){
        // update context with statement 2 with a
        // temporal restriction
        if (rev) {
            rev1 = [rev retain];
            [context updateWithStatements:statements2 movingObject:mo inIntervalFrom:mo.begin to:nil completionBlock:^(TXLRevision *rev, NSError *error){
                // Notify the successful end of the operation.
                if (rev) {
                    rev2 = [rev retain];
                    [self notify:kGHUnitWaitStatusSuccess];
                } else {
                    GHTestLog([error localizedDescription]);
                    [self notify:kGHUnitWaitStatusFailure];
                }
            }];
        } else {
            GHTestLog([error localizedDescription]);
            [self notify:kGHUnitWaitStatusFailure];
        }
    }];
    
    // ---------------------------------------
    // Wait for completion
    
    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:100000.0];
    
    [rev1 autorelease];
    [rev2 autorelease];
    
    
    // check content of corresponding tables
    // ---------------------------------------
    
    NSArray *result_statement;
    NSArray *result_statement_removed;
    NSArray *result_statement_created;
    
    result_statement = [db executeSQL:@"SELECT * FROM txl_statement WHERE NOT id IN (SELECT statement_id from txl_statement_removed) ORDER BY id" error:&error];
    GHAssertNotNil(result_statement, [error localizedDescription]);
    GHAssertEquals([result_statement count], (NSUInteger)2, nil);
    
    TXLMovingObject *mo1 = [TXLMovingObject movingObjectWithPrimaryKey:[[[result_statement objectAtIndex:0] objectForKey:@"mo_id"] unsignedIntegerValue]];
    GHAssertEqualObjects(mo1, [TXLMovingObject movingObjectWithBegin:nil end:[NSDate dateWithString:@"2010-09-29 11:00:00 +0200"]], nil);
        
    TXLMovingObject *mo2 = [TXLMovingObject movingObjectWithPrimaryKey:[[[result_statement objectAtIndex:1] objectForKey:@"mo_id"] unsignedIntegerValue]];
    GHAssertEqualObjects(mo2, [TXLMovingObject movingObjectWithBegin:[NSDate dateWithString:@"2010-09-29 11:00:00 +0200"]
                                                                     end:[NSDate dateWithString:@"2010-09-29 15:00:00 +0200"]], nil);

    
    // Check table txl_statement_removed
    
    result_statement_removed = [db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error];
    GHAssertNotNil(result_statement_removed, [error localizedDescription]);
    GHAssertEquals([result_statement_removed count], (NSUInteger)1, @"Expecting one entry in the table result_statement_removed.");
    GHAssertEquals([[[result_statement_removed objectAtIndex:0] objectForKey:@"revision_id"] unsignedIntegerValue], rev2.primaryKey, nil);
    
    // Check table txl_statement_created
    
    result_statement_created = [db executeSQL:@"SELECT * FROM txl_statement_created ORDER BY id" error:&error];
    GHAssertNotNil(result_statement_created, [error localizedDescription]);
    GHAssertEquals([result_statement_created count], (NSUInteger)3, @"Expecting 3 entries in the table result_statement_created.");
    
    GHAssertEquals([[[result_statement_created objectAtIndex:0] objectForKey:@"revision_id"] unsignedIntegerValue], rev1.primaryKey, nil);
    GHAssertEquals([[[result_statement_created objectAtIndex:1] objectForKey:@"revision_id"] unsignedIntegerValue], rev2.primaryKey, nil);
    GHAssertEquals([[[result_statement_created objectAtIndex:2] objectForKey:@"revision_id"] unsignedIntegerValue], rev2.primaryKey, nil);
}

- (void)testUpdateWithSameMovingObject {
    
    TXLDatabase *db = [[TXLManager sharedManager] database];
    NSError *error;
    __block TXLRevision *rev1;
    __block TXLRevision *rev2;
    
    // Check precondition
    // ---------------------------------------
    
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement" error:&error] count], nil);
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement_created" error:&error] count], nil);
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error] count], nil);
    
    // ---------------------------------------
    // Setup data for test
    
    // create terms
    TXLTerm *subject = [TXLTerm termWithLiteral:@"subject"];
    TXLTerm *predicate = [TXLTerm termWithLiteral:@"predicate"];
    TXLTerm *object1 = [TXLTerm termWithLiteral:@"object-1"];
    TXLTerm *object2 = [TXLTerm termWithLiteral:@"object-2"];
    
    
    // create statements
    TXLStatement *statement1 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object1];
    
    TXLStatement *statement2 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object2];
    
    NSArray *statements1 = [NSArray arrayWithObject:statement1];
    NSArray *statements2 = [NSArray arrayWithObject:statement2];
    
    // create context
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                    host:@"TXLManagerOperationTest"
                                                                    path:[NSArray arrayWithObject:@"testUpdateWithMovingObject"]
                                                                   error:nil];
    
    // moving object to restrict the second update of the context
    TXLMovingObject *mo = [TXLMovingObject movingObjectWithBegin:[NSDate dateWithString:@"2010-09-29 11:00:00 +0200"]
                                                             end:[NSDate dateWithString:@"2010-09-29 15:00:00 +0200"]];
    
    // ---------------------------------------
    
    // update context with the first situation
    // without a moving object. after this update,
    // the context contains the statement 1 without
    // any spatial or temporal restriction.
    
    [self prepare];
    [context updateWithStatements:statements1
                     movingObject:mo 
                   inIntervalFrom:mo.begin
                               to:mo.end
                  completionBlock:^(TXLRevision *rev, NSError *error) {
        // update context with statement 2 with a
        // temporal restriction
        if (rev) {
            rev1 = [rev retain];
            [context updateWithStatements:statements2
                             movingObject:mo
                           inIntervalFrom:mo.begin
                                       to:mo.end
                          completionBlock:^(TXLRevision *rev, NSError *error) {
                // Notify the successful end of the operation.
                if (rev) {
                    rev2 = [rev retain];
                    [self notify:kGHUnitWaitStatusSuccess];
                } else {
                    GHTestLog([error localizedDescription]);
                    [self notify:kGHUnitWaitStatusFailure];
                }
            }];
        } else {
            GHTestLog([error localizedDescription]);
            [self notify:kGHUnitWaitStatusFailure];
        }
    }];
    
    // ---------------------------------------
    // Wait for completion
    
    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:10.0];
    
    [rev1 autorelease];
    [rev2 autorelease];
    
    
    // check content of corresponding tables
    // ---------------------------------------
    
    NSArray *result_statement;
    NSArray *result_statement_removed;
    NSArray *result_statement_created;
    
    result_statement = [db executeSQL:@"SELECT txl_statement.* FROM txl_statement WHERE NOT txl_statement.id IN (SELECT statement_id from txl_statement_removed)" error:&error];
    GHAssertNotNil(result_statement, [error localizedDescription]);
    GHAssertEquals([result_statement count], (NSUInteger)1, nil);
    
    
    TXLMovingObject *mo1 = [TXLMovingObject movingObjectWithPrimaryKey:[[[result_statement objectAtIndex:0] objectForKey:@"mo_id"] unsignedIntegerValue]];
    GHAssertEqualObjects(mo1, [TXLMovingObject movingObjectWithBegin:[NSDate dateWithString:@"2010-09-29 11:00:00 +0200"]
                                                                 end:[NSDate dateWithString:@"2010-09-29 15:00:00 +0200"]], nil);

    
    // Check table txl_statement_removed
    
    result_statement_removed = [db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error];
    GHAssertNotNil(result_statement_removed, [error localizedDescription]);
    GHAssertEquals([result_statement_removed count], (NSUInteger)1, @"Expecting one entry in the table result_statement_removed.");
    GHAssertEquals([[[result_statement_removed objectAtIndex:0] objectForKey:@"revision_id"] unsignedIntegerValue], rev2.primaryKey, nil);
    
    // Check table txl_statement_created
    
    result_statement_created = [db executeSQL:@"SELECT * FROM txl_statement_created ORDER BY id" error:&error];
    GHAssertNotNil(result_statement_created, [error localizedDescription]);
    GHAssertEquals([result_statement_created count], (NSUInteger)2, @"Expecting 3 entries in the table result_statement_created.");
    
    GHAssertEquals([[[result_statement_created objectAtIndex:0] objectForKey:@"revision_id"] unsignedIntegerValue], rev1.primaryKey, nil);
    GHAssertEquals([[[result_statement_created objectAtIndex:1] objectForKey:@"revision_id"] unsignedIntegerValue], rev2.primaryKey, nil);
}

- (void)testUpdateOtherContext {
    
    TXLDatabase *db = [[TXLManager sharedManager] database];
    NSError *error;
    __block TXLRevision *rev1;
    __block TXLRevision *rev2;
    
    // Check precondition
    // ---------------------------------------
    
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement" error:&error] count], nil);
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement_created" error:&error] count], nil);
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error] count], nil);
    
    // ---------------------------------------
    // Setup data for test
    
    // create terms
    TXLTerm *subject = [TXLTerm termWithLiteral:@"subject"];
    TXLTerm *predicate = [TXLTerm termWithLiteral:@"predicate"];
    TXLTerm *object1 = [TXLTerm termWithLiteral:@"object-1"];
    TXLTerm *object2 = [TXLTerm termWithLiteral:@"object-2"];
    
    
    // create statements
    TXLStatement *statement1 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object1];
    
    TXLStatement *statement2 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object2];
    
    NSArray *statements1 = [NSArray arrayWithObject:statement1];
    NSArray *statements2 = [NSArray arrayWithObject:statement2];
    
    // create context
    TXLContext *context1 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"TXLManagerOperationTest"
                                                                     path:[NSArray arrayWithObject:@"testUpdateOtherContext1"]
                                                                    error:nil];
    
    TXLContext *context2 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"TXLManagerOperationTest"
                                                                     path:[NSArray arrayWithObject:@"testUpdateOtherContext2"]
                                                                    error:nil];
     
    // moving object to restrict the second update of the context
    TXLMovingObject *mo = [TXLMovingObject movingObjectWithBegin:[NSDate dateWithString:@"2010-09-29 11:00:00 +0200"]
                                                             end:[NSDate dateWithString:@"2010-09-29 15:00:00 +0200"]];
    
    // ---------------------------------------
    
    // update context with the first situation
    // without a moving object. after this update,
    // the context contains the statement 1 without
    // any spatial or temporal restriction.
    
    [self prepare];
    [context1 updateWithStatements:statements1
                      movingObject:mo 
                    inIntervalFrom:mo.begin
                                to:mo.end
                   completionBlock:^(TXLRevision *rev, NSError *error) {
                      // update context with statement 2 with a
                      // temporal restriction
                      if (rev) {
                          rev1 = [rev retain];
                          [context2 updateWithStatements:statements2
                                            movingObject:mo
                                          inIntervalFrom:mo.begin
                                                      to:mo.end
                                         completionBlock:^(TXLRevision *rev, NSError *error) {
                                            // Notify the successful end of the operation.
                                            if (rev) {
                                                rev2 = [rev retain];
                                                [self notify:kGHUnitWaitStatusSuccess];
                                            } else {
                                                GHTestLog([error localizedDescription]);
                                                [self notify:kGHUnitWaitStatusFailure];
                                            }
                                        }];
                      } else {
                          GHTestLog([error localizedDescription]);
                          [self notify:kGHUnitWaitStatusFailure];
                      }
                  }];
    
    // ---------------------------------------
    // Wait for completion
    
    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:10.0];
    
    [rev1 autorelease];
    [rev2 autorelease];
    
    
    // check content of corresponding tables
    // ---------------------------------------
    
    NSArray *result_statement;
    NSArray *result_statement_removed;
    NSArray *result_statement_created;
    
    result_statement = [db executeSQL:@"SELECT txl_statement.* FROM txl_statement WHERE NOT txl_statement.id IN (SELECT statement_id from txl_statement_removed) ORDER BY id" error:&error];
    GHAssertNotNil(result_statement, [error localizedDescription]);
    GHAssertEquals([result_statement count], (NSUInteger)2, nil);
    
    
    TXLMovingObject *mo1 = [TXLMovingObject movingObjectWithPrimaryKey:[[[result_statement objectAtIndex:0] objectForKey:@"mo_id"] unsignedIntegerValue]];
    GHAssertEqualObjects(mo1, mo, nil);
    
    TXLMovingObject *mo2 = [TXLMovingObject movingObjectWithPrimaryKey:[[[result_statement objectAtIndex:1] objectForKey:@"mo_id"] unsignedIntegerValue]];
    GHAssertEqualObjects(mo2, mo, nil);
    
    
    // Check table txl_statement_removed
    
    result_statement_removed = [db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error];
    GHAssertNotNil(result_statement_removed, [error localizedDescription]);
    GHAssertEquals([result_statement_removed count], (NSUInteger)0, @"Expecting no entry in the table result_statement_removed.");

    
    // Check table txl_statement_created
    
    result_statement_created = [db executeSQL:@"SELECT * FROM txl_statement_created ORDER BY id" error:&error];
    GHAssertNotNil(result_statement_created, [error localizedDescription]);
    GHAssertEquals([result_statement_created count], (NSUInteger)2, @"Expecting 3 entries in the table result_statement_created.");
    GHAssertEquals([[[result_statement_created objectAtIndex:0] objectForKey:@"revision_id"] unsignedIntegerValue], rev1.primaryKey, nil);
    GHAssertEquals([[[result_statement_created objectAtIndex:1] objectForKey:@"revision_id"] unsignedIntegerValue], rev2.primaryKey, nil);
}

- (void)testUpdateWithMovingObjectAfterMovingObject {
    
    TXLDatabase *db = [[TXLManager sharedManager] database];
    NSError *error;
    __block TXLRevision *rev1;
    __block TXLRevision *rev2;
    
    // Check precondition
    // ---------------------------------------
    
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement" error:&error] count], nil);
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement_created" error:&error] count], nil);
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error] count], nil);
    
    // ---------------------------------------
    // Setup data for test
    
    // create terms
    TXLTerm *subject = [TXLTerm termWithLiteral:@"subject"];
    TXLTerm *predicate = [TXLTerm termWithLiteral:@"predicate"];
    TXLTerm *object1 = [TXLTerm termWithLiteral:@"object-1"];
    TXLTerm *object2 = [TXLTerm termWithLiteral:@"object-2"];
    
    
    // create statements
    TXLStatement *statement1 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object1];
    
    TXLStatement *statement2 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object2];
    
    NSArray *statements1 = [NSArray arrayWithObject:statement1];
    NSArray *statements2 = [NSArray arrayWithObject:statement2];
    
    // create context
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                    host:@"TXLManagerOperationTest"
                                                                    path:[NSArray arrayWithObject:@"testUpdateWithMovingObject"]
                                                                   error:nil];
    
    // moving object to restrict the second update of the context
    TXLMovingObject *mo1 = [TXLMovingObject movingObjectWithBegin:[NSDate dateWithString:@"2010-09-29 11:00:00 +0200"]
                                                             end:[NSDate dateWithString:@"2010-09-29 15:00:00 +0200"]];
    
    TXLMovingObject *mo2 = [TXLMovingObject movingObjectWithBegin:[NSDate dateWithString:@"2010-09-29 15:00:00 +0200"]
                                                              end:[NSDate dateWithString:@"2010-09-29 18:00:00 +0200"]];
    
    // ---------------------------------------
    
    // update context with the first situation
    // without a moving object. after this update,
    // the context contains the statement 1 without
    // any spatial or temporal restriction.
    
    [self prepare];
    [context updateWithStatements:statements1
                     movingObject:mo1 
                   inIntervalFrom:mo1.begin
                               to:mo1.end
                  completionBlock:^(TXLRevision *rev, NSError *error) {
                      // update context with statement 2 with a
                      // temporal restriction
                      if (rev) {
                          rev1 = [rev retain];
                          [context updateWithStatements:statements2
                                           movingObject:mo2
                                         inIntervalFrom:mo2.begin
                                                     to:mo2.end
                                        completionBlock:^(TXLRevision *rev, NSError *error) {
                                            // Notify the successful end of the operation.
                                            if (rev) {
                                                rev2 = [rev retain];
                                                [self notify:kGHUnitWaitStatusSuccess];
                                            } else {
                                                GHTestLog([error localizedDescription]);
                                                [self notify:kGHUnitWaitStatusFailure];
                                            }
                                        }];
                      } else {
                          GHTestLog([error localizedDescription]);
                          [self notify:kGHUnitWaitStatusFailure];
                      }
                  }];
    
    // ---------------------------------------
    // Wait for completion
    
    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:10.0];
    
    [rev1 autorelease];
    [rev2 autorelease];
    
    
    // check content of corresponding tables
    // ---------------------------------------
    
    NSArray *result_statement;
    NSArray *result_statement_removed;
    NSArray *result_statement_created;
    
    result_statement = [db executeSQL:@"SELECT txl_statement.* FROM txl_statement WHERE NOT txl_statement.id IN (SELECT statement_id from txl_statement_removed) ORDER BY txl_statement.id" error:&error];
    GHAssertNotNil(result_statement, [error localizedDescription]);
    GHAssertEquals([result_statement count], (NSUInteger)2, nil);
    
    
    TXLMovingObject *mo1_ = [TXLMovingObject movingObjectWithPrimaryKey:[[[result_statement objectAtIndex:0] objectForKey:@"mo_id"] unsignedIntegerValue]];
    GHAssertEqualObjects(mo1_, mo1, nil);
    
    TXLMovingObject *mo2_ = [TXLMovingObject movingObjectWithPrimaryKey:[[[result_statement objectAtIndex:1] objectForKey:@"mo_id"] unsignedIntegerValue]];
    GHAssertEqualObjects(mo2_, mo2, nil);
    
    
    // Check table txl_statement_removed
    
    result_statement_removed = [db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error];
    GHAssertNotNil(result_statement_removed, [error localizedDescription]);
    GHAssertEquals([result_statement_removed count], (NSUInteger)0, @"Expecting one entry in the table result_statement_removed.");
    
    // Check table txl_statement_created
    
    result_statement_created = [db executeSQL:@"SELECT * FROM txl_statement_created ORDER BY id" error:&error];
    GHAssertNotNil(result_statement_created, [error localizedDescription]);
    GHAssertEquals([result_statement_created count], (NSUInteger)2, @"Expecting 2 entries in the table result_statement_created.");
    
    GHAssertEquals([[[result_statement_created objectAtIndex:0] objectForKey:@"revision_id"] unsignedIntegerValue], rev1.primaryKey, nil);
    GHAssertEquals([[[result_statement_created objectAtIndex:1] objectForKey:@"revision_id"] unsignedIntegerValue], rev2.primaryKey, nil);
}


- (void)testClear {
    
    
    TXLDatabase *db = [[TXLManager sharedManager] database];
    __block NSError *error;
    __block TXLRevision *rev1;
    __block TXLRevision *rev2;
    
    // Check precondition
    // ---------------------------------------
    
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement" error:&error] count], nil);
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement_created" error:&error] count], nil);
    GHAssertEquals((NSUInteger)0, [[db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error] count], nil);
    
    // ---------------------------------------
    // Setup data for test
    
    // Create terms
    TXLTerm *subject = [TXLTerm termWithLiteral:@"subject"];
    TXLTerm *predicate = [TXLTerm termWithLiteral:@"predicate"];
    TXLTerm *object = [TXLTerm termWithLiteral:@"object"];
    
    // Create a statement
    TXLStatement *statement = [TXLStatement statementWithSubject:subject
                                                       predicate:predicate
                                                          object:object];
    
    NSArray *statements = [NSArray arrayWithObject:statement];
    
    // Create a context
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                    host:@"TXLManagerOperationTest"
                                                                    path:[NSArray arrayWithObject:@"testUpdate"]
                                                                   error:nil];
    
    // ---------------------------------------
    // 1st update of the Context
    // ---------------------------------------
    GHTestLog(@"1st update of the Context");
    
    [self prepare];
    [context updateWithStatements:statements
                  completionBlock:^(TXLRevision *r, NSError *e){
                      rev1 = [r retain];
                      error = [e retain];
                      // ---------------------------------------
                      // Notify the successful end of the operation.
                      [self notify:kGHUnitWaitStatusSuccess];
                  }];
    
    
    
    // ---------------------------------------
    // Wait for completion
    
    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:10.0];
    
    [rev1 autorelease];
    [error autorelease];
    
    // ---------------------------------------
    // Check new revision
    
    GHAssertNotNil(rev1, @"revision == nil indicates an error: %@", [error localizedDescription]);
    
    // ---------------------------------------
    // Check content of the corresponding tables.
    
    NSArray *result_statement;
    NSArray *result_statement_removed;
    NSArray *result_statement_created;
    
    
    // Check table txl_statement
    
    result_statement = [db executeSQL:@"SELECT * FROM txl_statement" error:&error];
    GHAssertNotNil(result_statement, [error localizedDescription]);
    GHAssertEquals([result_statement count], (NSUInteger)1, @"Expecting one entry in the table txl_statement.");
    
    TXLInteger *stPk1 = [[result_statement objectAtIndex:0] objectForKey:@"id"];
    GHAssertNotNil(stPk1, @"No primary key for statement 1.");
    
    
    // Check table txl_statement_removed
    
    result_statement_removed = [db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error];
    GHAssertNotNil(result_statement_removed, [error localizedDescription]);
    GHAssertEquals([result_statement_removed count], (NSUInteger)0, @"Expecting no entry in the table result_statement_removed.");
    
    
    // Check table txl_statement_created
    
    result_statement_created = [db executeSQL:@"SELECT * FROM txl_statement_created" error:&error];
    GHAssertNotNil(result_statement_created, [error localizedDescription]);
    GHAssertEquals([result_statement_created count], (NSUInteger)1, @"Expecting one entry in the table result_statement_created.");
    
    GHAssertEqualObjects([[result_statement_created objectAtIndex:0] objectForKey:@"statement_id"], stPk1, nil);
    
    GHAssertEquals([[[result_statement_created objectAtIndex:0] objectForKey:@"revision_id"] unsignedIntegerValue], rev1.primaryKey, nil);
    
    
    // ---------------------------------------
    // clear context
    // ---------------------------------------
    GHTestLog(@"clear context");
    
    [self prepare];
    [context clear:^(TXLRevision *r, NSError *e){
        rev2 = [r retain];
        error = [e retain];
        // ---------------------------------------
        // Notify the successful end of the operation.
        [self notify:kGHUnitWaitStatusSuccess];
    }];
    
    
    // ---------------------------------------
    // Wait for completion
    
    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:10.0];
    
    [rev2 autorelease];
    [error autorelease];
    
    // ---------------------------------------
    // Check new revision
    
    GHAssertNotNil(rev2, @"revision == nil indicates an error: %@", [error localizedDescription]);
    
    // ---------------------------------------
    // Check content of the corresponding tables.
    
    
    // Check table txl_statement
    
    result_statement = [db executeSQL:@"SELECT * FROM txl_statement" error:&error];
    GHAssertNotNil(result_statement, [error localizedDescription]);
    GHAssertEquals([result_statement count], (NSUInteger)1, @"Expecting one entry in the table txl_statement.");
    
    GHAssertEqualObjects([[result_statement objectAtIndex:0] objectForKey:@"id"], stPk1, nil);
    
    
    // Check table txl_statement_removed
    
    result_statement_removed = [db executeSQL:@"SELECT * FROM txl_statement_removed" error:&error];
    GHAssertNotNil(result_statement_removed, [error localizedDescription]);
    GHAssertEquals([result_statement_removed count], (NSUInteger)1, @"Expecting one entry in the table result_statement_removed.");
    
    GHAssertEqualObjects([[result_statement_removed objectAtIndex:0] objectForKey:@"statement_id"], stPk1, nil);
    GHAssertEquals([[[result_statement_removed objectAtIndex:0] objectForKey:@"revision_id"] unsignedIntegerValue], rev2.primaryKey, nil);
    
    // Check table txl_statement_created
    
    result_statement_created = [db executeSQL:@"SELECT * FROM txl_statement_created" error:&error];
    GHAssertNotNil(result_statement_created, [error localizedDescription]);
    GHAssertEquals([result_statement_created count], (NSUInteger)1, @"Expecting one entry in the table result_statement_created.");
    
    GHAssertEqualObjects([[result_statement_created objectAtIndex:0] objectForKey:@"statement_id"], stPk1, nil);
    GHAssertEquals([[[result_statement_created objectAtIndex:0] objectForKey:@"revision_id"] unsignedIntegerValue], rev1.primaryKey, nil);
}

@end

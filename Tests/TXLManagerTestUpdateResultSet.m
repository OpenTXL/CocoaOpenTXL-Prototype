//
//  TXLManagerTestUpdateResultSet.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 21.02.11.
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

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import "NSDate+dateWithString.h"
#endif
#import "TXLDatabase.h"
#import "TXLManager.h"
#import "TXLQueryHandle.h"
#import "TXLTerm.h"
#import "TXLStatement.h"
#import "TXLContext.h"
#import "TXLResultSet.h"

#import "TXLMovingObjectSequence.h"
#import "TXLMovingObject.h"

#define SQL(x) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

@interface TXLManagerTestUpdateResultSet : GHAsyncTestCase {
    TXLResultSet *resultSet;
    TXLRevision *resultRevision;
}

@property (retain) TXLResultSet *resultSet;
@property (retain) TXLRevision *resultRevision;

@end

@implementation TXLManagerTestUpdateResultSet

@synthesize resultSet;
@synthesize resultRevision;

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
    
    self.resultSet = nil;
    self.resultRevision = nil;
    [TXLManager sharedManager].delegate = nil;
}

#pragma mark -
#pragma mark Test

- (void)test {
    
    /*
     * Every update operation can change the set of statements, that are valid regarding
     * to a specific context. This changes make take effect to the validity of the query
     * resultsets, that rely on that context. So after updating a context, all queries that
     * rely on that context have to be evaluated resulting in an updated resultset for each
     * such query. This test will test, whether the update of the query resultsets works after
     * updating a context.
     */
    
    NSError *error;
    
    // create context
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                    host:@"TXLManagerTestUpdateResultSet"
                                                                    path:nil
                                                                   error:nil];    
    [self prepare];
    [context clear:^(TXLRevision *r, NSError *error){
        [self notify:kGHUnitWaitStatusSuccess];
    }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:120.0];
    
    // ---------------------------------------
    // Create a query, that relies on context 
    // <txl://weather.situmet>
    
    TXLQueryHandle *qh = [[TXLManager sharedManager] queryWithName:@"TXLManagerTestUpdateResultSet"
                                                             error:nil];
    if (qh == nil) {
        qh = [[TXLManager sharedManager] registerQueryWithName:@"TXLManagerTestUpdateResultSet"
                                                    expression:@"PREFIX m: <http://schema.situmet.at/meteorology#> SELECT ?temp FROM <txl://TXLManagerTestUpdateResultSet> WHERE { [m:temperature ?temp]. }"
                                                    parameters:nil
                                                       options:nil
                                                         error:&error];
    }
    GHAssertNotNil(qh, [error localizedDescription]);
    
    // ---------------------------------------
    // Setup statements for context 
    // <txl://weather.situmet.at>
    
    
    // create terms    
    TXLTerm *subject = [TXLTerm termWithBlankNode:@"subject"];
    TXLTerm *predicate = [TXLTerm termWithIRI:@"http://schema.situmet.at/meteorology#temperature"];
    TXLTerm *object = [TXLTerm termWithDouble:10.0];
    
    // create statement
    TXLStatement *statement = [TXLStatement statementWithSubject:subject
                                                       predicate:predicate
                                                          object:object];
    NSArray *statements = [NSArray arrayWithObject:statement];
    
    qh.delegate = self;
    
    [self prepare];
    [context updateWithStatements:statements completionBlock:^(TXLRevision *r, NSError *error){}];
    
    // ---------------------------------------
    // Wait for completion
    
    
    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:120.0];
    
    for (int i = 0; i < [resultSet count]; i++) {
        GHTestLog(@"moving object sequence at index %d: %@", i, [resultSet movingObjectSequenceAtIndex:i]);
        GHTestLog(@"values at index %d                : %@", i, [resultSet valuesAtIndex:i]);
    }
    
    GHAssertEquals([resultSet count], (NSUInteger)1, nil);
    GHAssertEqualObjects([resultSet valuesAtIndex:0], [NSDictionary dictionaryWithObject:object forKey:@"temp"], nil);
    GHAssertEqualObjects([resultSet movingObjectSequenceAtIndex:0], [TXLMovingObjectSequence sequenceWithMovingObject:[TXLMovingObject omnipresentMovingObject]], nil);
    
    [[TXLManager sharedManager] unregisterQueryWithName:@"TXLManagerTestUpdateResultSet"];
}

#pragma mark -
#pragma mark TXLResultSet Delegate 

- (void)continuousQuery:(TXLQueryHandle *)query
        hasNewResultSet:(TXLResultSet *)result
            forRevision:(TXLRevision *)revision {
    GHTestLog(@"Delegate for result set called.");
    self.resultSet = result;
    self.resultRevision = revision;
    [self notify:kGHUnitWaitStatusSuccess];
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




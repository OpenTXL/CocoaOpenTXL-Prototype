//
//  TXLContextSituationDefinitionTest.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 09.03.11.
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
#import "TXLContext.h"
#import "TXLDatabase.h"
#import "TXLQueryHandle.h"
#import "TXLResultSet.h"
#import "TXLSnapshot.h"
#import "TXLMovingObjectSequence.h"
#import "TXLGeometryCollection.h"
#import "TXLMovingObject.h"
#import "TXLTerm.h"

#define SQL(x) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

@interface TXLContextSituationDefinitionTest : GHAsyncTestCase {}
@property (retain) TXLQueryHandle *qh;
@end

@implementation TXLContextSituationDefinitionTest

@synthesize qh;

- (void)dealloc {
    [qh release];
    [super dealloc];
}

#pragma mark -
#pragma mark Set Up & Tear Down

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
    
    NSError *error;
    
    // import spatial situations (resp. import dataset)
    // --------------------------------------------------------------
    
//	NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"n3" inDirectory:nil];
//    for (NSString *path in paths) {
//        BOOL result = [[TXLManager sharedManager] importSpatialSituationFromFileAtPath:path
//                                                                        inIntervalFrom:nil 
//                                                                                    to:nil 
//                                                                                 error:&error
//                                                                       completionBlock:^(TXLRevision *rev, NSError *error){
//                                                                           GHTestLog(@"Spatial situation from file '%@' imported.", path);
//                                                                       }];
//        GHAssertTrue(result, @"Importing Spatial Situation (%@) failed: %@", path, error);
//    }
    
    
    BOOL result = [[TXLManager sharedManager] importSpatialSituationFromFileAtPath:[[NSBundle mainBundle] pathForResource:@"16-event-salzburg-1" ofType:@"n3"]
                                                                    inIntervalFrom:nil 
                                                                                to:nil 
                                                                             error:&error
                                                                   completionBlock:^(TXLRevision *rev, NSError *error){
                                                                       GHTestLog(@"Spatial situation from file '%@' imported.", [[NSBundle mainBundle] pathForResource:@"16-event-salzburg-1" ofType:@"n3"]);
                                                                   }];
    GHAssertTrue(result, @"Importing Spatial Situation (%@) failed: %@", [[NSBundle mainBundle] pathForResource:@"16-event-salzburg-1" ofType:@"n3"], error);
    
    result = [[TXLManager sharedManager] importSpatialSituationFromFileAtPath:[[NSBundle mainBundle] pathForResource:@"travel-route" ofType:@"n3"]
                                                                    inIntervalFrom:nil 
                                                                                to:nil 
                                                                             error:&error
                                                                   completionBlock:^(TXLRevision *rev, NSError *error){
                                                                       GHTestLog(@"Spatial situation from file '%@' imported.", [[NSBundle mainBundle] pathForResource:@"travel-route" ofType:@"n3"]);
                                                                   }];
    GHAssertTrue(result, @"Importing Spatial Situation (%@) failed: %@", [[NSBundle mainBundle] pathForResource:@"travel-route" ofType:@"n3"], error);
}

- (void)tearDown {
    
    if ([TXLManager sharedManager].processing) {
        [self prepare];
        [self waitForStatus:kGHUnitWaitStatusSuccess
                    timeout:120.0];
    }
    self.qh = nil;
    [TXLManager sharedManager].delegate = nil;
}

#pragma mark -
#pragma mark Processing

- (void)didStartProcessing {
    GHTestLog(@"Start Processing.");
}

- (void)didEndProcessing {
    GHTestLog(@"End Processing.");
    [self notify:kGHUnitWaitStatusSuccess];
}

#pragma mark -
#pragma mark Test

- (void)test {
    
    // Wait for end of processing
    GHTestLog(@"Wait for end of processing ...");
    if ([TXLManager sharedManager].processing) {
        [self prepare];
        [self waitForStatus:kGHUnitWaitStatusSuccess
                    timeout:120.0];
    }
    GHTestLog(@"... done.");
    
    GHTestLog(@"Begin test.");
    
    
    NSError *error;
    NSString *expression = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"construct_events_on_tour" ofType:@"sq"]
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    GHAssertNotNil(expression, [error localizedDescription]);
    
    TXLContext *ctx = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                host:@"localhost"
                                                                path:[NSArray arrayWithObject:@"tour-events"]
                                                               error:&error];
    GHAssertNotNil(ctx, [error localizedDescription]);
    
    GHTestLog(@"Set situation definition for context: %@\n%@", ctx, expression);
    
    BOOL success = [ctx setSituationDefinition:expression
                                   withOptions:nil
                                         error:&error];
    
    GHAssertTrue(success, [error localizedDescription]);
    
    // Wait for end of processing
    GHTestLog(@"Wait for end of processing ...");
    if ([TXLManager sharedManager].processing) {
        [self prepare];
        [self waitForStatus:kGHUnitWaitStatusSuccess
                    timeout:120.0];
    }
    GHTestLog(@"... done.");
    
    
    self.qh = [[TXLManager sharedManager] queryWithName:@"tour-events" error:nil];
    if (qh == nil) {
        NSString *expression = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tour-events" ofType:@"sq"]
                                                         encoding:NSUTF8StringEncoding
                                                            error:&error];
        GHAssertNotNil(expression, [error localizedDescription]);
        
        GHTestLog(@"Register query with name: tour-events\n%@", expression);
        
        self.qh = [[TXLManager sharedManager] registerQueryWithName:@"tour-events"
                                                         expression:expression
                                                         parameters:nil
                                                            options:nil
                                                              error:&error];
    }
    GHAssertNotNil(self.qh, [error localizedDescription]);
    
    self.qh.delegate = self;
    
    // Wait for end of processing
    GHTestLog(@"Wait for end of processing ...");
    if ([TXLManager sharedManager].processing) {
        [self prepare];
        [self waitForStatus:kGHUnitWaitStatusSuccess
                    timeout:120.0];
    }
    GHTestLog(@"... done.");
    
    TXLResultSet *rs = [self.qh resultSetForRevision:self.qh.lastEvaluation];
    GHAssertNotNil(rs, nil);
    
    for (NSUInteger i = 0; i < [rs count]; i++) {
        GHTestLog(@"row (%d): %@ %@", i, [rs valuesAtIndex:i], [rs movingObjectSequenceAtIndex:i]);
    }
    
    GHAssertEquals([rs count], (NSUInteger)1, nil);
    
    GHAssertEqualObjects([rs valuesAtIndex:0], [NSDictionary dictionaryWithObject:[TXLTerm termWithInteger:16] forKey:@"event_id"], nil);
}

#pragma mark -
#pragma mark Query Handle Delegate 

- (void)continuousQuery:(TXLQueryHandle *)query
        hasNewResultSet:(TXLResultSet *)result
            forRevision:(TXLRevision *)revision {
    GHTestLog(@"Delegate for result set called.");
}

@end

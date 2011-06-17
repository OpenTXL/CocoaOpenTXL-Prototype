//
//  TXLQueryTest.m
//  OpenTXL
//
//  Created by Nico Nachtigall on 16.02.11.
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
#import "TXLResultSet.h"
#import "TXLQueryHandle.h"
#import "TXLMovingObject.h"
#import "TXLMovingObjectSequence.h"
#import "TXLSnapshot.h"
#import "TXLGeometryCollection.h"
#import "TXLManager.h"
#import "TXLDatabase.h"

#define SQL(x) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

@interface TXLQueryTest : GHAsyncTestCase <TXLContinuousQueryDelegateProtocol> {
	
}

- (BOOL)resultset:(TXLResultSet *)rs isEqual:(NSString *)path error:(NSError **)error;

@end

@implementation TXLQueryTest

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
}

- (void)testEvaluationQueryEventsInCities {
    
	NSError *error;
    
    // import spatial situations (resp. import dataset)
    // --------------------------------------------------------------
    
	NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"n3" inDirectory:nil];
    for (NSString *path in paths) {
        [self prepare];
        
        BOOL result = [[TXLManager sharedManager] importSpatialSituationFromFileAtPath:path
                                                                        inIntervalFrom:nil 
                                                                                    to:nil 
                                                                                 error:&error
                                                                       completionBlock:^(TXLRevision *rev, NSError *error){
                                                                           [self notify:kGHUnitWaitStatusSuccess];
                                                                       }];
        
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:120.0];
        
        GHAssertTrue(result, @"Importing Spatial Situation (%@) failed: %@", path, error);
    }
    
    // register sparql query and therefore test the first
    // evaluation of the registered sparql query
    // --------------------------------------------------------------

    NSString *expr = [NSString stringWithContentsOfFile:
                                               [[NSBundle mainBundle] pathForResource:@"events_in_cities" ofType:@"sq"]
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
    TXLQueryHandle *query = [[TXLManager sharedManager] registerQueryWithName:@"events_in_cities"
                                                                   expression:expr
                                                                   parameters:nil
                                                                      options:nil
                                                                        error:&error];

    GHAssertNotNil(query, @"Registering the query (%@) failed: %@", expr, error);
    
    query.delegate = self;
    
    [self prepare];
    
    // wait until the evaluation of the query succeeeded
    // --------------------------------------------------------------
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:120.0];
    
    // test the retrieved resultset from the evaluation
    // --------------------------------------------------------------
    
    GHAssertTrue([self resultset:[query resultSetForRevision:[[TXLManager sharedManager] headRevision]] 
                         isEqual:[[NSBundle mainBundle] pathForResource:@"events_in_cities" ofType:@"res"]
                           error:&error], @"Retrieved unexpected resultset from the query evaluation! (%@)", error);
}

- (void)testEvaluationQueryEventsOnTour {
    
	NSError *error;
    
    // import spatial situations (resp. import dataset)
    // --------------------------------------------------------------
    
	NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"n3" inDirectory:nil];
    for (NSString *path in paths) {
        [self prepare];
        
        BOOL result = [[TXLManager sharedManager] importSpatialSituationFromFileAtPath:path
                                                                        inIntervalFrom:nil 
                                                                                    to:nil 
                                                                                 error:&error
                                                                       completionBlock:^(TXLRevision *rev, NSError *error){
                                                                           [self notify:kGHUnitWaitStatusSuccess];
                                                                       }];
        
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:120.0];
        
        GHAssertTrue(result, @"Importing Spatial Situation (%@) failed: %@", path, error);
    }
    
    // register sparql query and therefore test the first
    // evaluation of the registered sparql query
    // --------------------------------------------------------------
    
    NSString *expr = [NSString stringWithContentsOfFile:
                      [[NSBundle mainBundle] pathForResource:@"events_on_tour" ofType:@"sq"]
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
    TXLQueryHandle *query = [[TXLManager sharedManager] registerQueryWithName:@"events_on_tour"
                                                                   expression:expr
                                                                   parameters:nil
                                                                      options:nil
                                                                        error:&error];
    
    GHAssertNotNil(query, @"Registering the query (%@) failed: %@", expr, error);
    
    query.delegate = self;
    
    [self prepare];
    
    // wait until the evaluation of the query succeeeded
    // --------------------------------------------------------------
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:120.0];
    
    // test the retrieved resultset from the evaluation
    // --------------------------------------------------------------
    
    GHAssertTrue([self resultset:[query resultSetForRevision:[[TXLManager sharedManager] headRevision]] 
                         isEqual:[[NSBundle mainBundle] pathForResource:@"events_on_tour" ofType:@"res"]
                           error:&error], @"Retrieved unexpected resultset from the query evaluation! (%@)", error);
}

- (void)continuousQuery:(TXLQueryHandle *)query
        hasNewResultSet:(TXLResultSet *)result
            forRevision:(TXLRevision *)revision {
    // evaluation of the query succeeded
    [self notify:kGHUnitWaitStatusSuccess];
}

/*
 * Compares a given resultset and the content of a file, that is given by <path>.
 *
 * Returns true, if for every result of the resultset there is a corresponding
 * line in the file and if every line in the file corresponds to a result of
 * the resultset.
 *
 * Otherwise returns false.
 */
- (BOOL)resultset:(TXLResultSet *)rs isEqual:(NSString *)path error:(NSError **)error {
    
    // read the content of the file
    // line by line
    // --------------------------------------------------------------
    
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:error];
    if (content == nil) {
        NSDictionary *error_dict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Could not read the content of the file: %@.", nil), path]
                                                               forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"TXLQueryTest" 
                                     code:1 
                                 userInfo:error_dict];
        return NO;
    }
    NSMutableArray *contentLineByLine = [NSMutableArray arrayWithArray:[content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
      
    // transform the content of the file
    // line by line into a form, which
    // represents the expected resultset
    // and is comparable to the given resultset
    // --------------------------------------------------------------
    
    NSMutableArray *results = [NSMutableArray array]; // the results of the resultset
    NSMutableArray *moss = [NSMutableArray array]; // the moving object sequence for every result in the resultset
    
    NSUInteger lineNo = 0;
    
    for (NSString *line in contentLineByLine) {
        
        lineNo++;
        
        NSMutableDictionary *result = [NSMutableDictionary dictionary]; // result of the line
        NSMutableArray *mos = [NSMutableArray array]; // moving object sequence of the line
        
        NSArray *lineComponents = [line componentsSeparatedByString:@";"];
        for (NSString *component in lineComponents) {
            NSArray *pair = [component componentsSeparatedByString:@"="];
            if ([pair count] == 2) {
                // found a (var,value) pair
                [result setObject:[pair objectAtIndex:1] forKey:[pair objectAtIndex:0]];
            } else {
                if ([pair count] == 1) {
                    // found a moving object definition
                    NSArray *moComponents = [[pair objectAtIndex:0] componentsSeparatedByString:@","];
                    if ([moComponents count] % 2 != 0) {
                        NSDictionary *error_dict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Failure in parsing the moving object in line %d of the expected resultset file %@.", nil), lineNo, path]
                                                                               forKey:NSLocalizedDescriptionKey];
                        *error = [NSError errorWithDomain:@"TXLQueryTest" 
                                                     code:1 
                                                 userInfo:error_dict];
                        return NO;
                    }
                    NSMutableArray *snapshots = [NSMutableArray array];
                    for (NSUInteger i = 0; i < [moComponents count]; i+=2) {
                        
                        // Parse the date.
                        // --------------------------------------------------------------
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
						[dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
						[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm'Z'"];

                        NSDate *snapshotDate = [dateFormatter dateFromString:[moComponents objectAtIndex:i]];
                        [dateFormatter release];
                        
                        TXLSnapshot *snaphot = [TXLSnapshot snapshotWithTimestamp:snapshotDate
                                                                         geometry:[TXLGeometryCollection geometryFromWKT:[moComponents objectAtIndex:i + 1]]];
                        [snapshots addObject:snaphot];
                    }
                    [mos addObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
                } else {
                    // failure
                    NSDictionary *error_dict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Failure in parsing the expected resultset file (%@) in line: %d.", nil), path, lineNo]
                                                                           forKey:NSLocalizedDescriptionKey];
                    *error = [NSError errorWithDomain:@"TXLQueryTest" 
                                                 code:1 
                                             userInfo:error_dict];
                    return NO;
                }

            }

        }
        
        [results addObject:result];
        [moss addObject:[TXLMovingObjectSequence sequenceWithArray:mos]];
    }
    
    // check the given resultset result by result
    // --------------------------------------------------------------
    
    for (NSUInteger i = 0; i < [rs count]; i++) {
        
        // check the result.
        // --------------------------------------------------------------
        
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:[rs valuesAtIndex:i]];
        
        // transform the result, so that there are string as
        // term representations instead of objects of type TXLTerm
        // --------------------------------------------------------------
        
        for (NSString* key in [result allKeys]) {
            [result setObject:[[result objectForKey:key] description] forKey:key];
        }
        TXLMovingObjectSequence *mos = [rs movingObjectSequenceAtIndex:i];
        
        // find the result in the expected resultset,
        // that is defined by the given file content
        // --------------------------------------------------------------
        
        BOOL found = NO;
        
        for (NSUInteger j = 0; j < [results count]; j++) {
            if ([result isEqual:[results objectAtIndex:j]]) {
                if ([mos isEqual:[moss objectAtIndex:j]]) {
                    
                    // if the result and the corresponding
                    // moving object sequence was found in the
                    // expected resultset, delete that
                    // result resp. moving object sequence
                    // from the expected resultset
                    // --------------------------------------------------------------
                    
                    found = YES;
                    [results removeObject:result];
                    [moss removeObject:mos];
                    break;
                }
            }
        }
        
        if (!found) {
            NSDictionary *error_dict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Found unexpected result (%@) with moving object sequence (%@) in the resultset.", nil), result, mos]
                                                                   forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:@"TXLQueryTest" 
                                         code:1 
                                     userInfo:error_dict];
            return NO;
        }
    }
    
    // check, if all lines resp. expected results, that are specified
    // in the file are contained in the resultset
    // --------------------------------------------------------------
    
    if ([results count] == 0 && [moss count] == 0) {
        return YES;
    } else {
        NSDictionary *error_dict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"The resultset does not contain the following expected results (%@) with moving object sequences (%@).", nil), results, moss]
                                                               forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"TXLQueryTest" 
                                     code:3 
                                 userInfo:error_dict];
        return NO;
    }

    
}

@end

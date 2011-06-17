//
//  TXLSpatialSituationImporterTest.m
//  OpenTXL
//
//  Created by Eleni Tsigka on 16.02.11.
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
#import "TXLSpatialSituationImporter.h"
#import "TXLManager.h"
#import "TXLMovingObject.h"
#import "TXLDatabase.h"

@interface TXLSpatialSituationImporterTest : GHAsyncTestCase {
	
}
@end


@implementation TXLSpatialSituationImporterTest


- (void)testSpatialSituationCompiler {
	
	/*
	@context <txl://opentxl.org/events/> .
	@snapshot 2011-07-22T20:00Z : POINT(20.40302705189357 30.08912723635675) .
    @snapshot 2011-02-21T12:00Z : POINT(15.40302705189357 47.08912723635675) .
	 
	@prefix ex: <http://example.org/stuff/1.0/> .
	
	<txl://opentxl.org/events/event-graz-1> ex:name "Event Graz 1";
											ex:suitability "schoenwetter";
											ex:category "architecture";
											ex:imageurl "http://opentxl.org/events/graz/images/1.jpg".	
	*/

	NSError *error;
	
	NSDictionary *result = [TXLSpatialSituationImporter compileSpatialSituationWithExpression:@" @context <txl://opentxl.org/events/> . @snapshot 2011-07-22T20:00Z : POINT(20.40302705189357 30.08912723635675) . @snapshot 2011-02-21T12:00Z : POINT(15.40302705189357 47.08912723635675) . @prefix ex: <http://example.org/stuff/1.0/> . <txl://opentxl.org/events/event-graz-1> ex:name \"Event Graz 1\"; ex:suitability \"schoenwetter\"; ex:category \"architecture\"; ex:imageurl \"http://opentxl.org/events/graz/images/1.jpg\". "
																			parameters:nil
																			   options:nil
																				 error:&error]; 
	// Check that the query was saved, by checking its id.
	GHAssertNotNil(result, @"Result should not be nil.");
	
}


- (void)testSpatialSituationImporterWithTestData {
	
	NSError *error;
	
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
    NSDate *beginDate = [dateFormatter dateFromString:@"2011-01-01 01:00:00 +0200"];
	NSDate *endDate = [dateFormatter dateFromString:@"2011-01-05 01:00:00 +0200"];
	[dateFormatter release];
    
	NSArray *pathList = [[NSBundle mainBundle] pathsForResourcesOfType:@"n3" inDirectory:nil];
	
	for (NSString *path in pathList) {
        [self prepare];
		BOOL result = [[TXLManager sharedManager] importSpatialSituationFromFileAtPath:path 
																			 inIntervalFrom:beginDate
																						 to:endDate
																					  error:&error
																			completionBlock:^(TXLRevision *rev, NSError *error){
																				// Notify the successful end of the operation.
																				[self notify:kGHUnitWaitStatusSuccess];
																			}];
        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:120.0];
		// Check that the query was saved, by checking its id.
		GHAssertTrue(result, @"Result should be YES.");
	}
}

- (void)testSpatialSituationCompilerWithOmniPresentSnapshot {
	
	/*
	 @context <txl://opentxl.org/events/> .
	 @prefix ex: <http://example.org/stuff/1.0/> .
	 
	 <txl://opentxl.org/events/event-graz-8> 
	 ex:category 1; 
	 ex:name 1.
	 */
	
	NSError *error;
	
	NSDictionary *result = [TXLSpatialSituationImporter compileSpatialSituationWithExpression:@" @context <txl://opentxl.org/events/> . @prefix ex: <http://example.org/stuff/1.0/> . <txl://opentxl.org/events/event-graz-8> ex:category 1; ex:name 1. "
																				   parameters:nil
																					  options:nil
																						error:&error]; 
	// Check that the query was saved, by checking its id.
	GHAssertNotNil(result, @"Result should not be nil.");
	
	TXLMovingObject *mo = [result objectForKey:@"moving_object"];
	// Check that the moving object is omnipresent.
	GHAssertTrue([mo isOmnipresent], @"Result should be omnipresent.");	
}

- (void)testSpatialSituationCompilerWithEverywhereSnapshots {
	
	/*
	 @context <txl://opentxl.org/events/> .
	 
	 @snapshot 2011-07-22T20:00Z .
	 @snapshot 2011-02-21T12:00Z .
	 
	 @prefix ex: <http://example.org/stuff/1.0/> .
	 
	 <txl://opentxl.org/events/event-graz-8> 
	 ex:category 1; 
	 ex:name 1.
	 */
	
	NSError *error;
	
	NSDictionary *result = [TXLSpatialSituationImporter compileSpatialSituationWithExpression:@" @context <txl://opentxl.org/events/> . @snapshot 2011-07-22T20:00Z . @snapshot 2011-02-21T12:00Z . @prefix ex: <http://example.org/stuff/1.0/> . <txl://opentxl.org/events/event-graz-8> ex:category 1; ex:name 1. "
																				   parameters:nil
																					  options:nil
																						error:&error]; 
	// Check that the query was saved, by checking its id.
	GHAssertNotNil(result, @"Result should not be nil.");
	
	TXLMovingObject *mo = [result objectForKey:@"moving_object"];
	// Check that the moving object is evereywhere valid.
	GHAssertTrue([mo isEverywhere], @"Result should be everywhere valid.");		
}

- (void)testSpatialSituationCompilerWithAlwaysSnapshot {
	
	/*
	 @context <txl://opentxl.org/events/> .
	
	 @snapshot : POINT(20.40302705189357 30.08912723635675) .
	 
	 @prefix ex: <http://example.org/stuff/1.0/> .
	 
	 <txl://opentxl.org/events/event-graz-8> 
	 ex:category 1; 
	 ex:name 1.
	 */
	
	NSError *error;
	
	NSDictionary *result = [TXLSpatialSituationImporter compileSpatialSituationWithExpression:@" @context <txl://opentxl.org/events/> . @snapshot : POINT(20.40302705189357 30.08912723635675) . @prefix ex: <http://example.org/stuff/1.0/> . <txl://opentxl.org/events/event-graz-8> ex:category 1; ex:name 1. "
																				   parameters:nil
																					  options:nil
																						error:&error]; 
	// Check that the query was saved, by checking its id.
	GHAssertNotNil(result, @"Result should not be nil.");
	
	TXLMovingObject *mo = [result objectForKey:@"moving_object"];
	// Check that the moving object is always valid.
	GHAssertTrue([mo isAlways], @"Result should be always valid.");		
}

@end

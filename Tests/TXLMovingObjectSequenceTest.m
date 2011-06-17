//
//  TXLMovingObjectSequenceTest.m
//  OpenTXL
//
//  Created by Peter Fenske on 16.11.10.
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

#import "TXLMovingObject.h"
#import "TXLMovingObjectSequence.h"
#import "TXLPoint.h"
#import "TXLGeometryCollection.h"
#import "TXLSnapshot.h"

#import "TXLDatabase.h"
#import "TXLManager.h"

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import "NSDate+dateWithString.h"
#endif

#import "TXLMovingObjectTestData.h"

#define DATE(x) [NSDate dateWithString:x]
#define GEO(x) [TXLGeometryCollection geometryFromWKT:x]

#define SQL(x) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

@interface TXLMovingObjectSequenceTest : GHTestCase {
    
}

@end


@implementation TXLMovingObjectSequenceTest

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

#pragma mark -
#pragma mark Test Constructor, Save & Load and basic Accessor Methods

- (void)testEmptySequence {
    
    // Test the constructor and the "basic accessor methods"
    // for an empty moving object sequence.
    // ====================================================
    
    TXLMovingObjectSequence *seq = [TXLMovingObjectSequence emptySequence];
    GHAssertNotNil(seq, @"Could not create an empty sequence.");
    
    // Predicates
    // ----------------------
    
    GHAssertTrue(seq.empty, nil);
    
    // Interval
    // ----------------------
    
    // Begin and end of an empty moving object are not defined.
    
    // Bounds
    // ----------------------
    
    GHAssertNil(seq.bounds, @"An empty moving object sequence has no bounds.");
    
    // Moving Objects
    // ----------------------
    
    GHAssertEquals([seq.movingObjects count], (NSUInteger)0, nil);
    
    // Save
    // ----------------------
    
    // An empty moving object sequence can not be stored in the database.
    NSError *error;
    GHAssertNil([seq save:&error], @"Expecting nil.");
}

- (void)testSequenceWithObject {
    
    // Test the constructor and the "basic accessor methods"
    // for an moving object sequence with one moving object.
    // ====================================================
    
    TXLMovingObjectSequence *seq = [TXLMovingObjectSequence sequenceWithMovingObject:[TXLMovingObjectTestData a1]];
    GHAssertNotNil(seq, @"Could not create a moving object sequence with one moving object.");
    
    // Save & Load
    // ----------------------
    
    NSError *error;
    GHAssertNotNil([seq save:&error], [error localizedDescription]);
    
    NSUInteger pk = seq.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, @"The primary key of an saved moving object sequence must not be 0.");
    
    seq = [TXLMovingObjectSequence sequenceWithPrimaryKey:pk];
    
    // Predicates
    // ----------------------
    
    GHAssertFalse(seq.empty, nil);
    
    // Interval
    // ----------------------
    
    GHAssertEqualObjects(seq.begin, [[TXLMovingObjectTestData a1] begin], nil);
    GHAssertEqualObjects(seq.end, [[TXLMovingObjectTestData a1] end], nil);
    
    // Bounds
    // ----------------------
    
    GHAssertEqualObjects(seq.bounds, [[TXLMovingObjectTestData a1] bounds], nil);
    
    // Moving Objects
    // ----------------------
    
    GHAssertEquals([seq.movingObjects count], (NSUInteger)1, nil);
    
    GHAssertEqualObjects([seq.movingObjects objectAtIndex:0], [TXLMovingObjectTestData a1], nil);
}

- (void)testSequenceWithUnifyingObjects {
    
    // Test the constructor and the "basic accessor methods"
    // for an moving object sequence constructed with an array
    // of moving objects. The sequence will contain the union
    // of the moving objects.
    // ====================================================
    
    NSArray *array = [NSArray arrayWithObjects:
                      [TXLMovingObjectTestData a1],
                      [TXLMovingObjectTestData b1],
                      [TXLMovingObjectTestData a1],
                      nil];
    
    TXLMovingObjectSequence *seq = [TXLMovingObjectSequence sequenceByUnifyingMovingObjects:array];
    GHAssertNotNil(seq, @"Could not create a unified sequence of an array of moving objects.");
    
    // Save & Load
    // ----------------------
    
    NSError *error;
    GHAssertNotNil([seq save:&error], [error localizedDescription]);
    
    NSUInteger pk = seq.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, @"The primary key of an saved moving object sequence must not be 0.");
    
    seq = [TXLMovingObjectSequence sequenceWithPrimaryKey:pk];
    
    // Predicates
    // ----------------------
    
    GHAssertFalse(seq.empty, nil);
    
    // Interval
    // ----------------------
    
    GHAssertEqualObjects(seq.begin, [[TXLMovingObjectTestData union_a1_b1] begin], nil);
    GHAssertEqualObjects(seq.end, [[TXLMovingObjectTestData union_a1_b1] end], nil);
    
    // Bounds
    // ----------------------
    
    GHAssertEqualObjects(seq.bounds, [[TXLMovingObjectTestData union_a1_b1] bounds], nil);
    
    // Moving Objects
    // ----------------------
    
    GHAssertEquals([seq.movingObjects count], (NSUInteger)1, nil);
    
    GHAssertEqualObjects([seq.movingObjects objectAtIndex:0], [[[TXLMovingObjectTestData union_a1_b1] movingObjects] objectAtIndex:0], nil);
}

#pragma mark -
#pragma mark Test Union Operations

- (void)testUnion {
    TXLMovingObjectSequence *seq1 = [TXLMovingObjectTestData A];
    TXLMovingObjectSequence *seq2 = [TXLMovingObjectTestData B];
    TXLMovingObjectSequence *result = [seq1 unionWithMovingObjectSequence:seq2];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData union_A_B], nil);
}

#pragma mark -
#pragma mark Test Intersection Operations

- (void)testIntersection {
    TXLMovingObjectSequence *seq1 = [TXLMovingObjectTestData A];
    TXLMovingObjectSequence *seq2 = [TXLMovingObjectTestData B];
    TXLMovingObjectSequence *result = [seq1 intersectionWithMovingObjectSequence:seq2];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData intersection_A_B], nil);
}

#pragma mark -
#pragma mark Test Compelment Operation

- (void)testComplement {
    TXLMovingObjectSequence *seq1 = [TXLMovingObjectTestData A];
    TXLMovingObjectSequence *seq2 = [TXLMovingObjectTestData B];
    TXLMovingObjectSequence *result = [seq1 complementWithMovingObjectSequnece:seq2];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData complement_A_B], nil);
}

@end

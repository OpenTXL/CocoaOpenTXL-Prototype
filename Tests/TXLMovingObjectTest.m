//
//  TXLMovingObjectTest.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 28.09.10.
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
#import "TXLPoint.h"
#import "TXLGeometryCollection.h"
#import "TXLSnapshot.h"

#import "TXLManager.h"
#import "TXLDatabase.h"

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import "NSDate+dateWithString.h"
#endif

#import "TXLMovingObjectTestData.h"

#define DATE(x) [NSDate dateWithString:x]
#define GEO(x) [TXLGeometryCollection geometryFromWKT:x]

#define SQL(x) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

@interface TXLMovingObjectTest : GHTestCase {
    
}

@end

@implementation TXLMovingObjectTest

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

- (void)testEmptyMovingObject {
    
    // Test the constructor and the "basic accessor methods"
    // for an empty moving object.
    // ====================================================
    
    TXLMovingObject *mo = [TXLMovingObject emptyMovingObject];
    GHAssertNotNil(mo, @"Could not create an empty moving object.");
    
    // Predicates
    // ----------------------
    
    GHAssertTrue(mo.empty, @"An empty moving object is emty.");
    GHAssertFalse(mo.omnipresent, @"An empty moving object is not omnipresent.");
    GHAssertFalse(mo.always, @"An empty moving object is not 'always'.");
    GHAssertFalse(mo.everywhere, @"An empty moving object in not everywhere.");
    
    // Interval
    // ----------------------
    
    // Begin and end of an empty moving object are not defined.
    
    // Bounds
    // ----------------------
    
    GHAssertNil(mo.bounds, @"An empty moving object has no bounds.");
    
    // Snapshots
    // ----------------------
    
    // An emty moving object does not contain any snaphots.
    
    GHAssertEquals([mo.snapshots count], (NSUInteger)0, nil);
    
    // Save
    // ----------------------
    
    // An empty moving object can not be stored in the database.
    NSError *error;
    GHAssertNil([mo save:&error], @"Expecting nil.");
}

- (void)testOmnipresentMovingObject {
    
    // Test the constructor and the "basic accessor methods"
    // for an omnipresent moving object.
    // ====================================================
    
    TXLMovingObject *mo = [TXLMovingObject omnipresentMovingObject];
    GHAssertNotNil(mo, @"Could not create an omnipresent moving object.");
    
    // Save & Load
    // ----------------------
    
    NSError *error;
    GHAssertNotNil([mo save:&error], [error localizedDescription]);
    
    NSUInteger pk = mo.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, @"The primary key of an saved moving object must not be 0.");
    
    mo = [TXLMovingObject movingObjectWithPrimaryKey:pk];    
    
    // Predicates
    // ----------------------
    
    GHAssertFalse(mo.empty, @"An omnipresent moving object is not empty.");
    GHAssertTrue(mo.omnipresent, @"An omnipresent moving object is omnipresent.");
    GHAssertTrue(mo.always, @"An omnipresent moving object is 'always'.");
    GHAssertTrue(mo.everywhere, @"An omnipresent moving object in everywhere.");
    
    // Interval
    // ----------------------
    
    // Begin and end of an omnipresent moving object are both nil. A nil value
    // indicates an open interval (left and right). The moving object is always
    // valid.
    
    GHAssertNil(mo.begin, nil);
    GHAssertNil(mo.end, nil);
    
    // Bounds
    // ----------------------
    
    // The bounds of an omnipresent movign object cover the whole world. While an
    // omnipresent moving object is alwys valid, the bounds at a time and in an
    // interval also cover the whole world.
    
    GHAssertEqualObjects(mo.bounds, GEO(@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"), nil);
    GHAssertEqualObjects([mo boundsInIntervalFrom:DATE(@"2010-09-29 19:00:00 +0200") to:DATE(@"2010-09-29 21:00:00 +0200")],
                         GEO(@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"), nil);
    
    // Snapshots
    // ----------------------
    
    // An omnipresent moving object contains two special snapshot with a
    // timestamp of nil and a geometry covering the whole world.
    
    GHAssertEquals([mo.snapshots count], (NSUInteger)2, nil);
    
    GHAssertNil([(TXLSnapshot *)[mo.snapshots objectAtIndex:0] timestamp], nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:0] geometry], GEO(@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"), nil);
    
    GHAssertNil([(TXLSnapshot *)[mo.snapshots objectAtIndex:1] timestamp], nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:1] geometry], GEO(@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"), nil);
}

- (void)testMovingObjectWithBeginEnd {
    
    // Test the constructor and the "basic accessor methods"
    // for an moving object which is in a certain interval
    // everywhere valid.
    // ====================================================
    
    TXLMovingObject *mo = [TXLMovingObject movingObjectWithBegin:DATE(@"2010-09-29 10:00:00 +0200")
                                                             end:DATE(@"2010-09-29 20:00:00 +0200")];
    GHAssertNotNil(mo, @"Could not create a moving object in interval begin, end.");
    
    // Save & Load
    // ----------------------
    
    NSError *error;
    GHAssertNotNil([mo save:&error], [error localizedDescription]);
    
    NSUInteger pk = mo.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, @"The primary key of an saved moving object must not be 0.");
    
    mo = [TXLMovingObject movingObjectWithPrimaryKey:pk];    
    
    // Predicates
    // ----------------------
    
    GHAssertFalse(mo.empty, @"A moving object with a temporal interval only is not empty.");
    GHAssertFalse(mo.omnipresent, @"A moving object with a temporal interval only is not omnipresent.");
    GHAssertFalse(mo.always, @"A moving object with a temporal interval only is not 'always'.");
    GHAssertTrue(mo.everywhere, @"A moving object with a temporal interval only is everywhere.");
    
    // Interval
    // ----------------------
    
    // Begin and end must have the same values as used in the constructor.
    
    GHAssertEqualObjects(mo.begin, DATE(@"2010-09-29 10:00:00 +0200"), nil);
    GHAssertEqualObjects(mo.end, DATE(@"2010-09-29 20:00:00 +0200"), nil);
    
    // Bounds
    // ----------------------
    
    // The bounds of an moving object which is in a certain time interval
    // everywhere valid must cover the whole world. Because the right boundary
    // of the temporal interval does not contain to the valid region of the
    // moving object, the bounds at this time must be nil.
    
    GHAssertEqualObjects(mo.bounds, GEO(@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"), nil);
    
    
    GHAssertNil([mo boundsAtDate:DATE(@"2010-09-29 09:00:00 +0200")], @"Bound before the temporal interval must bi nil.");
    
    GHAssertEqualObjects([mo boundsAtDate:DATE(@"2010-09-29 15:00:00 +0200")], GEO(@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"),
                         @"The bounds in the temporal onterval must cover the whole world.");
    
    GHAssertNil([mo boundsAtDate:DATE(@"2010-09-29 20:00:00 +0200")],
                @"The bounds at the same time as the temporal interval ends must be nil.");    
    
    GHAssertNil([mo boundsAtDate:DATE(@"2010-09-29 21:00:00 +0200")],
                @"The bounds of the object after end must be nil.");
    
    GHAssertNil([mo boundsInIntervalFrom:DATE(@"2010-09-29 00:00:00 +0200")
                                      to:DATE(@"2010-09-29 00:00:00 +0200")],
                @"The bounds in an interval ending befor the begin of the moving object must be nil.");
    
    GHAssertNil([mo boundsInIntervalFrom:DATE(@"2010-09-29 20:00:00 +0200")
                                      to:DATE(@"2010-09-29 21:00:00 +0200")],
                @"The bounds in an interval begining at the end of the moving object must be nil.");
    
    GHAssertEqualObjects([mo boundsInIntervalFrom:DATE(@"2010-09-29 19:00:00 +0200")
                                               to:DATE(@"2010-09-29 21:00:00 +0200")],
                         GEO(@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"),
                         @"The bounds in an interval intersecting the temporal interval of the moving object must cover the whole world.");
    
    // Snapshots
    // ----------------------
    
    // A moving object constructed with an temporal interval only (everywhere)
    // must contain two snaphots with begin and end as a timestamp an a
    // geometry covering the whole world.
    
    GHAssertEquals([mo.snapshots count], (NSUInteger)2, nil);
    
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:0] timestamp], DATE(@"2010-09-29 10:00:00 +0200"), nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:0] geometry], GEO(@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"), nil);
    
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:1] timestamp], DATE(@"2010-09-29 20:00:00 +0200"), nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:1] geometry], GEO(@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"), nil);
}

- (void)testMovingObjectWithGeometry {
    
    // Test the constructor and the "basic accessor methods"
    // for an moving object which is always in constant
    // bounds valid.
    // ====================================================
    
    TXLMovingObject *mo = [TXLMovingObject movingObjectWithGeometry:GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))")];
    GHAssertNotNil(mo, @"Could not create a moving object from a geometry.");
    
    // Save & Load
    // ----------------------
    
    NSError *error;
    GHAssertNotNil([mo save:&error], [error localizedDescription]);
    
    NSUInteger pk = mo.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, @"The primary key of an saved moving object must not be 0.");
    
    mo = [TXLMovingObject movingObjectWithPrimaryKey:pk];    
    
    // Predicates
    // ----------------------
    
    GHAssertFalse(mo.empty, @"A moving object with a geometry is not empty.");
    GHAssertFalse(mo.omnipresent, @"A moving object with a geometry (with bounds) is not omnipresent.");
    GHAssertTrue(mo.always, @"A moving object constructed from a geometry is 'always'.");
    GHAssertFalse(mo.everywhere, @"A moving object constructed from a geometry is not everywhere.");
    
    // Interval
    // ----------------------
    
    // Begin and end must be nil to indicate an left and right open interval.
    
    GHAssertNil(mo.begin, @"Temporal interval has no begin.");
    GHAssertNil(mo.end, @"Temporal interval has no end.");
    
    // Bounds
    // ----------------------
    
    // The bounds of the moving object must always be equal to the geometry the
    // moving object is constructed with.
    
    GHAssertEqualObjects(mo.bounds, GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    
    GHAssertEqualObjects([mo boundsAtDate:DATE(@"2010-09-29 15:00:00 +0200")], GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    
    GHAssertEqualObjects([mo boundsInIntervalFrom:DATE(@"2010-09-29 19:00:00 +0200") to:DATE(@"2010-09-29 21:00:00 +0200")],
                         GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    
    // Snapshots
    // ----------------------
    
    // An moving object which is in constant bounds valid valid must
    // contains two snapshot with that geometry and a timestamp of nil.
    
    GHAssertEquals([mo.snapshots count], (NSUInteger)2, nil);
    
    GHAssertNil([(TXLSnapshot *)[mo.snapshots objectAtIndex:0] timestamp], nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:0] geometry], GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    
    GHAssertNil([(TXLSnapshot *)[mo.snapshots objectAtIndex:1] timestamp], nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:1] geometry], GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
}

- (void)testMovingObjectWithGeometryBeginEnd {
    
    // Test the constructor and the "basic accessor methods"
    // for an moving object which is has constant
    // bounds valid in an temporal interval.
    // ====================================================
    
    TXLMovingObject *mo = [TXLMovingObject movingObjectWithGeometry:GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))")
                                                              begin:DATE(@"2010-09-29 10:00:00 +0200")
                                                                end:DATE(@"2010-09-29 20:00:00 +0200")];
    GHAssertNotNil(mo, @"Could not create a moving object from a geometry in interval begin, end.");
    
    // Save & Load
    // ----------------------
    
    NSError *error;
    GHAssertNotNil([mo save:&error], [error localizedDescription]);
    
    NSUInteger pk = mo.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, @"The primary key of an saved moving object must not be 0.");
    
    mo = [TXLMovingObject movingObjectWithPrimaryKey:pk];

    // Predicates
    // ----------------------
    
    GHAssertFalse(mo.empty, @"A moving object with a geometry is not empty.");
    GHAssertFalse(mo.omnipresent, @"A moving object with a geometry (with bounds) is not omnipresent.");
    GHAssertFalse(mo.always, @"A moving object constructed from a geometry with begin and end is not 'always'.");
    GHAssertFalse(mo.everywhere, @"A moving object constructed from a geometry is not everywhere.");
    
    // Interval
    // ----------------------
    
    // Begin and end must have the same values as used in the constructor.
    
    GHAssertEqualObjects(mo.begin, DATE(@"2010-09-29 10:00:00 +0200"), @"Begin is not the same value as used in the constructor.");
    GHAssertEqualObjects(mo.end, DATE(@"2010-09-29 20:00:00 +0200"), @"End is not the same value as used in the constructor.");
    
    // Bounds
    // ----------------------
    
    // The bounds of the moving object in the temporal interval (begin, end)
    // must be equal to the geometry the moving object is constructed with.
    
    // Because the right boundary of the temporal interval does not contain
    // to the valid region of the moving object, the bounds at this time
    // must be nil.
    
    GHAssertEqualObjects(mo.bounds, GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    
    GHAssertEqualObjects([mo boundsAtDate:DATE(@"2010-09-29 15:00:00 +0200")], GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    
    GHAssertNil([mo boundsAtDate:DATE(@"2010-09-29 20:00:00 +0200")], nil); 
    GHAssertNil([mo boundsAtDate:DATE(@"2010-09-29 21:00:00 +0200")], nil);
    
    GHAssertNil([mo boundsInIntervalFrom:DATE(@"2010-09-29 00:00:00 +0200") to:DATE(@"2010-09-29 00:00:00 +0200")], nil);
    GHAssertNil([mo boundsInIntervalFrom:DATE(@"2010-09-29 20:10:00 +0200") to:DATE(@"2010-09-29 21:00:00 +0200")], nil);
    
    GHAssertEqualObjects([mo boundsInIntervalFrom:DATE(@"2010-09-29 19:00:00 +0200") to:DATE(@"2010-09-29 21:00:00 +0200")],
                         GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    
    GHAssertEqualObjects([mo boundsInIntervalFrom:DATE(@"2010-09-29 01:00:00 +0200") to:DATE(@"2010-09-29 21:00:00 +0200")],
                         GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    
    // Snapshots
    // ----------------------
    
    // This moving object must contain exactly two snapshots with begin
    // and end as timestamps and the geomtry the object is constructed with.
    
    GHAssertEquals([mo.snapshots count], (NSUInteger)2, nil);
    
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:0] timestamp], DATE(@"2010-09-29 10:00:00 +0200"), nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:0] geometry], GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:1] timestamp], DATE(@"2010-09-29 20:00:00 +0200"), nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:1] geometry], GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
}

- (void)testMovingObjectWithSnapshots {
    
    // Test the constructor and the "basic accessor methods"
    // for an moving object constructed with snapshots.
    // ====================================================
    
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2010-09-29 10:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((0 0, 10 0,10 10, 0 10, 0 0))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2010-09-29 11:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2010-09-29 12:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2010-09-29 13:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((15 15, 25 15, 25 25, 15 25, 15 15))")]];

    TXLMovingObject *mo = [TXLMovingObject movingObjectWithSnapshots:snapshots];
    GHAssertNotNil(mo, @"Could not create a moving object from an array with snapshots.");
    
    // Save & Load
    // ----------------------
    
    NSError *error;
    GHAssertNotNil([mo save:&error], [error localizedDescription]);
    
    NSUInteger pk = mo.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, @"The primary key of an saved moving object must not be 0.");
    
    mo = [TXLMovingObject movingObjectWithPrimaryKey:pk];    
    
    // Predicates
    // ----------------------
    
    GHAssertFalse(mo.empty, @"A moving object with an array of snapshots is not empty.");
    GHAssertFalse(mo.omnipresent, @"A moving object with an array of snapshots is not omnipresent.");
    GHAssertFalse(mo.always, @"A moving object constructed from an array of snapshots is not 'always'.");
    GHAssertFalse(mo.everywhere, @"A moving object constructed from an array of snapshots is not everywhere.");
    
    // Interval
    // ----------------------
    
    // Begin and end must be the timestamps from the first and last
    // snapshot this object is constructed with.
    
    GHAssertEqualObjects(mo.begin, DATE(@"2010-09-29 10:00:00 +0200"), nil);
    GHAssertEqualObjects(mo.end, DATE(@"2010-09-29 13:00:00 +0200"), nil);
    
    // Bounds
    // ----------------------
    
    // The bounds of an moving object are depending on the algorithem
    // which is used for the interpolation between two moving object.
    
    // This implementation uses a constant interpolation. Therefore
    // the bounds at a time are the same as  geometry of the nearest
    // snapshot with a timestamp before (or at) this time.
    
    // The bounds of an object constructed with snapshots must be the
    // union of all geometry of the snapshots except the last one (if
    // it is not nil).
    
    // Because the right boundary of the temporal interval does not contain
    // to the valid region of the moving object, the bounds at this time
    // must be nil (if end is not nil).
    
    GHAssertEqualObjects(mo.bounds, GEO(@"POLYGON((0 0, 10 0, 10 5, 15 5, 15 10, 20 10, 20 20, 10 20, 10 15, 5 15, 5 10, 0 10, 0 0))"), nil);
    
    GHAssertEqualObjects([mo boundsAtDate:DATE(@"2010-09-29 10:10:00 +0200")], GEO(@"POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))"), nil);
    GHAssertEqualObjects([mo boundsAtDate:DATE(@"2010-09-29 11:10:00 +0200")], GEO(@"POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))"), nil);
    GHAssertEqualObjects([mo boundsAtDate:DATE(@"2010-09-29 12:10:00 +0200")], GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    GHAssertNil([mo boundsAtDate:DATE(@"2010-09-29 13:00:00 +0200")], nil);
    GHAssertNil([mo boundsAtDate:DATE(@"2010-09-29 21:00:00 +0200")], nil);
    
    
    GHAssertNil([mo boundsInIntervalFrom:DATE(@"2010-09-29 00:00:00 +0200") to:DATE(@"2010-09-29 01:00:00 +0200")], nil);
    GHAssertNil([mo boundsInIntervalFrom:DATE(@"2010-09-29 13:10:00 +0200") to:DATE(@"2010-09-29 21:00:00 +0200")], nil);
    
    GHAssertEqualObjects([mo boundsInIntervalFrom:DATE(@"2010-09-29 11:30:00 +0200") to:DATE(@"2010-09-29 12:30:00 +0200")],
                         GEO(@"POLYGON((5 5, 15 5, 15 10, 20 10, 20 20, 10 20, 10 15, 5 15, 5 5))"), nil);
    
    // Snapshots
    // ----------------------
    
    // This moving object must contain exactly the same list
    // of snapshots it is constructed with.
    
    GHAssertEquals([mo.snapshots count], (NSUInteger)4, nil);
    
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:0] timestamp], DATE(@"2010-09-29 10:00:00 +0200"), nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:0] geometry], GEO(@"POLYGON((0 0, 10 0,10 10, 0 10, 0 0))"), nil);
                         
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:1] timestamp], DATE(@"2010-09-29 11:00:00 +0200"), nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:1] geometry], GEO(@"POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))"), nil);
                         
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:2] timestamp], DATE(@"2010-09-29 12:00:00 +0200"), nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:2] geometry], GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:3] timestamp], DATE(@"2010-09-29 13:00:00 +0200"), nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:3] geometry], GEO(@"POLYGON((15 15, 25 15, 25 25, 15 25, 15 15))"), nil);
}

- (void)testMovingObjectWithSnapshotsBeginEndNil {
    
    // Test the constructor and the "basic accessor methods"
    // for an moving object constructed with snapshots (with
    // begin and end nil).
    // ====================================================
    
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((0 0, 10 0,10 10, 0 10, 0 0))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2010-09-29 10:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((0 0, 10 0,10 10, 0 10, 0 0))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2010-09-29 11:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2010-09-29 12:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2010-09-29 13:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((15 15, 25 15, 25 25, 15 25, 15 15))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((15 15, 25 15, 25 25, 15 25, 15 15))")]];
    
    TXLMovingObject *mo = [TXLMovingObject movingObjectWithSnapshots:snapshots];
    GHAssertNotNil(mo, @"Could not create a moving object from an array with snapshots.");
    
    // Save & Load
    // ----------------------
    
    NSError *error;
    GHAssertNotNil([mo save:&error], [error localizedDescription]);
    
    NSUInteger pk = mo.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, @"The primary key of an saved moving object must not be 0.");
    
    mo = [TXLMovingObject movingObjectWithPrimaryKey:pk];
    
    // Predicates
    // ----------------------
    
    GHAssertFalse(mo.empty, @"A moving object with an array of snapshots is not empty.");
    GHAssertFalse(mo.omnipresent, @"A moving object with an array of snapshots is not omnipresent.");
    GHAssertTrue(mo.always, @"A moving object with the timstamp nil in the first and last snapshot 'always'.");
    GHAssertFalse(mo.everywhere, @"A moving object constructed from an array of snapshots is not everywhere.");
    
    // Interval
    // ----------------------
    
    // Begin and end must be the timestamps from the first and last
    // snapshot this object is constructed with.
    
    GHAssertNil(mo.begin, nil);
    GHAssertNil(mo.end, nil);
    
    // Bounds
    // ----------------------
    
    // The bounds of an moving object are depending on the algorithem
    // which is used for the interpolation between two moving object.
    
    // This implementation uses a constant interpolation. Therefore
    // the bounds at a time are the same as  geometry of the nearest
    // snapshot with a timestamp before (or at) this time.
    
    // The bounds of an object constructed with snapshots must be the
    // union of all geometry of the snapshots except the last one (if
    // it is not nil).
    
    // Because the right boundary of the temporal interval does not contain
    // to the valid region of the moving object, the bounds at this time
    // must be nil (if end is not nil).
    
    GHAssertEqualObjects(mo.bounds, GEO(@"POLYGON((0 0, 10 0, 10 5, 15 5, 15 10, 20 10, 20 15, 25 15, 25 25, 15 25, 15 20, 10 20, 10 15, 5 15, 5 10, 0 10, 0 0))"), nil);
    
    GHAssertEqualObjects([mo boundsAtDate:DATE(@"1900-01-01 00:00:00 +0200")], GEO(@"POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))"), nil);
    GHAssertEqualObjects([mo boundsAtDate:DATE(@"2010-09-29 10:10:00 +0200")], GEO(@"POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))"), nil);
    GHAssertEqualObjects([mo boundsAtDate:DATE(@"2010-09-29 11:10:00 +0200")], GEO(@"POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))"), nil);
    GHAssertEqualObjects([mo boundsAtDate:DATE(@"2010-09-29 12:10:00 +0200")], GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    GHAssertEqualObjects([mo boundsAtDate:DATE(@"2010-09-29 13:00:00 +0200")], GEO(@"POLYGON((15 15, 25 15, 25 25, 15 25, 15 15))"), nil);
    GHAssertEqualObjects([mo boundsAtDate:DATE(@"4000-01-01 00:00:00 +0200")], GEO(@"POLYGON((15 15, 25 15, 25 25, 15 25, 15 15))"), nil);
    
    
    GHAssertEqualObjects([mo boundsInIntervalFrom:DATE(@"2010-09-29 00:00:00 +0200") to:DATE(@"2010-09-29 01:00:00 +0200")],
                         GEO(@"POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))"), nil);
    
    GHAssertEqualObjects([mo boundsInIntervalFrom:DATE(@"2010-09-29 19:10:00 +0200") to:DATE(@"2010-09-29 21:00:00 +0200")],
                         GEO(@"POLYGON((15 15, 25 15, 25 25, 15 25, 15 15))"), nil);
    
    GHAssertEqualObjects([mo boundsInIntervalFrom:DATE(@"2010-09-29 11:30:00 +0200") to:DATE(@"2010-09-29 12:30:00 +0200")],
                         GEO(@"POLYGON((5 5, 15 5, 15 10, 20 10, 20 20, 10 20, 10 15, 5 15, 5 5))"), nil);
    
    // Snapshots
    // ----------------------
    
    // This moving object must contain exactly the same list
    // of snapshots it is constructed with.
    
    GHAssertEquals([mo.snapshots count], (NSUInteger)6, nil);
    
    GHAssertNil([(TXLSnapshot *)[mo.snapshots objectAtIndex:0] timestamp], nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:0] geometry], GEO(@"POLYGON((0 0, 10 0,10 10, 0 10, 0 0))"), nil);
    
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:1] timestamp], DATE(@"2010-09-29 10:00:00 +0200"), nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:1] geometry], GEO(@"POLYGON((0 0, 10 0,10 10, 0 10, 0 0))"), nil);
    
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:2] timestamp], DATE(@"2010-09-29 11:00:00 +0200"), nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:2] geometry], GEO(@"POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))"), nil);
    
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:3] timestamp], DATE(@"2010-09-29 12:00:00 +0200"), nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:3] geometry], GEO(@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"), nil);
    
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:4] timestamp], DATE(@"2010-09-29 13:00:00 +0200"), nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:4] geometry], GEO(@"POLYGON((15 15, 25 15, 25 25, 15 25, 15 15))"), nil);
    
    GHAssertNil([(TXLSnapshot *)[mo.snapshots objectAtIndex:5] timestamp], nil);
    GHAssertEqualObjects([(TXLSnapshot *)[mo.snapshots objectAtIndex:5] geometry], GEO(@"POLYGON((15 15, 25 15, 25 25, 15 25, 15 15))"), nil);
}

#pragma mark -
#pragma mark Test Equality

- (void)testEqual {
    GHAssertEqualObjects([TXLMovingObjectTestData a1], [TXLMovingObjectTestData a1], nil);
}

- (void)testNotEqual {
    GHAssertNotEqualObjects([TXLMovingObjectTestData a1], [TXLMovingObjectTestData b1], nil);
}

#pragma mark -
#pragma mark Test Union

- (void)testUnion_a1_b1 {
    TXLMovingObject *mo1 = [TXLMovingObjectTestData a1];
    TXLMovingObject *mo2 = [TXLMovingObjectTestData b1];
    TXLMovingObjectSequence *result = [mo1 unionWithMovingObject:mo2];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData union_a1_b1], nil);
}

- (void)testUnion_b1_a1 {
    TXLMovingObject *mo1 = [TXLMovingObjectTestData a1];
    TXLMovingObject *mo2 = [TXLMovingObjectTestData b1];
    TXLMovingObjectSequence *result = [mo2 unionWithMovingObject:mo1];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData union_a1_b1], nil);
}

- (void)testUnion_a1_e1 {
    TXLMovingObject *mo1 = [TXLMovingObjectTestData a1];
    TXLMovingObject *mo2 = [TXLMovingObjectTestData e1];
    TXLMovingObjectSequence *result = [mo1 unionWithMovingObject:mo2];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData union_a1_e1], nil);
}

#pragma mark -
#pragma mark Test Intersection

- (void)testIntersection_a1_b1 {
    TXLMovingObject *mo1 = [TXLMovingObjectTestData a1];
    TXLMovingObject *mo2 = [TXLMovingObjectTestData b1];
    TXLMovingObjectSequence *result = [mo1 intersectionWithMovingObject:mo2];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData intersection_a1_b1], nil);
}

- (void)testIntersection_b1_a1 {
    TXLMovingObject *mo1 = [TXLMovingObjectTestData a1];
    TXLMovingObject *mo2 = [TXLMovingObjectTestData b1];
    TXLMovingObjectSequence *result = [mo2 intersectionWithMovingObject:mo1];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData intersection_a1_b1], nil);
}

- (void)testIntersection_c1_d1 {
    TXLMovingObject *mo1 = [TXLMovingObjectTestData c1];
    TXLMovingObject *mo2 = [TXLMovingObjectTestData d1];
    TXLMovingObjectSequence *result = [mo1 intersectionWithMovingObject:mo2];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData intersection_c1_d1], nil);
}

- (void)testIntersection_d1_c1 {
    TXLMovingObject *mo1 = [TXLMovingObjectTestData c1];
    TXLMovingObject *mo2 = [TXLMovingObjectTestData d1];
    TXLMovingObjectSequence *result = [mo2 intersectionWithMovingObject:mo1];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData intersection_c1_d1], nil);
}

- (void)testIntersection_a1_e1 {
    TXLMovingObject *mo1 = [TXLMovingObjectTestData a1];
    TXLMovingObject *mo2 = [TXLMovingObjectTestData e1];
    TXLMovingObjectSequence *result = [mo1 intersectionWithMovingObject:mo2];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData intersection_a1_e1], nil);
}


- (void)testIntersection_f1_f2 {
    TXLMovingObject *mo1 = [TXLMovingObjectTestData f1];
    TXLMovingObject *mo2 = [TXLMovingObjectTestData f2];
    TXLMovingObjectSequence *result = [mo1 intersectionWithMovingObject:mo2];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData intersection_f1_f2], nil);
}

- (void)testIntersection_f3_f4 {
    TXLMovingObject *mo1 = [TXLMovingObjectTestData f3];
    TXLMovingObject *mo2 = [TXLMovingObjectTestData f4];
    TXLMovingObjectSequence *result = [mo1 intersectionWithMovingObject:mo2];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData intersection_f3_f4], nil);
}


#pragma mark -
#pragma mark Test Complement

- (void)testComplement_c1_d1 {
    TXLMovingObject *mo1 = [TXLMovingObjectTestData c1];
    TXLMovingObject *mo2 = [TXLMovingObjectTestData d1];
    TXLMovingObjectSequence *result = [mo1 complementWithMovingObject:mo2];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData complement_c1_d1], nil);
}

- (void)testComplement_a1_e1 {
    TXLMovingObject *mo1 = [TXLMovingObjectTestData a1];
    TXLMovingObject *mo2 = [TXLMovingObjectTestData e1];
    TXLMovingObjectSequence *result = [mo1 complementWithMovingObject:mo2];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData complement_a1_e1], nil);
}

#pragma mark -
#pragma mark Test Mask Operations

- (void)testInInterval {
    TXLMovingObject *mo = [TXLMovingObjectTestData a1];
    TXLMovingObject *result = [mo movingObjectInIntervalFrom:DATE(@"1999-01-01 02:00:00 +0200")
                                                          to:DATE(@"2000-01-01 02:10:00 +0200")];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData inInterval1], nil);
}

- (void)testNotInInterval {
    TXLMovingObject *mo = [TXLMovingObjectTestData b2];
    TXLMovingObjectSequence *result = [mo movingObjectNotInIntervalFrom:DATE(@"2000-01-01 07:10:00 +0200")
                                                                     to:DATE(@"2000-01-01 09:00:00 +0200")];
    GHAssertEqualObjects(result, [TXLMovingObjectTestData notInInterval1], nil);
	
	mo = [TXLMovingObject omnipresentMovingObject];
	result = [mo movingObjectNotInIntervalFrom:DATE(@"2000-01-01 07:10:00 +0200")
			  								to:nil];
    GHAssertEqualObjects(result, [TXLMovingObjectSequence sequenceWithMovingObject:
								  			[TXLMovingObject movingObjectWithBegin:nil
																			   end:DATE(@"2000-01-01 07:10:00 +0200")]], nil);
	result = [mo movingObjectNotInIntervalFrom:nil
			  								to:DATE(@"2000-01-01 07:10:00 +0200")];
    GHAssertEqualObjects(result, [TXLMovingObjectSequence sequenceWithMovingObject:
								  [TXLMovingObject movingObjectWithBegin:DATE(@"2000-01-01 07:10:00 +0200")
																	 end:nil]], nil);
	
	result = [mo movingObjectNotInIntervalFrom:nil
			  								to:nil];
    GHAssertEqualObjects(result, [TXLMovingObjectSequence sequenceWithMovingObject:
								  [TXLMovingObject emptyMovingObject]], nil);
}

@end

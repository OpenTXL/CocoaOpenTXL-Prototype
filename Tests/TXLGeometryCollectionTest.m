//
//  TXLGeometryCollectionTest.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 19.10.10.
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

#import "TXLGeometryCollection.h"
#import "TXLPolygon.h"
#import "TXLRing.h"
#import "TXLPoint.h"
#import "TXLLinestring.h"
#import "TXLGeometryTypes.h"
#import "TXLManager.h"
#import "TXLDatabase.h"


#define SQL(x) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

@interface TXLGeometryCollectionTest : GHTestCase {
    
}

@end

@implementation TXLGeometryCollectionTest

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

- (void)testSavePoints {
    NSError *error;
    
    NSMutableArray *points = [NSMutableArray array];
    [points addObject:[[[TXLPoint alloc] initWithLongitude:10 latitude:15] autorelease]];
    [points addObject:[[[TXLPoint alloc] initWithLongitude:12 latitude:16] autorelease]];
    [points addObject:[[[TXLPoint alloc] initWithLongitude:15 latitude:17] autorelease]];
    
    TXLGeometryCollection *coll = nil;
    
    coll = [TXLGeometryCollection geometryWithPoints:points
                                         linestrings:[NSMutableArray array]
                                            polygons:[NSMutableArray array]];
    
    GHAssertFalse(coll.savedInDatabase, nil);
    GHAssertNotNil([coll save:&error], [error localizedDescription]);
    GHAssertTrue(coll.savedInDatabase, nil);
    
    NSUInteger pk = coll.primaryKey;
    
    coll = [TXLGeometryCollection geometryWithPrimaryKey:pk];
    GHAssertTrue(coll.savedInDatabase, nil);
    
    // check content (points)
    GHAssertEqualObjects(points, coll.points, nil);
    
    // check content (linestrings)
    GHAssertEqualObjects([NSMutableArray array], coll.linestrings, nil);

    // check content (polygons)
    GHAssertEqualObjects([NSMutableArray array], coll.polygons, nil);
}

- (void)testSaveLinestrings {
    NSError *error;
    
    NSMutableArray *points = [NSMutableArray array];
    [points addObject:[[[TXLPoint alloc] initWithLongitude:10 latitude:15] autorelease]];
    [points addObject:[[[TXLPoint alloc] initWithLongitude:12 latitude:16] autorelease]];
    [points addObject:[[[TXLPoint alloc] initWithLongitude:15 latitude:17] autorelease]];
    
    NSMutableArray *linestrings = [NSMutableArray array];
    [linestrings addObject:[[[TXLLinestring alloc] initWithPoints:points] autorelease]];
    
    TXLGeometryCollection *coll = nil;
    
    coll = [TXLGeometryCollection geometryWithPoints:[NSMutableArray array]
                                         linestrings:linestrings
                                            polygons:[NSMutableArray array]];
    
    GHAssertFalse(coll.savedInDatabase, nil);
    GHAssertNotNil([coll save:&error], [error localizedDescription]);
    GHAssertTrue(coll.savedInDatabase, nil);
    
    NSUInteger pk = coll.primaryKey;
    
    coll = [TXLGeometryCollection geometryWithPrimaryKey:pk];
    GHAssertTrue(coll.savedInDatabase, nil);
    
    // check content (points)
    GHAssertEqualObjects([NSMutableArray array], coll.points, nil);
    
    // check content (linestrings)
    GHAssertEqualObjects(linestrings, coll.linestrings, nil);
    
    // check content (polygons)
    GHAssertEqualObjects([NSMutableArray array], coll.polygons, nil);
}

- (void)testSavePointsAndLinestrings {
    NSError *error;
    
    NSMutableArray *points = [NSMutableArray array];
    [points addObject:[[[TXLPoint alloc] initWithLongitude:10 latitude:15] autorelease]];
    [points addObject:[[[TXLPoint alloc] initWithLongitude:12 latitude:16] autorelease]];
    [points addObject:[[[TXLPoint alloc] initWithLongitude:15 latitude:17] autorelease]];
    
    NSMutableArray *linestrings = [NSMutableArray array];
    [linestrings addObject:[[[TXLLinestring alloc] initWithPoints:points] autorelease]];
    
    TXLGeometryCollection *coll = nil;
    
    coll = [TXLGeometryCollection geometryWithPoints:points
                                         linestrings:linestrings
                                            polygons:[NSMutableArray array]];
    
    GHAssertFalse(coll.savedInDatabase, nil);
    GHAssertNotNil([coll save:&error], [error localizedDescription]);
    GHAssertTrue(coll.savedInDatabase, nil);
    
    NSUInteger pk = coll.primaryKey;
    
    coll = [TXLGeometryCollection geometryWithPrimaryKey:pk];
    GHAssertTrue(coll.savedInDatabase, nil);
    
    // check content (points)
    GHAssertEqualObjects(points, coll.points, nil);
    
    // check content (linestrings)
    GHAssertEqualObjects(linestrings, coll.linestrings, nil);
    
    // check content (polygons)
    GHAssertEqualObjects([NSMutableArray array], coll.polygons, nil);
}

- (void)testSavePolygon {
    NSError *error;
    
    NSMutableArray *pointsA = [NSMutableArray array];
    [pointsA addObject:[[[TXLPoint alloc] initWithLongitude:10 latitude:10] autorelease]];
    [pointsA addObject:[[[TXLPoint alloc] initWithLongitude:20 latitude:10] autorelease]];
    [pointsA addObject:[[[TXLPoint alloc] initWithLongitude:20 latitude:20] autorelease]];
    [pointsA addObject:[[[TXLPoint alloc] initWithLongitude:10 latitude:20] autorelease]];
    [pointsA addObject:[[[TXLPoint alloc] initWithLongitude:10 latitude:10] autorelease]];
    
    TXLRing *ringA = [[[TXLRing alloc] initWithPoints:pointsA
                                            clockwise:NO] autorelease];
    
    TXLPolygon *polyA = [[TXLPolygon alloc] initWithExteriorRing:ringA
                                                   interiorRings:[NSArray array]];
    
    TXLGeometryCollection *coll = nil;
    
    coll = [TXLGeometryCollection geometryWithPoints:[NSMutableArray array]
                                         linestrings:[NSMutableArray array]
                                            polygons:[NSArray arrayWithObject:polyA]];
    
    GHAssertFalse(coll.savedInDatabase, nil);
    GHAssertNotNil([coll save:&error], [error localizedDescription]);
    GHAssertTrue(coll.savedInDatabase, nil);
    
    NSUInteger pk = coll.primaryKey;
    
    coll = [TXLGeometryCollection geometryWithPrimaryKey:pk];
    GHAssertTrue(coll.savedInDatabase, nil);
    
    // check content (points)
    GHAssertEqualObjects([NSMutableArray array], coll.points, nil);
    
    // check content (linestrings)
    GHAssertEqualObjects([NSMutableArray array], coll.linestrings, nil);
    
    // check content (polygons)
    GHAssertEqualObjects([NSArray arrayWithObject:polyA], coll.polygons, nil);
}


- (void)testFromWKT {
    NSError *error;
    
    NSMutableArray *pointsA = [NSMutableArray array];
    [pointsA addObject:[[[TXLPoint alloc] initWithLongitude:10 latitude:10] autorelease]];
    [pointsA addObject:[[[TXLPoint alloc] initWithLongitude:20 latitude:10] autorelease]];
    [pointsA addObject:[[[TXLPoint alloc] initWithLongitude:20 latitude:20] autorelease]];
    [pointsA addObject:[[[TXLPoint alloc] initWithLongitude:10 latitude:20] autorelease]];
    [pointsA addObject:[[[TXLPoint alloc] initWithLongitude:10 latitude:10] autorelease]];
    
    TXLRing *ringA = [[[TXLRing alloc] initWithPoints:pointsA
                                            clockwise:NO] autorelease];
    
    TXLPolygon *polyA = [[TXLPolygon alloc] initWithExteriorRing:ringA
                                                   interiorRings:[NSArray array]];
    
    TXLGeometryCollection *coll = nil;
    
    coll = [TXLGeometryCollection geometryFromWKT:@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"];
    
    GHAssertFalse(coll.savedInDatabase, nil);
    GHAssertNotNil([coll save:&error], [error localizedDescription]);
    GHAssertTrue(coll.savedInDatabase, nil);
    
    NSUInteger pk = coll.primaryKey;
    
    coll = [TXLGeometryCollection geometryWithPrimaryKey:pk];
    GHAssertTrue(coll.savedInDatabase, nil);
    
    // check content (points)
    GHAssertEqualObjects([NSMutableArray array], coll.points, nil);
    
    // check content (linestrings)
    GHAssertEqualObjects([NSMutableArray array], coll.linestrings, nil);
    
    // check content (polygons)
    GHAssertEqualObjects([NSArray arrayWithObject:polyA], coll.polygons, nil);
}

- (void)testIntersection {
    
    TXLGeometryCollection *collA = [TXLGeometryCollection geometryFromWKT:@"POLYGON((10 10, 20 10, 20 20, 10 20, 10 10))"];
    TXLGeometryCollection *collB = [TXLGeometryCollection geometryFromWKT:@"POLYGON((15 15, 25 15, 25 25, 15 25, 15 15))"];
    
    // geom C
    NSMutableArray *pointsC = [NSMutableArray array];
    [pointsC addObject:[[[TXLPoint alloc] initWithLongitude:15 latitude:15] autorelease]];
    [pointsC addObject:[[[TXLPoint alloc] initWithLongitude:20 latitude:15] autorelease]];
    [pointsC addObject:[[[TXLPoint alloc] initWithLongitude:20 latitude:20] autorelease]];
    [pointsC addObject:[[[TXLPoint alloc] initWithLongitude:15 latitude:20] autorelease]];
    [pointsC addObject:[[[TXLPoint alloc] initWithLongitude:15 latitude:15] autorelease]];
    
    TXLRing *ringC = [[[TXLRing alloc] initWithPoints:pointsC
                                            clockwise:NO] autorelease];
    
    TXLPolygon *polyC = [[TXLPolygon alloc] initWithExteriorRing:ringC
                                                   interiorRings:[NSArray array]];
    
    // build the intersection
    TXLGeometryCollection *result = [collA intersection:collB];
    GHAssertNotNil(result, nil);
    
    // check content (polygons)
    GHAssertEqualObjects([NSArray arrayWithObject:polyC], result.polygons, nil);
}

- (void)testEqual {
    GHAssertEqualObjects([TXLGeometryCollection geometryFromWKT:@"POLYGON((4 4, 4 2, 4 1, 1 1, 1 4, 2 4, 4 4))"],
                         [TXLGeometryCollection geometryFromWKT:@"POLYGON((1 1, 4 1, 4 4, 1 4, 1 1))"],
                         nil);
}

- (void)testUnion {
    GHTestLog(@"%@", [[TXLGeometryCollection geometryFromWKT:@"LINESTRING (6 6, 6 1)"] union:[TXLGeometryCollection geometryFromWKT:@"LINESTRING (4 3, 6 3)"]]);
}

@end

//
//  TXLMovingObjectTestData.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 02.02.11.
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

#import "TXLMovingObjectTestData.h"

#import "TXLMovingObject.h"
#import "TXLPoint.h"
#import "TXLGeometryCollection.h"
#import "TXLSnapshot.h"

#import "TXLDatabase.h"
#import "TXLManager.h"

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import "NSDate+dateWithString.h"
#endif

#define DATE(x) [NSDate dateWithString:x]
#define GEO(x) [TXLGeometryCollection geometryFromWKT:x]


@implementation TXLMovingObjectTestData

#pragma mark -
#pragma mark Moving Objects

+ (TXLMovingObject *)a1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((1 1, 3 1, 3 3, 1 3, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 3, 5 3, 5 5, 3 5, 3 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 4, 6 4, 6 6, 4 6, 4 4))")]];
    
    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
}

+ (TXLMovingObject *)a2 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 04:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 4, 6 4, 6 6, 4 6, 4 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 05:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 4, 4 4, 4 6, 2 6, 2 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 06:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 3, 3 3, 3 5, 1 5, 1 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 07:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((0 2, 2 2, 2 4, 0 4, 0 2))")]];
    
    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
}

+ (TXLMovingObject *)a3 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 08:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 3, 3 3, 3 5, 1 5, 1 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 09:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((1 1, 3 1, 3 3, 1 3, 1 1))")]];
    
    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
}

+ (TXLMovingObject *)b1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 1, 4 1, 4 4, 1 4, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 03:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 0, 5 0, 5 3, 2 3, 2 0))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 04:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 0, 6 0, 6 3, 3 3, 3 0))")]];
    
    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
    
}

+ (TXLMovingObject *)b2 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 06:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 5, 6 5, 6 6, 1 6, 1 5))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 07:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 4, 6 4, 6 6, 1 6, 1 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 08:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 3, 6 3, 6 6, 1 6, 1 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 09:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 1, 6 1, 6 6, 1 6, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((1 0, 6 0, 6 6, 1 6, 1 0))")]];
    
    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
}

+ (TXLMovingObject *)c1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((4 1, 6 1, 6 7, 4 7, 4 1))")]];
    
    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
}

+ (TXLMovingObject *)d1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 3, 3 5, 5 5, 5 3, 3 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 3, 4 3, 4 5, 2 5, 2 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 03:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 3, 3 3, 3 5, 1 5, 1 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 04:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 3, 4 3, 4 5, 2 5, 2 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 05:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 3, 5 3, 5 5, 3 5, 3 3))")]];
    
    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
}

+ (TXLMovingObject *)e1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 4, 6 4, 6 6, 4 6, 4 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((1 1, 3 1, 3 3, 1 3, 1 1))")]];
    
    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
}

+ (TXLMovingObject *)f1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-17 00:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 3, 2 3, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-18 00:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 3, 4 3, 4 4, 2 4, 2 3))")]];
    
    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
}

+ (TXLMovingObject *)f2 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-17 20:30:00 +0200")
                                                   geometry:GEO(@"POINT(3 2.5)")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-18 23:00:00 +0200")
                                                   geometry:GEO(@"POINT(3 2.5)")]];
    
    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
}

+ (TXLMovingObject *)f3 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-17 00:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 3, 2 3, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-18 00:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 3, 4 3, 4 4, 2 4, 2 3))")]];

    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-19 00:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 3, 4 3, 4 4, 2 4, 2 3))")]];

    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
}

+ (TXLMovingObject *)f4 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-17 20:30:00 +0200")
                                                   geometry:GEO(@"POINT(3 2.5)")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-18 23:00:00 +0200")
                                                   geometry:GEO(@"POINT(3 2.5)")]];
    
    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
}


#pragma mark -
#pragma mark Moving Object Sequneces

+ (TXLMovingObjectSequence *)A {
    NSMutableArray *movingObjects = [NSMutableArray array];
    
    [movingObjects addObject:[self a1]];
    [movingObjects addObject:[self a2]];
    [movingObjects addObject:[self a3]];
    
    return [TXLMovingObjectSequence sequenceWithArray:movingObjects];
}

+ (TXLMovingObjectSequence *)B {
    NSMutableArray *movingObjects = [NSMutableArray array];
    
    [movingObjects addObject:[self b1]];
    [movingObjects addObject:[self b2]];
    
    return [TXLMovingObjectSequence sequenceWithArray:movingObjects];
}

#pragma mark -
#pragma mark Results

+ (TXLMovingObjectSequence *)union_A_B {
    NSMutableArray *objects = [NSMutableArray array];
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((1 1, 3 1, 3 3, 1 3, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 1, 4 1, 4 4, 1 4, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 1, 4 1, 4 3, 5 3, 5 5, 3 5, 3 4, 1 4, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:30:00 +0200")
                                                   geometry:GEO(@"GEOMETRYCOLLECTION(POLYGON((1 1, 4 1, 4 4, 1 4, 1 1)), POLYGON((4 4, 6 4, 6 6, 4 6, 4 4)))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 1, 4 1, 4 4, 1 4, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 03:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 0, 5 0, 5 3, 2 3, 2 0))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 04:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 0, 6 0, 6 3, 3 3, 3 0))")]];
    
    [objects addObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
    snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 04:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 4, 6 4, 6 6, 4 6, 4 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 05:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 4, 4 4, 4 6, 2 6, 2 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 06:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 4, 4 4, 4 6, 2 6, 2 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 06:00:00 +0200")
                                                   geometry:[GEO(@"POLYGON((1 5, 6 5, 6 6, 1 6, 1 5))") union:GEO(@"POLYGON((2 4, 4 4, 4 6, 2 6, 2 4))")]]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 06:30:00 +0200")
                                                   geometry:[GEO(@"POLYGON((1 3, 3 3, 3 5, 1 5, 1 3))") union:GEO(@"POLYGON((1 5, 6 5, 6 6, 1 6, 1 5))")]]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 07:00:00 +0200")
                                                   geometry:[GEO(@"POLYGON((1 4, 6 4, 6 6, 1 6, 1 4))") union:GEO(@"POLYGON((1 3, 3 3, 3 5, 1 5, 1 3))")]]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 07:30:00 +0200")
                                                   geometry:[GEO(@"POLYGON((0 2, 2 2, 2 4, 0 4, 0 2))") union:GEO(@"POLYGON((1 4, 6 4, 6 6, 1 6, 1 4))")]]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 07:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 4, 6 4, 6 6, 1 6, 1 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 08:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 3, 6 3, 6 6, 1 6, 1 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 08:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 3, 6 3, 6 6, 1 6, 1 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 08:30:00 +0200")
                                                   geometry:[GEO(@"POLYGON((1 3, 6 3, 6 6, 1 6, 1 3))") union:GEO(@"POLYGON((1 3, 3 3, 3 5, 1 5, 1 3))")]]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 09:00:00 +0200")
                                                   geometry:[GEO(@"POLYGON((1 1, 6 1, 6 6, 1 6, 1 1))") union:GEO(@"POLYGON((1 3, 3 3, 3 5, 1 5, 1 3))")]]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 09:30:00 +0200")
                                                   geometry:[GEO(@"POLYGON((1 1, 6 1, 6 6, 1 6, 1 1))") union:GEO(@"POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))")]]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:[GEO(@"POLYGON((1 1, 3 1, 3 3, 1 3, 1 1))") union:GEO(@"POLYGON((1 0, 6 0, 6 6, 1 6, 1 0))")]]];

    [objects addObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
    
    return [TXLMovingObjectSequence sequenceWithArray:objects];
}

+ (TXLMovingObjectSequence *)union_a1_b1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((1 1, 3 1, 3 3, 1 3, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 1, 4 1, 4 4, 1 4, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 1, 4 1, 4 3, 5 3, 5 5, 3 5, 3 4, 1 4, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:30:00 +0200")
                                                   geometry:GEO(@"GEOMETRYCOLLECTION(POLYGON((1 1, 4 1, 4 4, 1 4, 1 1)), POLYGON((4 4, 6 4, 6 6, 4 6, 4 4)))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 1, 4 1, 4 4, 1 4, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 03:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 0, 5 0, 5 3, 2 3, 2 0))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 04:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 0, 6 0, 6 3, 3 3, 3 0))")]];
    
    return [TXLMovingObjectSequence sequenceWithMovingObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
}

+ (TXLMovingObjectSequence *)union_a1_e1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((1 1, 3 1, 3 3, 1 3, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 3, 5 3, 5 5, 3 5, 3 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 4, 6 4, 6 6, 4 6, 4 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((1 1, 3 1, 3 3, 1 3, 1 1))")]];
    
    return [TXLMovingObjectSequence sequenceWithMovingObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
}

+ (TXLMovingObjectSequence *)intersection_A_B {
    NSMutableArray *objects = [NSMutableArray array];
    NSMutableArray *snapshots = [NSMutableArray array];

    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 2, 2 2, 2 4, 4 4, 4 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 3, 3 3, 3 4, 4 4, 4 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:30:00 +0200")
                                                   geometry:GEO(@"POINT(4 4)")]];
    
    
    [objects addObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
    snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 06:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 6, 4 5, 2 5, 2 6, 4 6))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 06:30:00 +0200")
                                                   geometry:GEO(@"LINESTRING(3 5, 1 5)")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 07:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 5, 3 5, 3 4, 1 4, 1 5))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 07:30:00 +0200")
                                                   geometry:GEO(@"LINESTRING(2 4, 1 4)")]];
    
    
    [objects addObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
    snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 08:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 3, 1 3, 1 5, 3 5, 3 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 09:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 5, 3 5, 3 3, 1 3, 1 5))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 09:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 2 4, 4 4, 4 2, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((1 3, 3 3, 3 1, 1 1, 1 3))")]];
    
    [objects addObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
    
    return [TXLMovingObjectSequence sequenceWithArray:objects];
}

+ (TXLMovingObjectSequence *)intersection_a1_b1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 3, 4 3, 4 4, 3 4, 3 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:30:00 +0200")
                                                   geometry:GEO(@"POINT(4 4)")]];
    
    return [TXLMovingObjectSequence sequenceWithMovingObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
}

+ (TXLMovingObjectSequence *)intersection_c1_d1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 3, 5 3, 5 5, 4 5, 4 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:00:00 +0200")
                                                   geometry:GEO(@"LINESTRING(4 3, 4 5)")]];

    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 03:00:00 +0200")
                                                   geometry:GEO(@"LINESTRING(4 3, 4 5)")]];
    
    TXLMovingObject *mo1 = [TXLMovingObject movingObjectWithSnapshots:snapshots];
    
    
    snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 04:00:00 +0200")
                                                   geometry:GEO(@"LINESTRING(4 3, 4 5)")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 05:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 3, 5 3, 5 5, 4 5, 4 3))")]];

    TXLMovingObject *mo2 = [TXLMovingObject movingObjectWithSnapshots:snapshots];
    
    return [TXLMovingObjectSequence sequenceWithArray:[NSArray arrayWithObjects:mo1, mo2, nil]];
}

+ (TXLMovingObjectSequence *)intersection_a1_e1 {
    return [TXLMovingObjectSequence emptySequence];
}


+ (TXLMovingObjectSequence *)intersection_f1_f2 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-17 20:30:00 +0200")
                                                   geometry:GEO(@"POINT(3 2.5)")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-18 00:00:00 +0200")
                                                   geometry:GEO(@"POINT(3 2.5)")]];
    
    return [TXLMovingObjectSequence sequenceWithMovingObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
}

+ (TXLMovingObjectSequence *)intersection_f3_f4 {
    
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-17 20:30:00 +0200")
                                                   geometry:GEO(@"POINT(3 2.5)")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2011-07-18 00:00:00 +0200")
                                                   geometry:GEO(@"POINT(3 2.5)")]];
    
    return [TXLMovingObjectSequence sequenceWithMovingObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
}

+ (TXLMovingObjectSequence *)complement_A_B {
    NSMutableArray *objects = [NSMutableArray array];
    NSMutableArray *snapshots = [NSMutableArray array];
    
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((1 1, 3 1, 3 3, 1 3, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))")]];
    
    [objects addObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
    snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 4, 3 5, 5 5, 5 3, 4 3, 4 4, 3 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 4, 4 6, 6 6, 6 4, 4 4))")]];
    
    [objects addObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
    snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 04:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 4, 6 4, 6 6, 4 6, 4 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 05:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 4, 4 4, 4 6, 2 6, 2 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 06:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 4, 4 4, 4 6, 2 6, 2 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 06:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 5, 4 4, 2 4, 2 5, 4 5))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 06:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 5, 3 3, 1 3, 1 5, 3 5))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 07:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 4, 3 3, 1 3, 1 4, 3 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 07:30:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 4, 2 2, 0 2, 0 4, 1 4, 2 4))")]];
    
    [objects addObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
    
    return [TXLMovingObjectSequence sequenceWithArray:objects];
}

+ (TXLMovingObjectSequence *)complement_c1_d1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((4 1, 6 1, 6 7, 4 7, 4 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 1, 6 1, 6 7, 4 7, 4 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 1, 6 1, 6 7, 4 7, 4 5, 5 5, 5 3, 4 3, 4 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 1, 6 1, 6 7, 4 7, 4 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 03:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 1, 6 1, 6 7, 4 7, 4 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 04:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 1, 6 1, 6 7, 4 7, 4 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 05:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 1, 6 1, 6 7, 4 7, 4 5, 5 5, 5 3, 4 3, 4 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 05:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((4 1, 6 1, 6 7, 4 7, 4 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((4 1, 6 1, 6 7, 4 7, 4 1))")]];
    
    return [TXLMovingObjectSequence sequenceWithMovingObject:[TXLMovingObject movingObjectWithSnapshots:snapshots]];
}

+ (TXLMovingObjectSequence *)complement_a1_e1 {
    return [TXLMovingObjectSequence sequenceWithMovingObject:[self a1]];
}

+ (TXLMovingObject *)inInterval1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"1999-01-01 02:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 1, 3 1, 3 3, 1 3, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 01:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((2 2, 4 2, 4 4, 2 4, 2 2))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 3, 5 3, 5 5, 3 5, 3 3))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 02:10:00 +0200")
                                                   geometry:GEO(@"POLYGON((3 3, 5 3, 5 5, 3 5, 3 3))")]];
    
    return [TXLMovingObject movingObjectWithSnapshots:snapshots];
}

+ (TXLMovingObjectSequence *)notInInterval1 {
    NSMutableArray *snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 06:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 5, 6 5, 6 6, 1 6, 1 5))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 07:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 4, 6 4, 6 6, 1 6, 1 4))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 07:10:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 4, 6 4, 6 6, 1 6, 1 4))")]];
    
    TXLMovingObject *mo1 = [TXLMovingObject movingObjectWithSnapshots:snapshots];
    
    
    snapshots = [NSMutableArray array];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:DATE(@"2000-01-01 09:00:00 +0200")
                                                   geometry:GEO(@"POLYGON((1 1, 6 1, 6 6, 1 6, 1 1))")]];
    
    [snapshots addObject:[TXLSnapshot snapshotWithTimestamp:nil
                                                   geometry:GEO(@"POLYGON((1 0, 6 0, 6 6, 1 6, 1 0))")]];
    
    TXLMovingObject *mo2 = [TXLMovingObject movingObjectWithSnapshots:snapshots];
    
    return [TXLMovingObjectSequence sequenceWithArray:[NSArray arrayWithObjects:mo1, mo2, nil]];
}

@end

//
//  TXLGeometryCollection.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 29.09.10.
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

#import <Foundation/Foundation.h>

#import "TXLGeometryTypes.h"

@class TXLLinestring;
@class TXLPolygon;

@interface TXLGeometryCollection : NSObject {

@private
    NSUInteger primaryKey;
    void * _collection;
}

+ (TXLGeometryCollection *)geometryFromWKT:(NSString *)wkt;

+ (TXLGeometryCollection *)geometryWithPoints:(NSArray *)points
                                  linestrings:(NSArray *)linestrings
                                     polygons:(NSArray *)polygons;

+ (TXLGeometryCollection *)geometryForEntireWorld;

#pragma mark -
#pragma mark Accessing Details

@property (readonly) TXLBoundingBox boundingBox;

- (void)iterateOverPoints:(void(^)(TXLCoordinate coordinate, BOOL *stop))iterator;
- (void)iterateOverLinestrings:(void(^)(TXLLinestring *linestring, BOOL *stop))iterator;
- (void)iterateOverPolygons:(void(^)(TXLPolygon *polygon, BOOL *stop))iterator;

@property (readonly) NSArray *points;
@property (readonly) NSArray *linestrings;
@property (readonly) NSArray *polygons;

#pragma mark -
#pragma mark Predicates

@property (readonly, getter=isEmpty) BOOL empty;

#pragma mark -
#pragma mark Relations

- (BOOL)contains:(TXLGeometryCollection *)other;
- (BOOL)disjoint:(TXLGeometryCollection *)other;
- (BOOL)intersects:(TXLGeometryCollection *)other;
- (BOOL)overlaps:(TXLGeometryCollection *)other;
- (BOOL)crosses:(TXLGeometryCollection *)other;
- (BOOL)touches:(TXLGeometryCollection *)other;
- (BOOL)within:(TXLGeometryCollection *)other;

#pragma mark -
#pragma mark Operations

- (TXLGeometryCollection *)intersection:(TXLGeometryCollection *)other;
- (TXLGeometryCollection *)union:(TXLGeometryCollection *)other;
- (TXLGeometryCollection *)difference:(TXLGeometryCollection *)other;
- (TXLGeometryCollection *)symDifference:(TXLGeometryCollection *)other;

#pragma mark -
#pragma mark Database Management

+ (id)geometryWithPrimaryKey:(NSUInteger)pk;

@property (readonly) NSUInteger primaryKey;
@property (readonly, getter=isSavedInDatabase) BOOL savedInDatabase;

- (TXLGeometryCollection *)save:(NSError **)error;

@end

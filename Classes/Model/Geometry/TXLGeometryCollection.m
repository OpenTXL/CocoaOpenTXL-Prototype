//
//  TXLGeometryCollection.m
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

#import "TXLGeometryCollection.h"

#import "TXLPoint.h"
#import "TXLLinestring.h"
#import "TXLPolygon.h"

#import "TXLDatabase.h"
#import "TXLInteger.h"
#import "TXLManager.h"

#import <spatialite/sqlite3.h>
#import <spatialite/gaiageo.h>
#import <spatialite.h>

#import <geos_c.h>

static void _geos_error (const char *fmt, ...)
{
    // TODO: Better error reporting
    
    /* reporting some GEOS warning/error */
    va_list ap;
    fprintf (stderr, "GEOS: ");
    va_start (ap, fmt);
    vfprintf (stdout, fmt, ap);
    va_end (ap);
    fprintf (stdout, "\n");
}

@interface TXLGeometryCollection ()
- (id)initWithPrimaryKey:(NSUInteger)pk;
- (id)initWithPoints:(NSArray *)points
         linestrings:(NSArray *)linestrings
            polygons:(NSArray *)polygons;
- (id)initWithGaiaGeomColl:(gaiaGeomCollPtr)ptr;
@property (readonly) gaiaGeomCollPtr _collection;
@end


@implementation TXLGeometryCollection

@synthesize primaryKey;

+ (void)load {
    // Initialize the GEOS library on start. This has to be
    // done before any function of spatialite (gaia...) is
    // called, which uses that library.
    initGEOS (_geos_error, _geos_error);
}

+ (TXLGeometryCollection *)geometryFromWKT:(NSString *)wkt {
    gaiaGeomCollPtr geom = gaiaParseWkt((const unsigned char *)[wkt cStringUsingEncoding:NSUTF8StringEncoding], -1);
    if (geom) {
        geom->Srid = 4326;

		TXLGeometryCollection *gc = [[[self alloc] initWithGaiaGeomColl:geom] autorelease];
		gaiaFreeGeomColl(geom);
		
        return gc;
    } else {
        return nil;
    }
}

+ (TXLGeometryCollection *)geometryWithPoints:(NSArray *)points
                                  linestrings:(NSArray *)linestrings
                                     polygons:(NSArray *)polygons {
    return [[[TXLGeometryCollection alloc] initWithPoints:points
                                              linestrings:linestrings
                                                 polygons:polygons] autorelease];
}

+ (TXLGeometryCollection *)geometryForEntireWorld {
    return [self geometryFromWKT:@"POLYGON((-180 -90, 180 -90, 180 90, -180 90, -180 -90))"];
}

- (id)initWithPrimaryKey:(NSUInteger)pk {
    if ((self = [super init])) {
        primaryKey = pk;
    }
    return self;
}

- (id)initWithPoints:(NSArray *)points
         linestrings:(NSArray *)linestrings
            polygons:(NSArray *)polygons {
    if ((self = [super init])) {
        _collection = gaiaAllocGeomColl();
        assert(_collection);
        // TODO: Better error handling
        
        ((gaiaGeomCollPtr)_collection)->Srid = 4326;
        
        for (TXLPoint *point in points) {
            gaiaAddPointToGeomColl(_collection, point.coordinate.longitude, point.coordinate.latitude);
        }
        
        for (TXLLinestring *linestring in linestrings) {
            gaiaInsertLinestringInGeomColl(_collection,
                                           gaiaCloneLinestring(linestring.gaiaLinestring));
        }
        
        for (TXLPolygon *polygon in polygons) {
            gaiaPolygonPtr p = gaiaInsertPolygonInGeomColl(_collection,
                                                           gaiaCloneRing(polygon.gaiaPolygon->Exterior));
            for (TXLRing *ring in polygon.interiorRings) {
                gaiaInsertInteriorRing(p, gaiaCloneRing(ring.gaiaRing));
            }
        }
        
        gaiaMbrGeometry(_collection);
        
        // TODO: Find out, which checks are needed
        // TODO: Better error handling
        assert(gaiaIsValid(_collection));
    }
    return self;
}

- (id)initWithGaiaGeomColl:(gaiaGeomCollPtr)ptr {
    if ((self = [super init])) {
        _collection = gaiaCloneGeomColl(ptr);
        // TODO: Better error handling
        assert(_collection);
        assert(gaiaIsEmpty(_collection) || gaiaIsValid(_collection));
    }
    return self;
}

- (void)dealloc {
    if (_collection) {
        gaiaFreeGeomColl(_collection);
    }
    [super dealloc];
}

#pragma mark -
#pragma mark Accessing Details

- (TXLBoundingBox)boundingBox {
    TXLBoundingBox bbox;
    
    gaiaGeomCollPtr c = self._collection;
    
    bbox.minLongitude = c->MinX;
    bbox.maxLongitude = c->MaxX;
    bbox.minLatitude = c->MinY;
    bbox.maxLatitude = c->MaxY;
    return bbox;
}

- (void)iterateOverPoints:(void(^)(TXLCoordinate coordinate, BOOL *stop))iterator {
    gaiaGeomCollPtr c = self._collection;
    BOOL stop = NO;
    gaiaPointPtr p = c->FirstPoint;
    while (p && !stop) {
        TXLCoordinate coord;
        coord.longitude = p->X;
        coord.latitude = p->Y;
        iterator(coord, &stop);
        p = p->Next;
    }
}

- (void)iterateOverLinestrings:(void(^)(TXLLinestring *linestring, BOOL *stop))iterator {
    gaiaGeomCollPtr c = self._collection;
    BOOL stop = NO;
    gaiaLinestringPtr l = c->FirstLinestring;
    while (l && !stop) {
        TXLLinestring *line = [[TXLLinestring alloc] initWithGaiaLinestring:l];
        iterator(line, &stop);
        [line release];
        l = l->Next;
    }
}

- (void)iterateOverPolygons:(void(^)(TXLPolygon *polygon, BOOL *stop))iterator {
    gaiaGeomCollPtr c = self._collection;
    BOOL stop = NO;
    gaiaPolygonPtr p = c->FirstPolygon;
    while (p && !stop) {
        TXLPolygon *polygon = [[TXLPolygon alloc] initWithGaiaPolygon:p];
        iterator(polygon, &stop);
        [polygon release];
        p = p->Next;
    }
}

- (NSArray *)points {
    NSMutableArray *result = [NSMutableArray array];
    [self iterateOverPoints:^(TXLCoordinate coordinate, BOOL *stop){
        TXLPoint *point = [[TXLPoint alloc] initWithCoordinate:coordinate];
        [result addObject:point];
        [point release];
    }];
    return result;
}

- (NSArray *)linestrings {
    NSMutableArray *result = [NSMutableArray array];
    [self iterateOverLinestrings:^(TXLLinestring *linestring, BOOL *stop){
        [result addObject:linestring];
    }];
    return result;
}

- (NSArray *)polygons {
    NSMutableArray *result = [NSMutableArray array];
    [self iterateOverPolygons:^(TXLPolygon *polygon, BOOL *stop){
        [result addObject:polygon];
    }];
    return result;
}

- (NSString *)description {
    
    // TODO: Remove the following macro if spatialite is integrated in the project
    
#if 1
    NSString *result = nil;
    gaiaOutBuffer out_buf;
    gaiaOutBufferInitialize(&out_buf);
    gaiaOutWkt(&out_buf, self._collection);
    if (out_buf.Error || out_buf.Buffer == NULL) {
        result = nil;
    } else {
        result = [NSString stringWithCString:out_buf.Buffer
                                    encoding:NSUTF8StringEncoding];
    }
    gaiaOutBufferReset(&out_buf);
    return result;
#else
    return [super description];
#endif
}

#pragma mark -
#pragma mark Predicates

- (BOOL)isEmpty {
    return gaiaIsEmpty(self._collection) == 1;
}

#pragma mark -
#pragma mark Relations

- (BOOL)contains:(TXLGeometryCollection *)other {
    return gaiaGeomCollContains(self._collection, other._collection);
}

- (BOOL)disjoint:(TXLGeometryCollection *)other {
    return gaiaGeomCollDisjoint(self._collection, other._collection);
}

- (BOOL)intersects:(TXLGeometryCollection *)other {
    return gaiaGeomCollIntersects(self._collection, other._collection);
}

- (BOOL)overlaps:(TXLGeometryCollection *)other {
    return gaiaGeomCollOverlaps(self._collection, other._collection);
}

- (BOOL)crosses:(TXLGeometryCollection *)other {
    return gaiaGeomCollCrosses(self._collection, other._collection);
}

- (BOOL)touches:(TXLGeometryCollection *)other {
    return gaiaGeomCollTouches(self._collection, other._collection);
}

- (BOOL)within:(TXLGeometryCollection *)other {
    return gaiaGeomCollWithin(self._collection, other._collection);
}

#pragma mark -
#pragma mark Operations

- (TXLGeometryCollection *)intersection:(TXLGeometryCollection *)other {
    gaiaGeomCollPtr result = gaiaGeometryIntersection(self._collection, other._collection);
    
    assert(result);
    // TODO: Better error handling
    
	TXLGeometryCollection *gc = [[[TXLGeometryCollection alloc] initWithGaiaGeomColl:result] autorelease];
	gaiaFreeGeomColl(result);
	
    return gc;
}

- (TXLGeometryCollection *)union:(TXLGeometryCollection *)other {
    gaiaGeomCollPtr result = gaiaGeometryUnion(self._collection, other._collection);
    
    assert(result);
    // TODO: Better error handling
    
	TXLGeometryCollection *gc = [[[TXLGeometryCollection alloc] initWithGaiaGeomColl:result] autorelease];
	gaiaFreeGeomColl(result);
	
    return gc;
}

- (TXLGeometryCollection *)difference:(TXLGeometryCollection *)other {
    gaiaGeomCollPtr result = gaiaGeometryDifference(self._collection, other._collection);
    
    assert(result);
    // TODO: Better error handling
    
	TXLGeometryCollection *gc = [[[TXLGeometryCollection alloc] initWithGaiaGeomColl:result] autorelease];
	gaiaFreeGeomColl(result);
	
    return gc;	
}

- (TXLGeometryCollection *)symDifference:(TXLGeometryCollection *)other {
    gaiaGeomCollPtr result = gaiaGeometrySymDifference(self._collection, other._collection);
    
    assert(result);
    // TODO: Better error handling
    
	TXLGeometryCollection *gc = [[[TXLGeometryCollection alloc] initWithGaiaGeomColl:result] autorelease];
	gaiaFreeGeomColl(result);
	
    return gc;
}

#pragma mark -
#pragma mark Operations

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TXLGeometryCollection class]]) {
        TXLGeometryCollection *other = object;
        return gaiaGeomCollEquals(self._collection, other._collection);
    }
    return NO;
}

#pragma mark -
#pragma mark Database Management

+ (id)geometryWithPrimaryKey:(NSUInteger)pk {
    return [[[TXLGeometryCollection alloc] initWithPrimaryKey:pk] autorelease];
}

- (BOOL)isSavedInDatabase {
    return primaryKey;
}

- (TXLGeometryCollection *)save:(NSError **)error {
    @synchronized (self) {
        if (primaryKey == 0) {
            
            unsigned char *data;
            int size;
            
            // We have to set the type of this collection explicit,
            // because the column in the database does only accept a
            // GEOMETRYCOLLECTION and if we have only points in _collection
            // the function would create a MULTIPOINT
            ((gaiaGeomCollPtr)_collection)->DeclaredType = GAIA_GEOMETRYCOLLECTION;
            
            gaiaToSpatiaLiteBlobWkb(_collection, &data, &size);
            
            assert(data);
            // TODO: Better error handling
            
            TXLDatabase *database = [[TXLManager sharedManager] database];
            if ([database executeSQLWithParameters:@"INSERT INTO txl_geometry (geometry) VALUES (?)" error:error,
                 [NSData dataWithBytesNoCopy:data length:size freeWhenDone:YES],
                 nil] == nil) {
                return nil;
            };
            primaryKey = database.lastInsertRowid;
        }
    }
    return self;
}

- (gaiaGeomCollPtr)_collection {
    @synchronized (self) {
        if (_collection == 0) {
            NSError *error;
            TXLDatabase *database = [[TXLManager sharedManager] database];
            
            NSArray *result = [database executeSQLWithParameters:@"SELECT CAST (geometry AS BLOB) AS geometry FROM txl_geometry WHERE id = ?" error:&error,
                                    [TXLInteger integerWithValue:primaryKey],
                                    nil];
            
            if (result == nil) {
                [NSException exceptionWithName:@"TXLGeometryCollectionException"
                                        reason:[error localizedDescription]
                                      userInfo:nil];
            }
            
            // TODO: Better error handling
            assert([result count] == 1);
            
            NSData *data = [[result objectAtIndex:0] objectForKey:@"geometry"];
            
            _collection = gaiaFromSpatiaLiteBlobWkb([data bytes], [data length]);
            // TODO: Better error handling
            assert(_collection);
        }
    }
    return _collection;
}

@end

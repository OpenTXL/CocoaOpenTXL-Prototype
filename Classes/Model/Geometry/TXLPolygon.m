//
//  TXLPolygon.m
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

#import "TXLPolygon.h"


@implementation TXLPolygon


- (id)initWithExteriorRing:(TXLRing *)eR
             interiorRings:(NSArray *)iR {
    if ((self = [super init])) {
		gaiaRingPtr rPtr = gaiaCloneRing(eR.gaiaRing);
        _polygon = gaiaCreatePolygon(rPtr);
		gaiaFreeRing(rPtr);
		
        // TODO: Better error handling
        assert(_polygon);
        
        for (TXLRing *ring in iR) {
			gaiaRingPtr irPtr = gaiaCloneRing(ring.gaiaRing);
            gaiaInsertInteriorRing(_polygon, irPtr);
			gaiaFreeRing(irPtr);
        }
        
        gaiaMbrPolygon(_polygon);
    }
    return self;
}

- (id)initWithGaiaPolygon:(gaiaPolygonPtr)ptr {
    if ((self = [super init])) {
        _polygon = gaiaClonePolygon(ptr);
        // TODO: Better error handling
        assert(_polygon);
    }
    return self;
}

- (void)dealloc {
    gaiaFreePolygon(_polygon);
    [super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (TXLBoundingBox)boundingBox {
    TXLBoundingBox bbox;
    bbox.minLongitude = _polygon->MinX;
    bbox.maxLongitude = _polygon->MaxX;
    bbox.minLatitude = _polygon->MinY;
    bbox.maxLatitude = _polygon->MaxY;
    return bbox;
}

- (TXLRing *)exteriorRing {
    return [[[TXLRing alloc] initWithGaiaRing:_polygon->Exterior] autorelease];
}

- (void)iterateOverInteriorRings:(void(^)(TXLRing *ring, BOOL *stop))iterator {
    BOOL stop = NO;
    
    gaiaRingPtr ring = _polygon->Interiors;
    while (ring && !stop) {
        TXLRing *interiorRing = [[TXLRing alloc] initWithGaiaRing:ring];
        iterator(interiorRing, &stop);
        [interiorRing release];
        ring = ring->Next;
    }
}

- (NSArray *)interiorRings {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:_polygon->NumInteriors];
    
    [self iterateOverInteriorRings:^(TXLRing *ring, BOOL *stop){
        [result addObject:ring];
    }];
    
    return result;
}

- (gaiaPolygonPtr)gaiaPolygon {
    return _polygon;
}

#pragma mark -
#pragma mark Operations

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TXLPolygon class]]) {
        TXLPolygon *other = object;
        return gaiaPolygonEquals(self.gaiaPolygon, other.gaiaPolygon);
    }
    return NO;
}

@end

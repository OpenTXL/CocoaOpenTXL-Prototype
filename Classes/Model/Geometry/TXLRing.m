//
//  TXLRing.m
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

#import "TXLRing.h"
#import "TXLPoint.h"


@implementation TXLRing

- (id)initWithPoints:(NSArray *)points
           clockwise:(BOOL)cw; {
    if ((self = [super init])) {
        _ring = gaiaAllocRing([points count]);
        // TODO: Better error handling
        assert(_ring);
        
        _ring->Clockwise = cw;
        
        for (int i = 0; i < [points count]; i++) {
            TXLPoint *point = [points objectAtIndex:i];
            gaiaSetPoint(_ring->Coords, i, point.coordinate.longitude, point.coordinate.latitude);
        }
        
        gaiaMbrRing(_ring);
    }
    return self;
}

- (id)initWithGaiaRing:(gaiaRingPtr)ptr {
    if ((self = [super init])) {
        _ring = gaiaCloneRing(ptr);
        // TODO: Better error handling
        assert(_ring);
    }
    return self;
}

- (void)dealloc {
    gaiaFreeRing(_ring);
    [super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (BOOL)isClockwise {
    return _ring->Clockwise;
}

- (TXLBoundingBox)boundingBox {
    TXLBoundingBox bbox;
    bbox.minLongitude = _ring->MinX;
    bbox.maxLongitude = _ring->MaxX;
    bbox.minLatitude = _ring->MinY;
    bbox.maxLatitude = _ring->MaxY;
    return bbox;
}

- (void)iterateOverPoints:(void(^)(TXLCoordinate coordinate, BOOL *stop))iterator {
    BOOL stop = NO;
    
    for (int i = 0; i < _ring->Points; i++) {
        if (stop)
            break;
        
        TXLCoordinate coord;
        gaiaGetPoint(_ring->Coords, i, &(coord.longitude), &(coord.latitude));
        iterator(coord, &stop);
    }
}

- (gaiaRingPtr)gaiaRing {
    return _ring;
}

#pragma mark -
#pragma mark Operations

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TXLRing class]]) {
        TXLRing *other = object;
        // TODO: Check if the cast is suitable
        return gaiaLinestringEquals((gaiaLinestringPtr)self.gaiaRing, (gaiaLinestringPtr)other.gaiaRing);
    }
    return NO;
}

@end

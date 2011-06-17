//
//  TXLLine.m
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

#import "TXLLinestring.h"
#import "TXLPoint.h"

@implementation TXLLinestring

- (id)initWithPoints:(NSArray *)points {
    if ((self = [super init])) {
        _linestring = gaiaAllocLinestring([points count]);
        // TODO: Better error handling
        assert(_linestring);
        
        for (int i = 0; i < [points count]; i++) {
            TXLPoint *point = [points objectAtIndex:i];
            gaiaSetPoint(_linestring->Coords, i, point.coordinate.longitude, point.coordinate.latitude);
        }
        
        gaiaMbrLinestring(_linestring);
    }
    return self;
}

- (id)initWithGaiaLinestring:(gaiaLinestringPtr)ptr {
    if ((self = [super init])) {
        _linestring = gaiaCloneLinestring(ptr);
        // TODO: Better error handling
        assert(_linestring);
    }
    return self;
}

- (void)dealloc {
    gaiaFreeLinestring(_linestring);
    [super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (TXLBoundingBox)boundingBox {
    TXLBoundingBox bbox;
    bbox.minLongitude = _linestring->MinX;
    bbox.maxLongitude = _linestring->MaxX;
    bbox.minLatitude = _linestring->MinY;
    bbox.maxLatitude = _linestring->MaxY;
    return bbox;
}

- (void)iterateOverPoints:(void(^)(TXLCoordinate coordinate, BOOL *stop))iterator {
    BOOL stop = NO;
    
    for (int i = 0; i < _linestring->Points; i++) {
        if (stop)
            break;
        
        TXLCoordinate coord;
        gaiaGetPoint(_linestring->Coords, i, &(coord.longitude), &(coord.latitude));
        iterator(coord, &stop);
    }
}

- (gaiaLinestringPtr)gaiaLinestring {
    return _linestring;
}

#pragma mark -
#pragma mark Operations

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TXLLinestring class]]) {
        TXLLinestring *other = object;
        return gaiaLinestringEquals(self.gaiaLinestring, other.gaiaLinestring);
    }
    return NO;
}

@end

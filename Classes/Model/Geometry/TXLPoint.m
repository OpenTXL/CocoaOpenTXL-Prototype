//
//  TXLPoint.m
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

#import "TXLPoint.h"


@implementation TXLPoint

@synthesize coordinate;

- (id)initWithLongitude:(double)lon latitude:(double)lat {
    if ((self = [super init])) {
        coordinate.longitude = lon;
        coordinate.latitude = lat;
    }
    return self;
}

- (id)initWithCoordinate:(TXLCoordinate)coord {
    if ((self = [super init])) {
        coordinate = coord;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TXLPoint class]]) {
        if (coordinate.longitude != ((TXLPoint *)object).coordinate.longitude)
            return NO;
        
        if (coordinate.latitude != ((TXLPoint *)object).coordinate.latitude)
            return NO;

        return YES;
    }
    return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"TXLPoint {longitude: %f, latitude: %f}", coordinate.longitude, coordinate.latitude];
}

@end

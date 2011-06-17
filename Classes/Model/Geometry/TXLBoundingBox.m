//
//  TXLBoundingBox.m
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

#import "TXLBoundingBox.h"


@implementation TXLBoundingBox

@synthesize minLongitude;
@synthesize maxLongitude;
@synthesize minLatitude;
@synthesize maxLatitude;

- (id)initWithMinLongitude:(double)minLon
              maxLongitude:(double)maxLon
               minLatitude:(double)minLat
               maxLatitude:(double)maxLat {
    if ((self = [super init])) {
        minLongitude = minLon;
        maxLongitude = maxLon;
        minLatitude = minLat;
        maxLatitude = maxLat;
    }
    return self;
}

@end

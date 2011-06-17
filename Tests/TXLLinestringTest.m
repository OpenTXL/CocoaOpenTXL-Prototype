//
//  TXLLinestringTest.m
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

#import "TXLLinestring.h"
#import "TXLPoint.h"
#import "TXLGeometryTypes.h"

@interface TXLLinestringTest : GHTestCase {
    
}

@end

@implementation TXLLinestringTest


- (void)testCreateLinestring {
    
    NSMutableArray *points = [NSMutableArray array];
    [points addObject:[[[TXLPoint alloc] initWithLongitude:10 latitude:15] autorelease]];
    [points addObject:[[[TXLPoint alloc] initWithLongitude:12 latitude:16] autorelease]];
    [points addObject:[[[TXLPoint alloc] initWithLongitude:15 latitude:17] autorelease]];
    
    TXLLinestring *line = [[TXLLinestring alloc] initWithPoints:points];
    
    GHAssertNotNil(line, nil);
    
    // check bbox
    GHAssertEquals(line.boundingBox.minLatitude, 15.0, nil);
    GHAssertEquals(line.boundingBox.maxLatitude, 17.0, nil);
    GHAssertEquals(line.boundingBox.minLongitude, 10.0, nil);
    GHAssertEquals(line.boundingBox.maxLongitude, 15.0, nil);
    
    // coords
    __block int i = 0;
    [line iterateOverPoints:^(TXLCoordinate coordinate, BOOL *stop){
        
        TXLCoordinate orig = [[points objectAtIndex:i] coordinate];
        
        GHAssertEquals(coordinate.latitude, orig.latitude, nil);
        GHAssertEquals(coordinate.longitude, orig.longitude, nil);
        
        i++;
    }];
    
    GHAssertEquals(i, 3, nil);
    
    [line release];
}

@end


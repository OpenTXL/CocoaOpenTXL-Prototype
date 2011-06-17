//
//  TXLPolygon.h
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

#import <Foundation/Foundation.h>

#import <spatialite/sqlite3.h>
#import <spatialite/gaiageo.h>
#import <spatialite.h>

#import "TXLGeometryTypes.h"
#import "TXLRing.h"

@interface TXLPolygon : NSObject {

@private
    gaiaPolygonPtr _polygon;
}

- (id)initWithExteriorRing:(TXLRing *)eR
             interiorRings:(NSArray *)iR;

#pragma mark -
#pragma mark Accessors

@property (readonly) TXLBoundingBox boundingBox;
@property (readonly) TXLRing *exteriorRing;
@property (readonly) NSArray *interiorRings;

- (void)iterateOverInteriorRings:(void(^)(TXLRing *ring, BOOL *stop))iterator;

#pragma mark -
#pragma mark Internal Methods

- (id)initWithGaiaPolygon:(gaiaPolygonPtr)ptr;
@property (readonly) gaiaPolygonPtr gaiaPolygon;

@end

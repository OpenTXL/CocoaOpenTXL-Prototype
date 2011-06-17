//
//  GaiaTest.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 21.10.10.
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

#import <spatialite/sqlite3.h>
#import <spatialite/gaiageo.h>
#import <spatialite.h>

@interface GaiaTest : GHTestCase {
    
}

@end

@implementation GaiaTest

- (void)testPoint {
    gaiaGeomCollPtr coll = gaiaParseWkt((const unsigned char *)"POINT(10 15)", GAIA_POINT);
    GHAssertNotNULL(coll, nil);
    GHAssertTrue(gaiaIsValid(coll), nil);
    gaiaFreeGeomColl(coll);
}

- (void)testMaxPolygon {
    gaiaGeomCollPtr coll = gaiaParseWkt((const unsigned char *)"POLYGON((-180 -90, 180 -90, 180 90, -180 90, -180 -90))", GAIA_POLYGON);
    GHAssertNotNULL(coll, @"%s", gaiaGetGeosErrorMsg());
    GHAssertTrue(gaiaIsValid(coll), nil);
    gaiaFreeGeomColl(coll);
}

@end

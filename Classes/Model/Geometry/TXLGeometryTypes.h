//
//  TXLGeometryTypes.h
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

#ifndef _TXL_GEOMETRY_TYPES_H_
#define _TXL_GEOMETRY_TYPES_H_

typedef struct TXLCoordinate_s {
    double latitude;
    double longitude;
} TXLCoordinate;

typedef struct TXLCoordinateSpan_s {
    double deltaLatitude;
    double deltaLongitude;
} TXLCoordinateSpan;

typedef struct TXLCoordinateRegion_s {
    TXLCoordinate center;
    TXLCoordinateSpan span;
} TXLCoordinateRegion;

typedef struct TXLBoundingBox_s {
    double minLatitude;
    double maxLatitude;
    double minLongitude;
    double maxLongitude;
} TXLBoundingBox;

// TODO: Define macros to create the structures above and to convert from a region to a bounding box and vice versa.

#endif // _TXL_GEOMETRY_TYPES_H_

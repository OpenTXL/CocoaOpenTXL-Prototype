//
//  TXLMovingObjectTestData.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 02.02.11.
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

#import "TXLMovingObject.h"
#import "TXLMovingObjectSequence.h"

@class TXLMovingObject;
@class TXLMovingObjectSequence;

@interface TXLMovingObjectTestData : NSObject {

}

#pragma mark -
#pragma mark Moving Objects

+ (TXLMovingObject *)a1;
+ (TXLMovingObject *)a2;
+ (TXLMovingObject *)a3;

+ (TXLMovingObject *)b1;
+ (TXLMovingObject *)b2;

+ (TXLMovingObject *)c1;

+ (TXLMovingObject *)d1;

+ (TXLMovingObject *)e1;

+ (TXLMovingObject *)f1;
+ (TXLMovingObject *)f2;
+ (TXLMovingObject *)f3;
+ (TXLMovingObject *)f4;

#pragma mark -
#pragma mark Moving Object Sequneces

+ (TXLMovingObjectSequence *)A;
+ (TXLMovingObjectSequence *)B;


#pragma mark -
#pragma mark Results

+ (TXLMovingObjectSequence *)union_A_B;

+ (TXLMovingObjectSequence *)union_a1_b1;

+ (TXLMovingObjectSequence *)union_a1_e1;

+ (TXLMovingObjectSequence *)intersection_A_B;

+ (TXLMovingObjectSequence *)intersection_a1_b1;

+ (TXLMovingObjectSequence *)intersection_c1_d1;

+ (TXLMovingObjectSequence *)intersection_a1_e1;

+ (TXLMovingObjectSequence *)intersection_f1_f2;

+ (TXLMovingObjectSequence *)intersection_f3_f4;

+ (TXLMovingObjectSequence *)complement_A_B;

+ (TXLMovingObjectSequence *)complement_c1_d1;

+ (TXLMovingObjectSequence *)complement_a1_e1;

+ (TXLMovingObject *)inInterval1;

+ (TXLMovingObjectSequence *)notInInterval1;

@end

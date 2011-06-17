//
//  TXLMovingObjectSequence.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 06.10.10.
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

extern NSString * const TXLMovingObjectSequenceErrorDomain;

#define TXL_MOVING_OBJECT_SEQUENCE_ERROR_EMPTY 1

@class TXLMovingObject;
@class TXLGeometryCollection;

@interface TXLMovingObjectSequence : NSObject {

@private
	NSUInteger primaryKey;
    
    NSDate *_begin;
    NSDate *_end;
    TXLGeometryCollection *_bounds;
    NSArray *_sequence;
    
    BOOL _loaded;
}

#pragma mark -
#pragma mark Autorelease Constructors

+ (TXLMovingObjectSequence *)emptySequence;

+ (TXLMovingObjectSequence *)sequenceWithMovingObject:(TXLMovingObject *)mo;

/*! Creates a moving object sequence by unifying the moving objects in the array.
 *
 *  Empty moving objects are ignored.
 *  If one moving object is omnipresent, only this moving object (the omnipresent)
 *  is in the sequence.
 */
+ (TXLMovingObjectSequence *)sequenceByUnifyingMovingObjects:(NSArray *)array;

#pragma mark -
#pragma mark Operations

- (TXLMovingObjectSequence *)intersectionWithMovingObject:(TXLMovingObject *)mo;
- (TXLMovingObjectSequence *)intersectionWithMovingObjectSequence:(TXLMovingObjectSequence *)mos;

- (TXLMovingObjectSequence *)unionWithMovingObject:(TXLMovingObject *)mo;
- (TXLMovingObjectSequence *)unionWithMovingObjectSequence:(TXLMovingObjectSequence *)mos;

- (TXLMovingObjectSequence *)complementWithMovingObject:(TXLMovingObject *)mo2;
- (TXLMovingObjectSequence *)complementWithMovingObjectSequnece:(TXLMovingObjectSequence *)mos;

#pragma mark -
#pragma mark Mask Operations

- (TXLMovingObjectSequence *)movingObjectSequenceInIntervalFrom:(NSDate *)from
                                                             to:(NSDate *)to;

- (TXLMovingObjectSequence *)movingObjectSequenceNotInIntervalFrom:(NSDate *)from
                                                                to:(NSDate *)to;

#pragma mark -
#pragma mark Predicates

@property (readonly, getter=isEmpty) BOOL empty;

#pragma mark -
#pragma mark Begin & End

@property (readonly) NSDate *begin;
@property (readonly) NSDate *end;

#pragma mark -
#pragma mark Bounds

@property (readonly) TXLGeometryCollection *bounds;
- (TXLGeometryCollection *)boundsAtDate:(NSDate *)date;
- (TXLGeometryCollection *)boundsInIntervalFrom:(NSDate *)from
                                             to:(NSDate *)to;

#pragma mark -
#pragma mark Sequence Objects

@property (readonly) NSArray *movingObjects;

#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Autorelease Constructors

+ (TXLMovingObjectSequence *)sequenceWithArray:(NSArray *)array;
+ (TXLMovingObjectSequence *)sequenceWithPrimaryKey:(NSUInteger)pk;

#pragma mark -
#pragma mark Database Management

@property (readonly) NSUInteger primaryKey;
- (TXLMovingObjectSequence *)save:(NSError **)error;

@end

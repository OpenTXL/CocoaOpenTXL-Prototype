//
//  TXLMovingObject.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 18.09.10.
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

extern NSString * const TXLMovingObjectErrorDomain;

#define TXL_MOVING_OBJECT_ERROR_EMPTY 1

@class TXLMovingObjectSequence;
@class TXLGeometryCollection;
@class TXLSnapshot;

@interface TXLMovingObject : NSObject {
    
@private
    NSUInteger primaryKey;
    
    BOOL _is_empty;
    NSDate *_begin;
    NSDate *_end;
    TXLGeometryCollection *_bounds;
    NSArray *_snapshots;
    
    BOOL _loaded;
}

#pragma mark -
#pragma mark Autorelease Constructors

/*! Create an empty moving object.
 */
+ (TXLMovingObject *)emptyMovingObject;

/*! Create an omnipresent moving object.
 *
 *  An omnipresent moving object is the exact
 *  opposite of an empty moving object.
 */
+ (TXLMovingObject *)omnipresentMovingObject;

/*! Create a moving object for the interval begin, end
 *  without spatial boundaries.
 *
 *  This moving object is in the specified interval
 *  everywhere valid.
 */
+ (TXLMovingObject *)movingObjectWithBegin:(NSDate *)begin
                                       end:(NSDate *)end;

/*! Create a moving object without temporal boundaries.
 *
 *  This moving object is in the specified geometry
 *  always valid.
 */
+ (TXLMovingObject *)movingObjectWithGeometry:(TXLGeometryCollection *)geometry;

/*! Create a moving object with one snapshot.
 *
 *  This method creates a moving object, containing two sanpshots. The snapshots
 *  are constructed with the timestamps begin and end and the geometry.
 */
+ (TXLMovingObject *)movingObjectWithGeometry:(TXLGeometryCollection *)geometry
                                        begin:(NSDate *)begin
                                          end:(NSDate *)end;

/*! Create a moving object from the list of snapshots.
 *
 *  Begin and end is set to the first and last timestamp
 *  in the list of snapshots.
 *
 *  The array must contain snapshots with ascending timestamps.
 *
 *  The first or last snapshot can have nil as timestamp to indicate
 *  that the moving object starts in the distant past or ends in
 *  the distant future.
 */
+ (TXLMovingObject *)movingObjectWithSnapshots:(NSArray *)snapshots;

#pragma mark -
#pragma mark Predicates

@property (readonly, getter=isEmpty) BOOL empty;
@property (readonly, getter=isOmnipresent) BOOL omnipresent;
@property (readonly, getter=isEverywhere) BOOL everywhere;
@property (readonly, getter=isAlways) BOOL always;
@property (readonly, getter=isConstant) BOOL constant;

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
#pragma mark Snapshots

@property (readonly) NSArray *snapshots;

#pragma mark -
#pragma mark Operations

- (TXLMovingObjectSequence *)intersectionWithMovingObject:(TXLMovingObject *)mo;
- (TXLMovingObjectSequence *)unionWithMovingObject:(TXLMovingObject *)mo;
- (TXLMovingObjectSequence *)complementWithMovingObject:(TXLMovingObject *)mo;

#pragma mark -
#pragma mark Mask Operations

- (TXLMovingObject *)movingObjectInIntervalFrom:(NSDate *)from
                                             to:(NSDate *)to;

- (TXLMovingObjectSequence *)movingObjectNotInIntervalFrom:(NSDate *)from
                                                        to:(NSDate *)to;

#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Autorelease Constructors

+ (TXLMovingObject *)movingObjectWithPrimaryKey:(NSUInteger)pk;

#pragma mark -
#pragma mark Database Management

@property (readonly) NSUInteger primaryKey;
- (TXLMovingObject *)save:(NSError **)error;

@end

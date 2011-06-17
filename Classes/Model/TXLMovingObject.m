//
//  TXLMovingObject.m
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

#import "TXLMovingObject.h"
#import "TXLMovingObjectSequence.h"
#import "TXLSnapshot.h"
#import "TXLGeometryCollection.h"
#import "TXLManager.h"
#import "TXLDatabase.h"
#import "TXLInteger.h"
#import "NSDate+Interval.h"

NSString * const TXLMovingObjectErrorDomain = @"org.opentxl.TXLMovingObjectErrorDomain";

typedef enum {
	kTXLMovingObjectOperationTypeUNION, 
	kTXLMovingObjectOperationTypeINTERSECT, 
	kTXLMovingObjectOperationTypeDIFFERENCE
} kTXLMovingObjectOperationType;

@interface TXLMovingObject ()

#pragma mark -
#pragma mark Internal Constructors

- (id)initEmptyMovingObject;
- (id)initOmnipresentMovingObject;
- (id)initWithBegin:(NSDate *)begin end:(NSDate *)end;
- (id)initWithGeometry:(TXLGeometryCollection *)geometry;
- (id)initWithGeometry:(TXLGeometryCollection *)geometry
                 begin:(NSDate *)begin
                   end:(NSDate *)end;
- (id)initWithSnapshots:(NSArray *)snapshots;

- (id)initWithPrimaryKey:(NSUInteger)pk;

#pragma mark -
#pragma mark Database Management

- (void)load;

@end


@implementation TXLMovingObject

@synthesize primaryKey;

#pragma mark -
#pragma mark Autorelease Constructors

+ (TXLMovingObject *)emptyMovingObject {
    return [[[TXLMovingObject alloc] initEmptyMovingObject] autorelease];
}

+ (TXLMovingObject *)omnipresentMovingObject {
    return [[[TXLMovingObject alloc] initOmnipresentMovingObject] autorelease];
}

+ (TXLMovingObject *)movingObjectWithBegin:(NSDate *)begin
                                       end:(NSDate *)end {
    return [[[TXLMovingObject alloc] initWithBegin:begin end:end] autorelease];
}

+ (TXLMovingObject *)movingObjectWithGeometry:(TXLGeometryCollection *)geometry {
    return [[[TXLMovingObject alloc] initWithGeometry:geometry] autorelease];
}

+ (TXLMovingObject *)movingObjectWithGeometry:(TXLGeometryCollection *)geometry
                                        begin:(NSDate *)begin
                                          end:(NSDate *)end {
    return [[[TXLMovingObject alloc] initWithGeometry:geometry begin:begin end:end] autorelease];
}

+ (TXLMovingObject *)movingObjectWithSnapshots:(NSArray *)snapshots {
    return [[[TXLMovingObject alloc] initWithSnapshots:snapshots] autorelease];
}

#pragma mark -
#pragma mark Empty or Omnipresent

- (BOOL)isEmpty {
    [self load];
    return _is_empty;
}

- (BOOL)isOmnipresent {
    [self load];
    return  (_is_empty == NO) &&
            (_begin == nil) &&
            (_end == nil) &&
            [_bounds isEqual:[TXLGeometryCollection geometryFromWKT:@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"]];
}

- (BOOL)isEverywhere {
    [self load];
    return  (_is_empty == NO) &&
            [_bounds isEqual:[TXLGeometryCollection geometryFromWKT:@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"]];
}

- (BOOL)isAlways {
    [self load];
    return  (_is_empty == NO) &&
            (_begin == nil) &&
            (_end == nil);
}

- (BOOL)isConstant {
    [self load];
    for (TXLSnapshot *s in _snapshots) {
        if (![_snapshots isEqual:_bounds])
            return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark Begin & End

- (NSDate *)begin {
    [self load];
    return _begin;
}

- (NSDate *)end {
    [self load];
    return _end;
}

#pragma mark -
#pragma mark Bounds

- (TXLGeometryCollection *)bounds {
    [self load];
    return _bounds;
}

- (TXLGeometryCollection *)boundsAtDate:(NSDate *)date {
    
    if (date == nil)
        return nil;
    
    [self load];
    
    if (_is_empty == NO) {
        
        if (![date inIntervalFrom:self.begin
                               to:self.end]) {
            return nil;
        }
        
        if ([_snapshots count] == 1) {
            TXLSnapshot *snap = [_snapshots objectAtIndex:0];
            if (snap.timestamp == nil || [snap.timestamp compare:date] == NSOrderedSame) {
                return snap.geometry;
            }
        }
        
        __block TXLGeometryCollection *b = nil;
        
        NSUInteger idx = [_snapshots indexOfObjectWithOptions:NSEnumerationReverse passingTest:^(id obj, NSUInteger idx, BOOL *stop){
            TXLSnapshot *snapshot = obj;
                
            if (snapshot.timestamp == nil) {
                if (idx == 0) {
                    // first snapshot in list
                    b = snapshot.geometry;
                    *stop = YES;
                    return YES;
                } else {
                    // last snapshot in list
                    return NO;
                }
            }

            if ([snapshot.timestamp earlierDate:date] == snapshot.timestamp) {
                b = snapshot.geometry;
                *stop = YES;
                return YES;
            } else {
                return NO;
            }
        }];
        
        if (idx == NSNotFound || ([_snapshots count] - 1 == idx &&
                                 [[_snapshots objectAtIndex:idx] timestamp] &&
                                  [[(TXLSnapshot *)[_snapshots objectAtIndex:idx] timestamp] compare:date] == NSOrderedSame)) {
            return nil;
        }
        
        return b;
    }
    return nil;
}

- (TXLGeometryCollection *)boundsInIntervalFrom:(NSDate *)from
                                             to:(NSDate *)to {
    [self load];
    
    if (_is_empty == NO) {
        
        if ([self.begin earlierDate:from] == from && [self.end laterDate:to] == to) {
            return self.bounds;
        }
        
        if (!(from != nil && [from inIntervalFrom:self.begin to:self.end]) &&
            !(to != nil && [to inIntervalFrom:self.begin to:self.end])) {
            return nil;
        }
        
        NSUInteger firstSnapshotIdx;
        NSUInteger lastSnapshotIdx;
        
        
        // find first snapshot after begin
        firstSnapshotIdx = [_snapshots indexOfObjectWithOptions:NSEnumerationReverse passingTest:^(id obj, NSUInteger idx, BOOL *stop){
            TXLSnapshot *snapshot = obj;
            
            if (snapshot.timestamp == nil) {
                if (idx == 0) {
                    // first snapshot in list
                    *stop = YES;
                    return YES;
                } else {
                    // last snapshot in list
                    return NO;
                }
            }
            
            if ([snapshot.timestamp laterDate:from] == from) {
                *stop = YES;
                return YES;
            } else {
                return NO;
            }
        }];
        
        // find first snapshot before end
        lastSnapshotIdx = [_snapshots indexOfObjectWithOptions:NSEnumerationReverse passingTest:^(id obj, NSUInteger idx, BOOL *stop){
            TXLSnapshot *snapshot = obj;
            
            if (snapshot.timestamp == nil) {
                if (idx == 0) {
                    // first snapshot in list
                    *stop = YES;
                    return YES;
                } else {
                    // last snapshot in list
                    return NO;
                }
            }
            
            if ([snapshot.timestamp laterDate:to] == to) {
                *stop = YES;
                return YES;
            } else {
                return NO;
            }                                  
        }];
        
        NSRange range;
        range.location = firstSnapshotIdx;
        range.length = lastSnapshotIdx - firstSnapshotIdx + 1;
                
        TXLGeometryCollection *b = nil;
        
        // Iterate over the snapshots and calculate
        // the bounds of this moving object
        for (TXLSnapshot *snapshot in [_snapshots subarrayWithRange:range]) {
            
            // calculate the union of the geometry of
            // this snapshot and the previous snapshot 
            if (b == nil) {
                b = snapshot.geometry;
            } else {
                b = [b union:snapshot.geometry];
            }
        }
        
        return b;

    }
    return nil;
}

#pragma mark -
#pragma mark Snapshots

- (NSArray *)snapshots {
    [self load];
    return _snapshots;
}

#pragma mark -
#pragma mark Equality

- (BOOL)isEqual:(id)object {
    
    // TODO: Double check comparison of two moving objects
    
    if ([object isKindOfClass:[TXLMovingObject class]]) {
        TXLMovingObject *other = object;
        
        if (self.empty && other.empty)
            return YES;
        
        if (self.omnipresent && other.omnipresent)
            return YES;
        
		if ((self.begin != nil && other.begin != nil) &&
            [self.begin compare:other.begin] != NSOrderedSame) 
            return NO;
        
        if ((self.begin == nil && other.begin != nil) ||
            (self.begin != nil && other.begin == nil))
            return NO;

		if ((self.end != nil && other.end != nil) &&
            [self.end compare:other.end] != NSOrderedSame)
            return NO;
		
        if ((self.end == nil && other.end != nil) ||
            (self.end != nil && other.end == nil))
            return NO;
        
        if (![self.bounds isEqual:other.bounds])
            return NO;
        
        if (![self.snapshots isEqual:other.snapshots])
            return NO;
        
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark Description

- (NSString *)description {
    [self load];
    return [NSString stringWithFormat:@"%@{snapshots = %@}", [super description], _snapshots];
}

#pragma mark -
#pragma mark Operations

- (TXLMovingObjectSequence *)intersectionWithMovingObject:(TXLMovingObject *)mo {
    return [[TXLMovingObjectSequence sequenceWithMovingObject:self] intersectionWithMovingObject:mo];
}

- (TXLMovingObjectSequence *)unionWithMovingObject:(TXLMovingObject *)mo {
    return [[TXLMovingObjectSequence sequenceWithMovingObject:self] unionWithMovingObject:mo];
}

- (TXLMovingObjectSequence *)complementWithMovingObject:(TXLMovingObject *)mo {
    return [[TXLMovingObjectSequence sequenceWithMovingObject:self] complementWithMovingObject:mo];
}

#pragma mark -
#pragma mark Mask Operations

- (TXLMovingObject *)movingObjectInIntervalFrom:(NSDate *)from
                                             to:(NSDate *)to {
    
    // handle special cases
    if (from == nil && to == nil) return self;
    if (self.empty) return self;
    
    [self load];
    
    NSMutableArray *result = [NSMutableArray array];
    TXLSnapshot *lastSnapshotBeforeInterval = nil;
    TXLSnapshot *lastSnapshotInInterval = nil;
    
    // Check if the snapshot is before (-2), at the beginning (-1), in (0),
    // at the end (1) or after (2) the interval (from, to). 
    int (^checkSnapshot)(int) = ^(int idx){
        TXLSnapshot *snapshot = [_snapshots objectAtIndex:idx];
        
        if (snapshot.timestamp == nil) {
            if ([_snapshots count] == 0) {
                return 0;
            } else if (idx == 0) {
                if (from == nil)
                    return 0;
                else
                    return -2;
            } else {
                if (to == nil)
                    return 0;
                else
                    return 2;
            }
        }
        
        if (from == nil) {
            switch ([to compare:snapshot.timestamp]) {
                case NSOrderedDescending:
                    return 0;
                    
                case NSOrderedSame:
                    return 1;
                    
                case NSOrderedAscending:
                    return 2;
   
                default:
                    break;
            }
        } else if (to == nil) {
            switch ([from compare:snapshot.timestamp]) {
                case NSOrderedAscending:
                    return 0;
                    
                case NSOrderedSame:
                    return 1;
                    
                case NSOrderedDescending:
                    return 2;
                    
                default:
                    break;
            }
        } else {
            switch ([from compare:snapshot.timestamp]) {
                case NSOrderedAscending:
                {
                    switch ([to compare:snapshot.timestamp]) {
                        case NSOrderedDescending:
                            return 0;
                            
                        case NSOrderedSame:
                            return 1;
                            
                        case NSOrderedAscending:
                            return 2;
                            
                        default:
                            break;
                    }
                }
                    
                case NSOrderedSame:
                    return -1;
                    
                case NSOrderedDescending:
                    return -2;
                    
                default:
                    break;
            }
            
        }
        return 0;
    };
    
    BOOL stop = NO;
    
    for (NSUInteger idx = 0; !stop && idx < [_snapshots count]; idx++) {
        switch (checkSnapshot(idx)) {
            case -2:
                // before interval
                lastSnapshotBeforeInterval = [_snapshots objectAtIndex:idx];
                break;
                
            case -1:
                // begin of interval
                [result addObject:[_snapshots objectAtIndex:idx]];
                lastSnapshotBeforeInterval = nil;
                break;
                
            case 1:
                // end of interval
                [result addObject:[_snapshots objectAtIndex:idx]];
                lastSnapshotInInterval = nil;
                break;
                
            case 2:
            {
                // after interval
                if (lastSnapshotInInterval != nil) {
                    [result addObject:[TXLSnapshot snapshotWithTimestamp:to
                                                                geometry:lastSnapshotInInterval.geometry]];
                    lastSnapshotInInterval = nil;
                }
                stop = YES;
                break;
            }
                
            case 0:
            default:
            {
                // in interval
                if (lastSnapshotBeforeInterval != nil) {
                    [result addObject:[TXLSnapshot snapshotWithTimestamp:from
                                                                geometry:lastSnapshotBeforeInterval.geometry]];
                    lastSnapshotBeforeInterval = nil;
                }
                
                TXLSnapshot *s = [_snapshots objectAtIndex:idx];
                lastSnapshotInInterval = s;
                [result addObject:s];
                break;
            }
        }
    }
    
    return [TXLMovingObject movingObjectWithSnapshots:result];
}

- (TXLMovingObjectSequence *)movingObjectNotInIntervalFrom:(NSDate *)from
                                                        to:(NSDate *)to {
    
    // handle special cases
    if (from == nil && to == nil)
        return [TXLMovingObjectSequence emptySequence];
    
    if (self.empty)
        return [TXLMovingObjectSequence emptySequence];
    
    [self load];
    
    NSMutableArray *resultSnapshots = [NSMutableArray array];
    NSMutableArray *resultObjects = [NSMutableArray array];
    TXLSnapshot *lastSnapshotBeforeInterval = nil;
    TXLSnapshot *lastSnapshotInInterval = nil;
    
    // Check if the snapshot is before (-2), at the beginning (-1), in (0),
    // at the end (1) or after (2) the interval (from, to). 
    int (^checkSnapshot)(int) = ^(int idx){
        TXLSnapshot *snapshot = [_snapshots objectAtIndex:idx];
        
        if (snapshot.timestamp == nil) {
            if ([_snapshots count] == 0) {
                return 0;
            } else if (idx == 0) {
                if (from == nil)
                    return 0; // It should be -1, but the implementation uses this workaround. 
                else
                    return -2;
            } else {
                if (to == nil)
                    return 0; // It should be 1, but the implementation uses this workaround.
                else
                    return 2;
            }
        }
        
        if (from == nil) {
            switch ([to compare:snapshot.timestamp]) {
                case NSOrderedDescending:
                    return 0;
                    
                case NSOrderedSame:
                    return 1;
                    
                case NSOrderedAscending:
                    return 2;
                    
                default:
                    break;
            }
        } else if (to == nil) {
            switch ([from compare:snapshot.timestamp]) {
                case NSOrderedAscending:
                    return 0;
                    
                case NSOrderedSame:
                    return 1;
                    
                case NSOrderedDescending:
                    return 2;
                    
                default:
                    break;
            }
        } else {
            switch ([from compare:snapshot.timestamp]) {
                case NSOrderedAscending:
                {
                    switch ([to compare:snapshot.timestamp]) {
                        case NSOrderedDescending:
                            return 0;
                            
                        case NSOrderedSame:
                            return 1;
                            
                        case NSOrderedAscending:
                            return 2;
                            
                        default:
                            break;
                    }
                }
                    
                case NSOrderedSame:
                    return -1;
                    
                case NSOrderedDescending:
                    return -2;
                    
                default:
                    break;
            }
            
        }
        return 0;
    };
    
    for (NSUInteger idx = 0; idx < [_snapshots count]; idx++) {
        switch (checkSnapshot(idx)) {
            case -2:
                // before interval
                lastSnapshotBeforeInterval = [_snapshots objectAtIndex:idx];
                [resultSnapshots addObject:lastSnapshotBeforeInterval];
                break;
                
            case -1:
            {
                // begin of interval
                [resultSnapshots addObject:[_snapshots objectAtIndex:idx]];
                lastSnapshotBeforeInterval = nil;
                if ([resultSnapshots count] > 0) {
                    [resultObjects addObject:[TXLMovingObject movingObjectWithSnapshots:resultSnapshots]];
                    resultSnapshots = [NSMutableArray array];
                }
                break;
            }
                
            case 1:
                // end of interval
                [resultSnapshots addObject:[_snapshots objectAtIndex:idx]];
                lastSnapshotInInterval = nil;
                break;
                
            case 2:
            {
                // after interval
                if (lastSnapshotInInterval != nil) {
                    [resultSnapshots addObject:[TXLSnapshot snapshotWithTimestamp:to
                                                                geometry:lastSnapshotInInterval.geometry]];
                    lastSnapshotInInterval = nil;
                }
                [resultSnapshots addObject:[_snapshots objectAtIndex:idx]];
                break;
            }
                
            case 0:
            default:
            {
                // in interval
                if (lastSnapshotBeforeInterval != nil) {
                    [resultSnapshots addObject:[TXLSnapshot snapshotWithTimestamp:from
                                                                geometry:lastSnapshotBeforeInterval.geometry]];
                    lastSnapshotBeforeInterval = nil;
                    if ([resultSnapshots count] > 0) {
                        [resultObjects addObject:[TXLMovingObject movingObjectWithSnapshots:resultSnapshots]];
                        resultSnapshots = [NSMutableArray array];
                    }
                }
                
                lastSnapshotInInterval = [_snapshots objectAtIndex:idx];
                break;
            }
        }
    }
    
    if ([resultSnapshots count] > 0) {
        [resultObjects addObject:[TXLMovingObject movingObjectWithSnapshots:resultSnapshots]];
    }
    
    return [TXLMovingObjectSequence sequenceWithArray:resultObjects];
}

#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Autorelease Constructors

+ (TXLMovingObject *)movingObjectWithPrimaryKey:(NSUInteger)pk {
    return [[[TXLMovingObject alloc] initWithPrimaryKey:pk] autorelease];
}

#pragma mark -
#pragma mark Database Management

- (TXLMovingObject *)save:(NSError **)error {
    @synchronized (self) {
        if (primaryKey != 0)
            return self;
        
        if (_is_empty) {
            if (error != nil) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Can not save an empty moving object.", nil)
                                                                     forKey:NSLocalizedDescriptionKey];
                
                *error = [NSError errorWithDomain:TXLMovingObjectErrorDomain
                                             code:TXL_MOVING_OBJECT_ERROR_EMPTY
                                         userInfo:userInfo];
            }
            return nil;
        }
        
        TXLDatabase *db = [[TXLManager sharedManager] database];
        
        NSMutableArray *parameters = [NSMutableArray array];
        
        if (_begin) {
            [parameters addObject:[NSNumber numberWithDouble:[_begin timeIntervalSince1970]]];
        } else {
            [parameters addObject:[NSNull null]];
        }
        
        if (_end) {
            [parameters addObject:[NSNumber numberWithDouble:[_end timeIntervalSince1970]]];
        } else {
            [parameters addObject:[NSNull null]];
        }
        
        if (_bounds) {
            TXLGeometryCollection *bounds = [_bounds save:error];
            if (bounds == nil) {
                return nil;
            }
            [parameters addObject:[TXLInteger integerWithValue:bounds.primaryKey]];
        } else {
            [parameters addObject:[NSNull null]];
        }
        
        if ([db executeSQL:@"INSERT INTO txl_movingobject (begin, end, bounds) VALUES (?, ?, ?)"
            withParameters:parameters
                     error:error] == nil) {
            return nil;
        } else {
            
            primaryKey = db.lastInsertRowid;
            
            int count = 0;
            
            
            for (TXLSnapshot *snapshot in _snapshots) {
                NSAutoreleasePool *pool = [NSAutoreleasePool new];
                
                TXLGeometryCollection *geom = [snapshot.geometry save:error];
                if (geom == nil) {
                    [pool drain];
                    return nil;
                } else {
                    NSArray *parameter = nil;
                    
                    if (snapshot.timestamp) {
                        parameter = [NSArray arrayWithObjects:[TXLInteger integerWithValue:primaryKey],
                                     [TXLInteger integerWithValue:geom.primaryKey],
                                     [NSNumber numberWithDouble:[snapshot.timestamp timeIntervalSince1970]],
                                     [TXLInteger integerWithValue:count],
                                     nil];
                    } else {
                        parameter = [NSArray arrayWithObjects:[TXLInteger integerWithValue:primaryKey],
                                     [TXLInteger integerWithValue:geom.primaryKey],
                                     [NSNull null],
                                     [TXLInteger integerWithValue:count],
                                     nil];
                    }
                    
                    if ([db executeSQL:@"INSERT INTO txl_snapshot (movingobject_id, geometry_id, timestamp, count) VALUES (?, ?, ?, ?)"
                        withParameters:parameter
                                 error:error] == nil) {
                        [pool drain];
                        return nil;
                    }
                    
                    count++;
                    [pool drain];
                }
            }
            
        }
    }
    return self;
}

#pragma mark -
#pragma mark -
#pragma mark Private Methods

#pragma mark -
#pragma mark Internal Constructors & Destructor

- (id)initEmptyMovingObject {
    if ((self = [super init])) {
        _is_empty = YES;
        _loaded = YES;
    }
    return self;
}

- (id)initOmnipresentMovingObject {
    if ((self = [super init])) {
        _loaded = YES;
        _bounds = [[TXLGeometryCollection geometryFromWKT:@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"] retain];
        _snapshots = [[NSArray arrayWithObjects:
                       [TXLSnapshot snapshotWithTimestamp:nil geometry:_bounds],
                       [TXLSnapshot snapshotWithTimestamp:nil geometry:_bounds],
                       nil] retain];
    }
    return self;
}

- (id)initWithBegin:(NSDate *)begin
                end:(NSDate *)end {
    if ((self = [super init])) {
        _begin = [begin retain];
        _end = [end retain];
        _loaded = YES;
        _bounds = [[TXLGeometryCollection geometryFromWKT:@"POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))"] retain];
        _snapshots = [[NSArray arrayWithObjects:
                       [TXLSnapshot snapshotWithTimestamp:_begin geometry:_bounds],
                       [TXLSnapshot snapshotWithTimestamp:_end geometry:_bounds],
                       nil] retain];
    }
    return self;
}

- (id)initWithGeometry:(TXLGeometryCollection *)geometry {
    if ((self = [super init])) {
        _bounds = [geometry retain];
        _loaded = YES;
        _snapshots = [[NSArray arrayWithObjects:
                       [TXLSnapshot snapshotWithTimestamp:nil geometry:_bounds],
                       [TXLSnapshot snapshotWithTimestamp:nil geometry:_bounds],
                       nil] retain];
    }
    return self;
}

- (id)initWithGeometry:(TXLGeometryCollection *)geometry
                 begin:(NSDate *)begin
                   end:(NSDate *)end {
    if ((self = [super init])) {
        _begin = [begin retain];
        _end = [end retain];
        _bounds = [geometry retain];
        _loaded = YES;
        _snapshots = [[NSArray arrayWithObjects:
                       [TXLSnapshot snapshotWithTimestamp:_begin geometry:_bounds],
                       [TXLSnapshot snapshotWithTimestamp:_end geometry:_bounds],
                       nil] retain];
    }
    return self;
}

- (id)initWithSnapshots:(NSArray *)snapshots {
    if ((self = [super init])) {
        _snapshots = [snapshots copy];
        
        // Iterate over the snapshots and calculate begin,
        // end and the bounds of this moving object
        
        NSDate *begin = nil;
        NSDate *end = nil;
        TXLGeometryCollection *bounds = nil;
        
		//TODO: needs revising
		// find the begin and end
        // we assume that the snapshots are sorted temporally
		if([snapshots count] > 0){
			begin = [(TXLSnapshot *)[snapshots objectAtIndex:0] timestamp];			
		} else {
			begin = nil;
		}
		if([snapshots count] > 1){
			end = [(TXLSnapshot *)[snapshots lastObject] timestamp];			
		} else {
			end = nil;
		}
				
        for (TXLSnapshot *snapshot in _snapshots) {
            
            // find the earliest timestamp
            // in the list of snapshots
            /*
			if (begin) {
                begin = [snapshot.timestamp earlierDate:begin];
            } else {
                begin = snapshot.timestamp;
            }
            
            // find the latest timestamp
            // in the list of snapshots
            if (end) {
                end = [snapshot.timestamp laterDate:end];
            } else {
                end = snapshot.timestamp;
            }
            */
			
            // calculate the union of the geometry of
            // this snapshot and the previous snapshot 
            if (bounds == nil) {
                bounds = snapshot.geometry;
            } else if ([_snapshots lastObject] != snapshot) {
                bounds = [bounds union:snapshot.geometry];
            }
        } 
        
        // set begin, end and the bounds
        // for this moving object
        _begin = [begin retain];
        _end = [end retain];
        _bounds = [bounds retain];
        _loaded = YES;
    }
    return self;
}

- (id)initWithPrimaryKey:(NSUInteger)pk {
    if ((self = [super init])) {
        primaryKey = pk;
    }
    return self;
}

- (void)dealloc {
    [_begin release];
    [_end release];
    [_bounds release];
    [_snapshots release];
    [super dealloc];
}

#pragma mark -
#pragma mark Database Management

- (void)load {
    @synchronized (self) {
        if (_loaded)
            return;
        
        _loaded = YES;
        
        TXLDatabase *db = [[TXLManager sharedManager] database];
        NSError *error;
        
        NSArray *result = [db executeSQLWithParameters:@"SELECT begin, end, bounds FROM txl_movingobject WHERE id = ?" error:&error,
                           [TXLInteger integerWithValue:primaryKey],
                           nil];
        if (!result) {
            [[NSException exceptionWithName:@"TXLMovingObjectException"
                                    reason:[error localizedDescription]
                                  userInfo:nil] raise];
        }
        
        if ([result count] == 0) {
            [[NSException exceptionWithName:@"TXLMovingObjectException"
                                     reason:[NSString stringWithFormat:NSLocalizedString(@"Moving object with primary key '%d' does not exists.", nil), primaryKey]
                                   userInfo:nil] raise];
        }
        
        NSNumber *begin_seconds = [[result objectAtIndex:0] objectForKey:@"begin"];
        if ([begin_seconds isKindOfClass:[NSNumber class]]) {
            _begin = [[NSDate dateWithTimeIntervalSince1970:[begin_seconds doubleValue]] retain];
        }
        
        NSNumber *end_seconds = [[result objectAtIndex:0] objectForKey:@"end"];
        if ([end_seconds isKindOfClass:[NSNumber class]]) {
            _end = [[NSDate dateWithTimeIntervalSince1970:[end_seconds doubleValue]] retain];
        }
        
        TXLInteger *geo_pk = [[result objectAtIndex:0] objectForKey:@"bounds"];
        if ([geo_pk isKindOfClass:[TXLInteger class]] && geo_pk.integerValue != 0) {
            _bounds = [[TXLGeometryCollection geometryWithPrimaryKey:geo_pk.integerValue] retain];
        }
        
        NSArray *parameters = [[NSArray arrayWithObject:[TXLInteger integerWithValue:primaryKey]] retain];
        NSMutableArray *snapshots = [NSMutableArray new];
        
        if (![db executeSQL:@"SELECT geometry_id, timestamp FROM txl_snapshot WHERE movingobject_id = ? ORDER BY count"
             withParameters:parameters
                      error:&error
              resultHandler:^(NSDictionary *row, BOOL *stop){
                  NSNumber *timestamp_seconds = [row objectForKey:@"timestamp"];
                  NSDate *timestamp = nil;
                  if ([timestamp_seconds isKindOfClass:[NSNumber class]]) {
                      timestamp = [[NSDate dateWithTimeIntervalSince1970:[timestamp_seconds doubleValue]] retain];
                  }
                  
                  TXLInteger *geo_pk = [row objectForKey:@"geometry_id"];
                  TXLGeometryCollection *geometry = nil;
                  if ([geo_pk isKindOfClass:[TXLInteger class]] && geo_pk.integerValue != 0) {
                      geometry = [[TXLGeometryCollection geometryWithPrimaryKey:geo_pk.integerValue] retain];
                  }
                  
                  TXLSnapshot *snapshot = [[TXLSnapshot snapshotWithTimestamp:timestamp geometry:geometry] retain];
                  [snapshots addObject:snapshot];
                  
                  [snapshot release];
                  [geometry release];
                  [timestamp release];
        }]){
            [[NSException exceptionWithName:@"TXLMovingObjectException"
                                     reason:[error localizedDescription]
                                   userInfo:nil] raise];
        }
        
        [parameters release];
        
        if ([snapshots count] == 0) {
            [snapshots release];
        } else {
            _snapshots = snapshots;
        }
    }
}

@end

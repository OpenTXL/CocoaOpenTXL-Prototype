//
//  TXLMovingObjectSequence.m
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

#import "TXLMovingObjectSequence.h"
#import "TXLMovingObject.h"
#import "TXLGeometryCollection.h"
#import "TXLSnapshot.h"
#import "TXLManager.h"
#import "TXLDatabase.h"
#import "TXLInteger.h"

NSString * const TXLMovingObjectSequenceErrorDomain = @"org.opentxl.TXLMovingObjectSequenceErrorDomain";

@interface TXLMovingObjectSequence ()

#pragma mark -
#pragma mark Internal Constructors

- (id)initWithArray:(NSArray *)array;
- (id)initWithPrimaryKey:(NSUInteger)pk;

#pragma mark -
#pragma mark Database Management

- (void)load;

#pragma mark -
#pragma mark Sweep Line Operation

- (TXLMovingObjectSequence *)generateSequenceWithMovingObject:(TXLMovingObjectSequence *)mos
                                               usingOperation:(TXLGeometryCollection  * (^)(TXLGeometryCollection *, TXLGeometryCollection *))operation;

@end


@implementation TXLMovingObjectSequence

@synthesize primaryKey;


#pragma mark -
#pragma mark Autorelease Constructors

+ (TXLMovingObjectSequence *)emptySequence {
    return [[[TXLMovingObjectSequence alloc] initWithArray:[NSArray array]] autorelease];
}

+ (TXLMovingObjectSequence *)sequenceWithMovingObject:(TXLMovingObject *)mo {
    return [[[TXLMovingObjectSequence alloc] initWithArray:[NSArray arrayWithObject:mo]] autorelease];
}

+ (TXLMovingObjectSequence *)sequenceByUnifyingMovingObjects:(NSArray *)array {
    
    TXLMovingObjectSequence *result = [TXLMovingObjectSequence emptySequence];
    
    for (TXLMovingObject *mo in array) {
        result = [result unionWithMovingObject:mo];
    }
    
    return result;
}

#pragma mark -
#pragma mark Operations

- (TXLMovingObjectSequence *)intersectionWithMovingObject:(TXLMovingObject *)mo {
    return [self generateSequenceWithMovingObject:[TXLMovingObjectSequence sequenceWithMovingObject:mo]
                                   usingOperation:^(TXLGeometryCollection *left, TXLGeometryCollection *right) {
                                       if (left == nil)
                                           return (TXLGeometryCollection *)nil;
                                       if (right == nil)
                                           return (TXLGeometryCollection *)nil;
                                       return [left intersection:right];
                                   }];
}

- (TXLMovingObjectSequence *)intersectionWithMovingObjectSequence:(TXLMovingObjectSequence *)mos {
    return [self generateSequenceWithMovingObject:mos
                                   usingOperation:^(TXLGeometryCollection *left, TXLGeometryCollection *right) {
                                       if (left == nil)
                                           return (TXLGeometryCollection *)nil;
                                       if (right == nil)
                                           return (TXLGeometryCollection *)nil;
                                       return [left intersection:right];
                                   }];
}

- (TXLMovingObjectSequence *)unionWithMovingObject:(TXLMovingObject *)mo {
    return [self generateSequenceWithMovingObject:[TXLMovingObjectSequence sequenceWithMovingObject:mo]
                                   usingOperation:^(TXLGeometryCollection *left, TXLGeometryCollection *right) {
                                       if (left == nil) return right;
                                       if (right == nil) return left;
                                       return [left union:right];
                                   }];
}

- (TXLMovingObjectSequence *)unionWithMovingObjectSequence:(TXLMovingObjectSequence *)mos {
    return [self generateSequenceWithMovingObject:mos
                                   usingOperation:^(TXLGeometryCollection *left, TXLGeometryCollection *right) {
                                       if (left == nil) return right;
                                       if (right == nil) return left;
                                       return [left union:right];
                                   }];
}

- (TXLMovingObjectSequence *)complementWithMovingObject:(TXLMovingObject *)mo {
    return [self generateSequenceWithMovingObject:[TXLMovingObjectSequence sequenceWithMovingObject:mo]
                                   usingOperation:^(TXLGeometryCollection *left, TXLGeometryCollection *right) {
                                       if (left == nil || right == nil) return left;
                                       return [left difference:right];
                                   }];
}

- (TXLMovingObjectSequence *)complementWithMovingObjectSequnece:(TXLMovingObjectSequence *)mos {
    return [self generateSequenceWithMovingObject:mos
                                   usingOperation:^(TXLGeometryCollection *left, TXLGeometryCollection *right) {
                                       if (left == nil || right == nil) return left;
                                       return [left difference:right];
                                   }];
}

#pragma mark -
#pragma mark Mask Operations

- (TXLMovingObjectSequence *)movingObjectSequenceInIntervalFrom:(NSDate *)from
                                                             to:(NSDate *)to {
    NSMutableArray *resultSequence = [NSMutableArray array];
    
    for (TXLMovingObject *mo in self.movingObjects) {
        [resultSequence addObject:[mo movingObjectInIntervalFrom:from to:to]];
    }
    
    return [TXLMovingObjectSequence sequenceWithArray:resultSequence];
}

- (TXLMovingObjectSequence *)movingObjectSequenceNotInIntervalFrom:(NSDate *)from
                                                                to:(NSDate *)to {

    NSMutableArray *resultSequence = [NSMutableArray array];
    
    for (TXLMovingObject *mo in self.movingObjects) {
        [resultSequence addObjectsFromArray:[mo movingObjectNotInIntervalFrom:from
                                                                           to:to].movingObjects];
    }
    
    return [TXLMovingObjectSequence sequenceWithArray:resultSequence];
}

#pragma mark -
#pragma mark Predicates

- (BOOL)isEmpty {
    [self load];
    return [_sequence count] == 0;
}

#pragma mark -
#pragma mark Begin & End

- (NSDate *)begin {
    @synchronized (_begin) {
        if (_begin == nil) {
            [self load];
            if ([_sequence count] > 0) {
                TXLMovingObject *mo = [_sequence objectAtIndex:0];
                _begin = [mo.begin retain];
            }
        }
    }
    return _begin;
}

- (NSDate *)end {
    @synchronized (_end) {
        if (_end == nil) {
            [self load];
            if ([_sequence count] > 0) {
                TXLMovingObject *mo = [_sequence lastObject];
                _end = [mo.end retain];
            }
        }        
    }
    return _end;
}

#pragma mark -
#pragma mark Sequence Objects

- (NSArray *)movingObjects {
    [self load];
    return _sequence;
}

#pragma mark -
#pragma mark Bounds

- (TXLGeometryCollection *)bounds {
    @synchronized (_bounds) {
        if (_bounds == nil) {
            [self load];
            TXLGeometryCollection *g = nil;
            for (TXLMovingObject *mo in _sequence) {
                if (g) {
                    g = [g union:mo.bounds];
                } else {
                    g = mo.bounds;
                }
            }
            _bounds = [g retain];
        }        
    }
    return _bounds;
}

- (TXLGeometryCollection *)boundsAtDate:(NSDate *)date {
    return nil;
}

- (TXLGeometryCollection *)boundsInIntervalFrom:(NSDate *)from
                                             to:(NSDate *)to {
    return nil;
}

#pragma mark -
#pragma mark Equality

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TXLMovingObjectSequence class]]) {
        TXLMovingObjectSequence *other = object;
        return [self.movingObjects isEqual:other.movingObjects];
    }
    return NO;
}

#pragma mark -
#pragma mark Description

- (NSString *)description {
    return [[[NSString stringWithFormat:@"%@{sequence = %@}", [super description], self.movingObjects] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"] stringByReplacingOccurrencesOfString:@"\\" withString:@""];
}

#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Autorelease Constructors

+ (TXLMovingObjectSequence *)sequenceWithArray:(NSArray *)array {
    return [[[TXLMovingObjectSequence alloc] initWithArray:array] autorelease];
}

+ (TXLMovingObjectSequence *)sequenceWithPrimaryKey:(NSUInteger)pk {
    return [[[TXLMovingObjectSequence alloc] initWithPrimaryKey:pk] autorelease];
}

#pragma mark -
#pragma mark Database Management

- (TXLMovingObjectSequence *)save:(NSError **)error {
    @synchronized (self) {
        if (primaryKey != 0)
            return self;
        
        if (_sequence == nil || [_sequence count] == 0) {
            if (error != nil) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Can not save an empty moving object sequence.", nil)
                                                                     forKey:NSLocalizedDescriptionKey];
                
                *error = [NSError errorWithDomain:TXLMovingObjectErrorDomain
                                             code:TXL_MOVING_OBJECT_ERROR_EMPTY
                                         userInfo:userInfo];
            }
            return nil;
        }
        
        TXLDatabase *db = [[TXLManager sharedManager] database];
        
        if ([db executeSQL:@"INSERT INTO txl_movingobjectsequence DEFAULT VALUES"
                     error:error] == nil) {
            return nil;
        }
        
        primaryKey = db.lastInsertRowid;
        
        int count = 0;
        
        for (TXLMovingObject *_mo in _sequence) {
            
            TXLMovingObject *mo = [_mo save:error];
            if (mo == nil) {
                return nil;
            }
            
            NSArray *parameter = [NSArray arrayWithObjects:
                                  [TXLInteger integerWithValue:count],
                                  [TXLInteger integerWithValue:primaryKey],
                                  [TXLInteger integerWithValue:mo.primaryKey],
                                  nil];
            
            if ([db executeSQL:@"INSERT INTO txl_movingobjectsequence_movingobject (count, sequence_id, movingobject_id) VALUES (?, ?, ?)"
                withParameters:parameter
                         error:error] == nil) {
                return nil;
            }
            
            count++;
        }
    }
    return self;
}

#pragma mark -
#pragma mark -
#pragma mark Private Methods

#pragma mark -
#pragma mark Internal Constructors & Destructor

- (id)initWithArray:(NSArray *)array {
    if (self = [super init]) {
        
        NSMutableArray *s = [NSMutableArray new];
        
        for (TXLMovingObject *mo in array) {
            if (mo.empty)
                continue;
            
            [s addObject:mo];
        }
        
        _sequence = s;
    }
    return self;
}

- (id)initWithPrimaryKey:(NSUInteger)pk {
    if (self = [super init]) {
        primaryKey = pk;
    }
    return self;
}

- (void)dealloc {
    [_begin release];
    [_end release];
    [_bounds release];
    [_sequence release];
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
        
        TXLInteger *mos_pk = [[TXLInteger integerWithValue:primaryKey] retain];
        NSArray *parameter = [[NSArray alloc] initWithObjects:mos_pk, nil];
        [mos_pk release];
        
        NSMutableArray *sequence = [NSMutableArray new];
        
        if (![db executeSQL:@"SELECT movingobject_id FROM txl_movingobjectsequence_movingobject WHERE sequence_id = ? ORDER BY count"
             withParameters:parameter
                      error:&error
              resultHandler:^(NSDictionary *row, BOOL *stop){
                  
                  TXLInteger *mo_pk = [[row objectForKey:@"movingobject_id"] retain];
                  
                  if ([mo_pk isKindOfClass:[TXLInteger class]] && mo_pk.integerValue != 0) {
                      
                      TXLMovingObject *mo = [[TXLMovingObject movingObjectWithPrimaryKey:mo_pk.integerValue] retain];
                      [sequence addObject:mo];
                      [mo release];
                      
                  } else {
                      [[NSException exceptionWithName:@"TXLMovingObjectException"
                                               reason:[NSString stringWithFormat:NSLocalizedString(@"Moving object with primary key (%d) for sequence (%d) does not exist.", nil), mo_pk.integerValue, primaryKey]
                                             userInfo:nil] raise];
                  }
                  
                  [mo_pk release];
                  
              }]){
                  [[NSException exceptionWithName:@"TXLMovingObjectException"
                                           reason:[error localizedDescription]
                                         userInfo:nil] raise];
              }
        
        if ([sequence count] > 0) {
            _sequence = sequence;
        } else {
            [sequence release];
        }
        
        [parameter release];
    }
}

#pragma mark -
#pragma mark Sweep Line Operation

// A sweep line style algorithm for bilding a moving object sequence
// from two moving objects by applying an operation. The algorithm uses
// a constant interpolation. A Snapshot is valid up to the next snapshot
// in the list of snapshots of the moving object.
- (TXLMovingObjectSequence *)generateSequenceWithMovingObject:(TXLMovingObjectSequence *)mos
                                               usingOperation:(TXLGeometryCollection *(^)(TXLGeometryCollection *, TXLGeometryCollection *))operation {
    
    __block NSMutableArray *resultSequence = [NSMutableArray array];
    __block NSMutableArray *resultSnapshots = [NSMutableArray array];
    
    NSArray *leftSequence = self.movingObjects;
    __block NSArray *leftSnapshots = nil;
    NSUInteger leftSequenceIdx = 0;
    __block TXLGeometryCollection *leftGeometry = nil;

    NSArray *rightSequence = mos.movingObjects;
    __block NSArray *rightSnapshots = nil;
    NSUInteger rightSequenceIdx = 0;
    __block TXLGeometryCollection *rightGeometry = nil;
    
    __block NSUInteger leftIdx = 0;
    __block NSUInteger rightIdx = 0;
    
    if ([leftSequence count] > leftSequenceIdx) {
        leftSnapshots = [[leftSequence objectAtIndex:leftSequenceIdx] snapshots];
        leftSequenceIdx++;
    }
    
    if ([rightSequence count] > rightSequenceIdx) {
        rightSnapshots = [[rightSequence objectAtIndex:rightSequenceIdx] snapshots];
        rightSequenceIdx++;
    }
    
    // Function to check which of the pending snapshots in the arrays of the
    // left and right moving objects has a earlier date.
    //
    // Result:
    //  -1 -> left
    //   0 -> same
    //   1 -> right
    int (^nextSnapshot)() = ^{
        
        // both arrays are empty.
        // this should never happen.
        if (leftIdx >= [leftSnapshots count] && rightIdx >= [rightSnapshots count])
            return 0; // ???
        
        // left array of snapshots is empty
        if (leftIdx >= [leftSnapshots count])
            return 1; // right
        
        // right array of snapshots is empty
        if (rightIdx >= [rightSnapshots count])
            return -1; // left
        
        TXLSnapshot *l = [leftSnapshots objectAtIndex:leftIdx];
        TXLSnapshot *r = [rightSnapshots objectAtIndex:rightIdx];
        
        // both snapshots have a timestamp of -inf
        if (l.timestamp == nil && leftIdx == 0 && r.timestamp == nil && rightIdx == 0)
            return 0; // same
        
        // both snapshots have a timestamp of +inf
        if (l.timestamp == nil && leftIdx > 0 && r.timestamp == nil && rightIdx > 0)
            return 0; // same
        
        // the left snapshot has a timestamp of -inf
        if (l.timestamp == nil && leftIdx == 0)
            return -1; // left
        
        // the right snapshot has a timestamp of -inf
        if (r.timestamp == nil && rightIdx == 0)
            return 1; // right
        
        // the left snapshot has a timestamp of +inf
        if (l.timestamp == nil && leftIdx > 0)
            return 1; // left
        
        // the right snapshot has a timestamp of +inf
        if (r.timestamp == nil && rightIdx > 0)
            return -1; // right
        
        switch ([l.timestamp compare:r.timestamp]) {
            case NSOrderedSame:
                return 0;
            case NSOrderedAscending:
                return -1;
            case NSOrderedDescending:
                return 1;
            default:
                return 0;
        }
        
        return 0;
    };
    
    // Function to generate the resulting geometry by applying the operation
    // to the current left and right geometry.
    //
    // If the resulting geometry is not nil or not empty, create
    // a snapshot with the given timestamp and append it ad the
    // end of the result snapshots.
    // Otherwise create a moving object out of the collected snapshots
    // and append it to at the result sequence. 
    void (^createSnapshot)(NSDate *) = ^(NSDate *timestamp){
        TXLGeometryCollection *geom = operation(leftGeometry, rightGeometry);
        if (geom && geom.empty == NO) {
            [resultSnapshots addObject:[TXLSnapshot snapshotWithTimestamp:timestamp
                                                                 geometry:geom]];
        } else {
            if ([resultSnapshots count] > 0) {
                // Add a snapshot to cover the time until this timestamp.
                TXLSnapshot *snapshot = [resultSnapshots lastObject];
                if( (timestamp != nil) &&
                    ([snapshot.timestamp earlierDate:timestamp] == snapshot.timestamp) &&
                    (snapshot.timestamp != timestamp) ){
                    [resultSnapshots addObject:[TXLSnapshot snapshotWithTimestamp:timestamp
                                                                         geometry:snapshot.geometry]];
                }
                [resultSequence addObject:[TXLMovingObject movingObjectWithSnapshots:resultSnapshots]];
                resultSnapshots = [NSMutableArray array];
            }
        }
    };
    
    // Iterate over the snapshots of the left and right moving object.
    // Use the function nextSnapshot to check which snapshot schould
    // be processed next (next in time). Then update the left or right
    // geometry and create a new snapshot.
    while ([leftSnapshots count] > leftIdx || [rightSnapshots count] > rightIdx) {
        
        switch (nextSnapshot()) {
            case -1: // left
            {
                
                TXLSnapshot *l = [leftSnapshots objectAtIndex:leftIdx];
                
                // Create a snapshot before the left moving object starts.
                if (leftIdx == 0 && rightIdx != 0) {
                    // left snapshot is first
                    createSnapshot(l.timestamp);
                }
                
                // Create the next snapshot.
                leftGeometry = l.geometry;
                createSnapshot(l.timestamp);
                
                
                if (leftIdx + 1 == [leftSnapshots count]) {
                    if (l.timestamp != nil) {
                        // Reset the geometry of the left moving object.
                        leftGeometry = nil;
                        // Create the snapshot after the left moving object.
                        createSnapshot(l.timestamp);
                    }
                    
                    if (leftSequenceIdx < [leftSequence count]) {
                        leftSnapshots = [[leftSequence objectAtIndex:leftSequenceIdx] snapshots];
                        leftSequenceIdx++;
                        leftIdx = 0;
                    } else {
                        leftIdx++;
                    }
                } else {
                    leftIdx++;
                }
                break;
            }
                
            case 1: // right
            {
                
                TXLSnapshot *r = [rightSnapshots objectAtIndex:rightIdx];
                
                // Create a snapshot before the right moving object starts.
                if (rightIdx == 0 && leftIdx != 0) {
                    // left snapshot is first
                    createSnapshot(r.timestamp);
                }
                
                // Create the next snapshot.
                rightGeometry = r.geometry;
                createSnapshot(r.timestamp);
                                
                if (rightIdx + 1 == [rightSnapshots count]) {
                    if (r.timestamp != nil) {
                        // Reset the geometry of the right moving object.
                        rightGeometry = nil;
                        createSnapshot(r.timestamp);
                    }
                    
                    if (rightSequenceIdx < [rightSequence count]) {
                        rightSnapshots = [[rightSequence objectAtIndex:rightSequenceIdx] snapshots];
                        rightSequenceIdx++;
                        rightIdx = 0;
                    } else {
                        rightIdx++;
                    }
                } else {
                    rightIdx++;
                }
                break;
            }
            
            default: // same
            {
                
                TXLSnapshot *l = [leftSnapshots objectAtIndex:leftIdx];
                TXLSnapshot *r = [rightSnapshots objectAtIndex:rightIdx];
                
                if (leftIdx == 0 && rightIdx + 1 == [rightSnapshots count]) {
                    // left is first AND right is last snapshot
                    
                    rightGeometry = r.geometry;
                    
                } else if (rightIdx == 0 && leftIdx + 1 == [leftSnapshots count]) {
                    // right is first AND left is last snapshot
                    
                    leftGeometry = l.geometry;
                    
                } else {
                    
                    leftGeometry = l.geometry;
                    rightGeometry = r.geometry;
                    
                }

                // Create the next snapshot.
                createSnapshot(l.timestamp);
                
                if (l.timestamp == nil) {
                    leftGeometry = nil;
                    rightGeometry = nil;
                }
                
                if (leftIdx + 1 == [leftSnapshots count]) {
                    if (l.timestamp != nil) {
                        // Reset the geometry of the left movign object.
                        leftGeometry = nil;
                    }
                    
                    if (leftSequenceIdx < [leftSequence count]) {
                        leftSnapshots = [[leftSequence objectAtIndex:leftSequenceIdx] snapshots];
                        leftSequenceIdx++;
                        leftIdx = 0;
                    } else {
                        leftIdx++;
                    }
                } else {
                    leftIdx++;
                }
                
                if (rightIdx + 1 == [rightSnapshots count]) {
                    if (r.timestamp != nil) {
                        // Reset the geometry of the right movign object.
                        rightGeometry = nil;
                    }
                    
                    if (rightSequenceIdx < [rightSequence count]) {
                        rightSnapshots = [[rightSequence objectAtIndex:rightSequenceIdx] snapshots];
                        rightSequenceIdx++;
                        rightIdx = 0;
                    } else {
                        rightIdx++;
                    }
                } else {
                    rightIdx++;
                }
            }
        }
    }
    
    // If the left or right geometry are not nil, at least one of
    // the moving objects has no end (timestamp == +inf).
    if ([(TXLSnapshot *)[resultSnapshots lastObject] timestamp] != nil && (leftGeometry != nil || rightGeometry != nil)) {
        
        // Create the last snapshot with timestamp == +inf
        createSnapshot(nil);
    }
    
    if ([resultSnapshots count] > 0) {
        [resultSequence addObject:[TXLMovingObject movingObjectWithSnapshots:resultSnapshots]];
    }
    
    return [TXLMovingObjectSequence sequenceWithArray:resultSequence];
}


@end

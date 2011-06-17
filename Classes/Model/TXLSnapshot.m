//
//  TXLSnapshot.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 28.01.11.
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

#import "TXLSnapshot.h"
#import "TXLGeometryCollection.h"

@implementation TXLSnapshot

@synthesize timestamp;
@synthesize geometry;

+ (TXLSnapshot *)snapshotWithTimestamp:(NSDate *)t
                              geometry:(TXLGeometryCollection *)g {
    return [[[self alloc] initWithTimestamp:t
                                   geometry:g] autorelease];
}

- (id)initWithTimestamp:(NSDate *)t
               geometry:(TXLGeometryCollection *)g {
    if ((self = [super init])) {
        timestamp = [t retain];
        geometry = [g retain];
    }
    return self;
}

- (void)dealloc {
    [timestamp release];
    [geometry release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<TXLSnapshot %p>{timestamp = %@, geometry = %@}", self, timestamp, geometry];
}

#pragma mark -
#pragma mark Equality

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TXLSnapshot class]]) {
        
        TXLSnapshot *other = object;
        
        if ((self.timestamp == nil && other.timestamp != nil) ||
            (self.timestamp != nil && other.timestamp == nil) ||
            [self.timestamp compare:other.timestamp] != NSOrderedSame)
            return NO;
        
        return [self.geometry isEqual:other.geometry];
    }
    return NO;
}

@end

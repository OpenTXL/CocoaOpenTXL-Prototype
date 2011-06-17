//
//  TXLInteger.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 07.01.11.
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

#import "TXLInteger.h"

@interface TXLInteger ()
- (id)initWithValue:(int64_t)v;
@end


@implementation TXLInteger

+ (id)integerWithValue:(int64_t)v {
    return [[[self alloc] initWithValue:v] autorelease];
}

- (id)initWithValue:(int64_t)v {
    if ((self = [super init])) {
        _v = v;
    }
    return self;
}

- (NSInteger)integerValue {
    return _v;
}

- (NSUInteger)unsignedIntegerValue {
    return _v;
}

- (int)intValue {
    return _v;
}

- (int64_t)int64Value {
    return _v;
}

- (BOOL)boolValue {
    return _v;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%d", _v];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]])
        return [(TXLInteger *)object int64Value] == _v;
    
    return NO;
}

- (NSUInteger)hash {
    return _v;
}

#pragma mark -
#pragma mark NSCopying Protocol Implementation

- (id)copyWithZone:(NSZone *)zone {
    return [self retain];
}

@end

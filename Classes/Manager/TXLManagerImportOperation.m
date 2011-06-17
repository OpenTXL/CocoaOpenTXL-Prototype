//
//  TXLManagerImportOperation.m
//  OpenTXL-MacOSX
//
//  Created by Tobias Kräntzer on 05.04.11.
//  Copyright 2011 Fraunhofer ISST. All rights reserved.
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

#import "TXLManagerImportOperation.h"


@implementation TXLManagerImportOperation

@synthesize path = path_;
@synthesize from = from_;
@synthesize to = to_;

+ (TXLManagerImportOperation *)operationWithPath:(NSString *)path
                                    intervalFrom:(NSDate *)from
                                              to:(NSDate *)to {
    return [[[self alloc] initWithPath:path intervalFrom:from to:to] autorelease];
}

- (id)initWithPath:(NSString *)path
    intervalFrom:(NSDate *)from
                to:(NSDate *)to {
    if ((self = [super init])) {
        path_ = [path retain];
        from_ = [from retain];
        to_ = [to retain];
    }
    return self;
}

- (void)dealloc {
    [path_ release];
    [from_ release];
    [to_ release];
    [super dealloc];
}

@end

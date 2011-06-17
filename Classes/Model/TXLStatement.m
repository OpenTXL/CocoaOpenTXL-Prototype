//
//  TXLStatement.m
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

#import "TXLStatement.h"
#import "TXLMovingObject.h"
#import "TXLTerm.h"

@interface TXLStatement ()
- (id)initWithSubject:(TXLTerm *)subject
            predicate:(TXLTerm *)predicate
               object:(TXLTerm *)object;
@end


@implementation TXLStatement

@synthesize subject;
@synthesize predicate;
@synthesize object;

+ (id)statementWithSubject:(TXLTerm *)subject
                 predicate:(TXLTerm *)predicate
                    object:(TXLTerm *)object {
    return [[[self alloc] initWithSubject:subject
                                predicate:predicate
                                   object:object] autorelease];
}

- (id)initWithSubject:(TXLTerm *)s
            predicate:(TXLTerm *)p
               object:(TXLTerm *)o {
    if ((self = [super init])) {
        subject = [s retain];
        predicate = [p retain];
        object = [o retain];
    }
    return self;
}

- (void)dealloc {
    [subject release];
    [predicate release];
    [object release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@ .", subject, predicate, object];
}

#pragma mark -
#pragma mark Check Equality

- (BOOL)isEqual:(id)obj {
    if ([obj isKindOfClass:[TXLStatement class]]) {
        
        TXLStatement *other = obj;
        
        if(![self.subject isEqual:other.subject]){
            return NO;
        }
        if(![self.predicate isEqual:other.predicate]){
            return NO;
        }
        if(![self.object isEqual:other.object]){
            return NO;
        }        
        
    } else {
        return NO;
    }
    
    return YES;
}

@end

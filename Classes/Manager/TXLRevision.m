//
//  TXLRevision.m
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

#import "TXLRevision.h"
#import "TXLManager.h"
#import "TXLDatabase.h"
#import "TXLInteger.h"

@interface TXLRevision ()
- (id)initWithPrimaryKey:(NSUInteger)pk;
- (id)initWithPrimaryKey:(NSUInteger)pk timestamp:(NSDate *)ts previousPrimaryKey:(NSUInteger)ppk;
@end


@implementation TXLRevision

@synthesize primaryKey;

#pragma mark - 
#pragma mark Memory Management

- (void)dealloc {
    [timestamp release];
    [super dealloc];
}

#pragma mark -
#pragma mark Revision Details

- (NSDate*)timestamp { 
    if (timestamp == nil & primaryKey != 0) { 
        TXLDatabase *database = [[TXLManager sharedManager] database]; 
        
        NSError *error;
        NSArray *result = [database executeSQLWithParameters:@"SELECT timestamp FROM txl_revision WHERE id = ?" error:&error, 
                           [TXLInteger integerWithValue:primaryKey],
                           nil];
        
        if (result == nil) {
            [NSException exceptionWithName:@"TXLRevisionException"
                                    reason:[error localizedDescription]
                                  userInfo:nil];
        }
        
        
        if ([result count] == 1) { 
            timestamp = [[NSDate  dateWithTimeIntervalSince1970:[[[result objectAtIndex:0] objectForKey:@"timestamp"] doubleValue]] retain]; 
        } 
    } 
    return timestamp; 
} 

#pragma mark -
#pragma mark Transaction Timeline

- (TXLRevision *)precursor {
    
    TXLRevision *pre = nil; 
    TXLDatabase *database = [[TXLManager sharedManager] database]; 
    
    // first try to get the previousPrimaryKey
    if (previousPrimaryKey == 0 && primaryKey != 0) {
        
        NSError *error;
        NSArray *result = [database executeSQLWithParameters:@"SELECT previous FROM txl_revision WHERE id = ?" error:&error, 
                           [TXLInteger integerWithValue:primaryKey], 
                           nil];
        
        if (result == nil) {
            [NSException exceptionWithName:@"TXLRevisionException"
                                    reason:[error localizedDescription]
                                  userInfo:nil];
        }        
        
        if ([result count] == 1) { 
            previousPrimaryKey = [[[result objectAtIndex:0] objectForKey:@"previous"] integerValue]; 
        } 
    }
    
    if (previousPrimaryKey == 0)
        return nil;
    
    NSError *error;
    NSArray *result = [database executeSQLWithParameters:@"SELECT id, timestamp, previous FROM txl_revision WHERE id = ?" error:&error,
                                                         [TXLInteger integerWithValue:previousPrimaryKey],
                                                         nil];
    
    if (result == nil) {
        [NSException exceptionWithName:@"TXLRevisionException"
                                reason:[error localizedDescription]
                              userInfo:nil];
    } 
    
    if ([result count] == 0) {
        return nil;
    } else {
        NSUInteger pk = [[[result objectAtIndex:0] objectForKey:@"id"] intValue];
        NSUInteger ppk = [[[result objectAtIndex:0] objectForKey:@"previous"] intValue];
        NSDate *ts = [NSDate  dateWithTimeIntervalSince1970:[[[result objectAtIndex:0] objectForKey:@"timestamp"] doubleValue]];
        pre = [[[TXLRevision alloc] initWithPrimaryKey:pk timestamp:ts previousPrimaryKey:ppk] autorelease];
    }
    
    return pre;
}

- (TXLRevision *)successor {
    TXLDatabase *database = [[TXLManager sharedManager] database];
    
    NSError *error;
    NSArray *result = [database executeSQLWithParameters:@"SELECT id, timestamp, previous FROM txl_revision WHERE previous = ?" error:&error,
                                                         [TXLInteger integerWithValue:primaryKey],
                                                         nil];
    
    if (result == nil) {
        [NSException exceptionWithName:@"TXLRevisionException"
                                reason:[error localizedDescription]
                              userInfo:nil];
    }    
    
    if ([result count] == 0) {
        return nil;
    } else {
        NSUInteger pk = [[[result objectAtIndex:0] objectForKey:@"id"] intValue];
        NSUInteger ppk = [[[result objectAtIndex:0] objectForKey:@"previous"] intValue];
        NSDate *ts = [NSDate  dateWithTimeIntervalSince1970:[[[result objectAtIndex:0] objectForKey:@"timestamp"] doubleValue]];
        return [[[TXLRevision alloc] initWithPrimaryKey:pk timestamp:ts previousPrimaryKey:ppk] autorelease];
    }
}

#pragma mark -
#pragma mark Check Equality

- (BOOL)isEqual:(id)anObject {
    if ([anObject isKindOfClass:[TXLRevision class]]) {
        TXLRevision *other = anObject;
        return other.primaryKey == self.primaryKey;
    }
    return NO;
}

#pragma mark -
#pragma mark Describing Objects

- (NSString *)description {
    return [NSString stringWithFormat:@"#%d", primaryKey];
}


#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Autorelease Constructor

+ (TXLRevision *)revisionWithPrimaryKey:(NSUInteger)pk {
    return [[[TXLRevision alloc] initWithPrimaryKey:pk] autorelease];
}

+ (TXLRevision *)revisionWithPrimaryKey:(NSUInteger)pk
                              timestamp:(NSDate *)ts
                     previousPrimaryKey:(NSUInteger)ppk {
    return [[[TXLRevision alloc] initWithPrimaryKey:pk
                                          timestamp:ts
                                 previousPrimaryKey:ppk] autorelease];
}

#pragma mark -
#pragma mark -
#pragma mark Private Methods

#pragma mark -
#pragma mark Internal Non-Autorelease Constructor 

- (id)initWithPrimaryKey:(NSUInteger)pk { 
    return [self initWithPrimaryKey:pk  
                          timestamp:nil  
                 previousPrimaryKey:0]; 
} 

- (id)initWithPrimaryKey:(NSUInteger)pk
               timestamp:(NSDate *)ts
      previousPrimaryKey:(NSUInteger)ppk {
    if ((self = [super init])) {
        primaryKey = pk;
        previousPrimaryKey = ppk;
        timestamp = [ts retain];
    }
    return self;
}

@end

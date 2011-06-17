//
//  TXLQueryHandle.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 08.10.10.
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

#import "TXLQueryHandle.h"
#import "TXLManager.h" 
#import "TXLQuery.h"
#import "TXLRevision.h"
#import "TXLResultSet.h"
#import "TXLDatabase.h"
#import "TXLInteger.h"

@interface TXLQueryHandle () 
- (id)initWithQueryPrimaryKey:(NSUInteger)pk;
@end 

@implementation TXLQueryHandle

@synthesize delegate;
@synthesize queryPrimaryKey;


#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    [super dealloc];
}

#pragma mark -
#pragma mark Query Expression & Parameters

- (NSString *)expression {
    NSError *error;
    NSArray *result = [[[TXLManager sharedManager] database] executeSQL:@"SELECT sparql FROM txl_query WHERE id = ?"
                                                         withParameters:[NSArray arrayWithObject:[TXLInteger integerWithValue:queryPrimaryKey]]
                                                                  error:&error];
    
    if (result == nil) {
        [NSException exceptionWithName:@"TXLQueryHandlerException"
                                reason:[error localizedDescription]
                              userInfo:nil];
    }
    
    if ([result count] == 0) {
        return nil;
    } else {
        return [[result objectAtIndex:0] objectForKey:@"sparql"];
    }
}

- (NSDictionary *)parameters {
    // Fetch the parameters for this query which where
    // used to configure the query.
    return nil;
}

- (NSDictionary *)options {
    // Fetch the options this query has been created
    // with form the database.
    return nil;
}

#pragma mark -
#pragma mark Evaluation Revisions

- (TXLRevision *)firstEvaluation {
    NSError *error;
    NSArray *result = [[[TXLManager sharedManager] database] executeSQL:@"SELECT first_evaluation FROM txl_query WHERE id = ?"
                                                        withParameters:[NSArray arrayWithObject:[TXLInteger integerWithValue:queryPrimaryKey]]
                                                                 error:&error];
    
    if (result == nil) {
        [NSException exceptionWithName:@"TXLQueryHandlerException"
                                reason:[error localizedDescription]
                              userInfo:nil];
    }
    
    if ([result count] == 0) {
        return nil;
    } else {
        return [TXLRevision revisionWithPrimaryKey:[[[result objectAtIndex:0] objectForKey:@"first_evaluation"] integerValue]];
    }
}

- (TXLRevision *)lastEvaluation {
    NSError *error;
    NSArray *result = [[[TXLManager sharedManager] database] executeSQL:@"SELECT last_evaluation FROM txl_query WHERE id = ?"
                                                         withParameters:[NSArray arrayWithObject:[TXLInteger integerWithValue:queryPrimaryKey]]
                                                                  error:&error];
    
    if (result == nil) {
        [NSException exceptionWithName:@"TXLQueryHandlerException"
                                reason:[error localizedDescription]
                              userInfo:nil];
    }
    
    if ([result count] == 0) {
        return nil;
    } else {
        return [TXLRevision revisionWithPrimaryKey:[[[result objectAtIndex:0] objectForKey:@"last_evaluation"] integerValue]];
    }
    
}

#pragma mark -
#pragma mark Result Set

- (TXLResultSet *)resultSetForRevision:(TXLRevision *)revision {
    // Return a result set for the given revision.
    return [TXLResultSet resultSetForQueryHandle:self
                                    withRevision:revision];
}

#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Autorelease Constructors

+ (TXLQueryHandle *)handleForQueryWithPrimaryKey:(NSUInteger)pk {
    return [[[self alloc] initWithQueryPrimaryKey:pk] autorelease];
}

#pragma mark -
#pragma mark -
#pragma mark Private Methods

#pragma mark -
#pragma mark Internal Non-Autorelease Constructor 

- (id)initWithQueryPrimaryKey:(NSUInteger)pk { 
    if ((self = [super init])) { 
        queryPrimaryKey = pk;
        observer = [[NSNotificationCenter defaultCenter] addObserverForName:[NSString stringWithFormat:@"org.opentxl.manager.resultset.%d", pk]
                                                                     object:nil
                                                                      queue:nil
                                                                 usingBlock:^(NSNotification *notification){
                                                                     if ([self.delegate respondsToSelector:@selector(continuousQuery:hasNewResultSet:forRevision:)]) {
                                                                         TXLRevision *rev = [[notification userInfo] objectForKey:@"revision"];
                                                                         if (rev) {
                                                                             [self.delegate continuousQuery:self
                                                                                            hasNewResultSet:[TXLResultSet resultSetForQueryHandle:self withRevision:rev]
                                                                                                forRevision:rev];
                                                                         } 
                                                                     }
                                                                 }];
    }
    return self;
}

@end

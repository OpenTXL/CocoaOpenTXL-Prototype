//
//  TXLSPARQLQuery.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 18.10.10.
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

#import "TXLQuery.h"
#import "TXLGraphPattern.h"
#import "TXLManager.h"
#import "TXLDatabase.h"
#import "TXLInteger.h"
#import "TXLContext.h"

@interface TXLQuery () 
- (id)initWithPrimaryKey:(NSUInteger)pk; 
@end 

@implementation TXLQuery

@synthesize primaryKey;

- (BOOL)isConstructQuery {
    TXLDatabase *database = [[TXLManager sharedManager] database];
    
    NSError *error;
    
    __block BOOL result = NO;
    
    BOOL success = [database executeSQL:@"SELECT id, construct_template_pattern_id FROM txl_query WHERE id = ?"
                         withParameters:[NSArray arrayWithObject:[TXLInteger integerWithValue:self.primaryKey]]
                                  error:&error
                          resultHandler:^(NSDictionary *row, BOOL *stop) {
                              id r = [row objectForKey:@"construct_template_pattern_id"];
                              if ([r isKindOfClass:[TXLInteger class]] && [(TXLInteger *)r unsignedIntegerValue] != 0) {
                                  result = YES;
                              } else {
                                  result = NO;
                              }
                              *stop = YES;
                          }];
    if (!success) {
        [[NSException exceptionWithName:@"TXLQueryException"
                                 reason:[error localizedDescription]
                               userInfo:nil] raise];
    }
    return result;
}

#pragma mark -
#pragma mark Query Pattern

- (TXLGraphPattern *)queryPattern {
    
    // returns the root query pattern
    // of this query
    
    NSError *error;
    
    TXLDatabase *database = [[TXLManager sharedManager] database];
    NSArray *result = [database executeSQLWithParameters:@"SELECT pattern_id FROM txl_query WHERE id = ?"
                                                   error:&error,
                       [TXLInteger integerWithValue:self.primaryKey], nil];
    
    if (result == nil) {
        [NSException raise:@"TXLQueryException" format:@"Could not retrieve the root query pattern: %@", [error localizedDescription]];
        NSLog(@"Could not load query pattern of query (%d): %@", self.primaryKey, [error localizedDescription]);
    }
    
    return [TXLGraphPattern graphPatternWithPrimaryKey:[[[result objectAtIndex:0] objectForKey:@"pattern_id"] integerValue]];
}

#pragma mark -
#pragma mark Variables

- (NSArray *)variablesOfResultset {
    
    // get all variables of this query,
    // that should be contained in the
    // resultset
    
    NSMutableArray *varsOfResultset = [NSMutableArray array];
    
    NSError *error;
    
    TXLDatabase *database = [[TXLManager sharedManager] database];
    NSArray *result = [database executeSQLWithParameters:@"SELECT id \
                       FROM txl_query_variable \
                       WHERE query_id=? AND in_resultset=?" error:&error, 
                       [TXLInteger integerWithValue:self.primaryKey],
                       [TXLInteger integerWithValue:YES],
                       nil];
    
    if (result == nil) {
        @throw [NSException exceptionWithName:@"TXLQueryException"
                                       reason:[error localizedDescription]
                                     userInfo:nil];
        NSLog(@"Could not load variables of query (%d): %@", self.primaryKey, [error localizedDescription]);
    }                       
    
    for (NSDictionary *res in result) {
        [varsOfResultset addObject:[res objectForKey:@"id"]];
    }   
    
    return varsOfResultset;
    
}

#pragma mark -
#pragma mark Blank Nodes Variables (applies to contruct queries)

- (NSArray *)blankNodeVariablesOfResultset {
    
	// get all variables of this query,
	// that should be contained in the
	// resultset and are blank nodes
    
    NSMutableArray *blankNodeVarsOfResultset = [NSMutableArray array];
    
    NSError *error;
    
    TXLDatabase *database = [[TXLManager sharedManager] database];
    NSArray *result = [database executeSQLWithParameters:@"SELECT id \
                       FROM txl_query_variable \
                       WHERE query_id=? AND in_resultset=? AND is_blanknode=?" error:&error, 
                       [TXLInteger integerWithValue:self.primaryKey],
                       [TXLInteger integerWithValue:YES],
                       [TXLInteger integerWithValue:YES],
                       nil];
    
    if (result == nil) {
        @throw [NSException exceptionWithName:@"TXLQueryException"
                                       reason:[error localizedDescription]
                                     userInfo:nil];
        NSLog(@"Could not load blank node variables of query (%d): %@", self.primaryKey, [error localizedDescription]);
    }                       
    
    for (NSDictionary *res in result) {
        [blankNodeVarsOfResultset addObject:[res objectForKey:@"id"]];
    }   
    
    return blankNodeVarsOfResultset;
}


#pragma mark -
#pragma mark Expression

- (NSString *)expression {
    
    TXLDatabase *database = [[TXLManager sharedManager] database];
    
    NSError *error;
    
    __block NSString *result = nil;
    
    BOOL success = [database executeSQL:@"SELECT sparql FROM txl_query WHERE id = ?"
                         withParameters:[NSArray arrayWithObject:[TXLInteger integerWithValue:self.primaryKey]]
                                  error:&error
                          resultHandler:^(NSDictionary *row, BOOL *stop){
                              result = [[row objectForKey:@"sparql"] retain];
                              *stop = YES;
                          }];
    if (!success) {
        [[NSException exceptionWithName:@"TXLQueryException"
                                 reason:[error localizedDescription]
                               userInfo:nil] raise];
    }
    
    return [result autorelease];
}

#pragma mark -
#pragma mark Context

+ (NSArray *)queriesForContexts:(NSSet *)ctxs error:(NSError **)error {
    
    // Find all registered queries containing a context in the FROM clause
    // which is equal to ctx or where ctx is a child context and
    // add these queries to the list above.
    
    NSMutableArray *queries = [NSMutableArray array];
    
    TXLDatabase *database = [[TXLManager sharedManager] database];
    NSArray *result = [database executeSQL:@"SELECT id \
                       FROM txl_query \
                       WHERE id IN (SELECT query_id FROM txl_query_name WHERE query_id = txl_query.id) \
                       OR id IN (SELECT query_id FROM txl_context_query WHERE query_id = txl_query.id)" error:error];
    
    if (result == nil) {
        return nil;
    }
    
    
    
    for (NSDictionary *res in result) {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        TXLInteger *queryPk = [res objectForKey:@"id"];
        
        NSArray *query_ctxs = [database executeSQLWithParameters:@"SELECT context_id FROM txl_query_context WHERE query_id = ?" error:error, queryPk, nil];
        
        if (query_ctxs == nil) {
            [pool drain];
            return nil;
        }
        
        for (NSDictionary *c in query_ctxs) {
            TXLContext *from_clause = [TXLContext contextWithPrimaryKey:[[c objectForKey:@"context_id"] integerValue]];
            
            if ([ctxs containsObject:from_clause]) {
                [queries addObject:[TXLQuery queryWithPrimaryKey:[queryPk integerValue]]];
                break;
            } else {
                NSSet *children = [from_clause subcontextsMatchingPattern:@"*"];
                if ([children intersectsSet:ctxs]) {
                    [queries addObject:[TXLQuery queryWithPrimaryKey:[queryPk integerValue]]];
                    break;
                }
            }
        }
        [pool drain];
    }

    return queries;
}

+ (NSArray *)queriesForContext:(TXLContext *)ctx error:(NSError **)error {
    
    // Find all registered queries containing a context in the FROM clause
    // which is equal to ctx or where ctx is a child context and
    // add these queries to the list above.
    
    NSMutableArray *queries = [NSMutableArray array];
    
    TXLDatabase *database = [[TXLManager sharedManager] database];
    NSArray *result = [database executeSQL:@"SELECT id \
                       FROM txl_query \
                       WHERE id IN (SELECT query_id FROM txl_query_name WHERE query_id = txl_query.id) \
                       OR id IN (SELECT query_id FROM txl_context_query WHERE query_id = txl_query.id)" error:error];
    
    if (result == nil) {
        return nil;
    }
    
    for (NSDictionary *res in result) {
        TXLInteger *queryPk = [res objectForKey:@"id"];
        
        NSArray *ctxs = [database executeSQLWithParameters:@"SELECT context_id \
                         FROM txl_query_context \
                         WHERE query_id = ?" error:error, 
                         queryPk,
                         nil];
        
        if (ctxs == nil) {
            return nil;
        }
        
        for (NSDictionary *c in ctxs) {
            TXLContext *context = [TXLContext contextWithPrimaryKey:[[c objectForKey:@"context_id"] integerValue]];
            
            if ([context isEqual:ctx] || [[context subcontextsMatchingPattern:@"*"] containsObject:ctx]) {
                [queries addObject:[TXLQuery queryWithPrimaryKey:[queryPk integerValue]]];
                break;
            }
        }
    }
    
    return queries;
    
}

- (NSArray *)contexts {
    
    // return all contexts, that are defined
    // in the from clause of this query
    
    NSError *error;
    
    NSMutableArray *ctxs = [NSMutableArray array];
    
    TXLDatabase *database = [[TXLManager sharedManager] database];
    NSArray *result = [database executeSQLWithParameters:@"SELECT context_id \
                       FROM txl_query_context \
                       WHERE query_id=?" error:&error, 
                       [TXLInteger integerWithValue:self.primaryKey],
                       nil];
    
    if (result == nil) {
        @throw [NSException exceptionWithName:@"TXLQueryException"
                                       reason:[error localizedDescription]
                                     userInfo:nil];
        NSLog(@"Could not load contexts of query (%d): %@", self.primaryKey, [error localizedDescription]);
    }
    
    for (NSDictionary *res in result) {
        NSUInteger ctxPk = [[res objectForKey:@"context_id"] unsignedIntegerValue];
        [ctxs addObject:[TXLContext contextWithPrimaryKey:ctxPk]];
    }
    
    return ctxs;
    
}

#pragma mark - 
#pragma mark Memory Management 

- (void)dealloc { 
    [super dealloc]; 
}

#pragma mark -
#pragma mark Database Management

+ (id)queryWithPrimaryKey:(NSUInteger)pk {
    return [[[self alloc] initWithPrimaryKey:pk] autorelease];
}

#pragma mark -
#pragma mark -
#pragma mark Private Methods

#pragma mark - 
#pragma mark Internal Non-Autorelease Constructor 

- (id)initWithPrimaryKey:(NSUInteger)pk { 
    if ((self = [super init])) { 
        primaryKey = pk; 
    } 
    return self; 
} 

@end

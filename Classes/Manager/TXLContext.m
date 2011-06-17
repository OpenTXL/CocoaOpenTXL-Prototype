//
//  TXLContext.m
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

#import "TXLContext.h"
#import "TXLDatabase.h"
#import "TXLInteger.h"
#import "TXLManager.h"
#import "TXLQuery.h"
#import "TXLSPARQLCompiler.h"

@interface TXLContext ()
- (id)initContextWithPrimaryKey:(NSUInteger)pk
                           name:(NSString *)n;
@end


@implementation TXLContext

@synthesize primaryKey, name;


#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [name release];
    [super dealloc];
}

#pragma mark -
#pragma mark Accessing the Context Hierarchy

- (NSSet *)subcontextsMatchingPattern:(NSString *)pattern {
    NSError *error;
    NSMutableSet *result = [NSMutableSet set];
    BOOL success = [[[TXLManager sharedManager] database] executeSQL:[NSString stringWithFormat:@"SELECT id, name FROM txl_context WHERE name glob ?"]
                                                      withParameters:[NSArray arrayWithObject:[NSString stringWithFormat:@"%@/%@", name, pattern]]
                                                               error:&error
                                                       resultHandler:^(NSDictionary *row, BOOL *stop){
                                                           NSUInteger pk = [[row objectForKey:@"id"] integerValue];
                                                           NSString *n = [row objectForKey:@"name"];
                                                           
                                                           [result addObject:[[[TXLContext alloc] initContextWithPrimaryKey:pk
                                                                                                                       name:n] autorelease]];
                                                       }];
    
    if (!success) {
        [[NSException exceptionWithName:@"TXLContextException"
                                 reason:[error localizedDescription]
                               userInfo:nil] raise];
    }
    
    return result;    
}

- (BOOL)isDescendantOf:(TXLContext *)ctx {
    return [name hasPrefix:ctx.name] &&
    ![name isEqualToString:ctx.name];
}

- (BOOL)isAntecendentOf:(TXLContext *)ctx {
    return [ctx.name hasPrefix:name] &&
    ![ctx.name isEqualToString:name];
}

- (TXLContext *)childWithName:(NSString *)n {
    NSError *error;
    __block TXLContext *result = nil;
    BOOL success = [[[TXLManager sharedManager] database] executeSQL:@"SELECT id, name FROM txl_context WHERE name = ?"
                                                      withParameters:[NSArray arrayWithObject:[NSString stringWithFormat:@"%@/%@", name, n]]
                                                               error:&error
                                                       resultHandler:^(NSDictionary *row, BOOL *stop){
                                                           NSUInteger pk = [[row objectForKey:@"id"] integerValue];
                                                           NSString *_n = [row objectForKey:@"name"];
                                                           result = [[[[TXLContext alloc] initContextWithPrimaryKey:pk
                                                                                                               name:_n] autorelease] retain];                                                           
                                                           *stop = YES;
                                                       }];
    
    if (!success) {
        [[NSException exceptionWithName:@"TXLContextException"
                                 reason:[error localizedDescription]
                               userInfo:nil] raise];
    }
    
    [result autorelease];
    
    if (result == nil) {
        BOOL success = [[[TXLManager sharedManager] database] executeSQL:@"INSERT INTO txl_context (name) VALUES (?)"
                                                          withParameters:[NSArray arrayWithObject:[NSString stringWithFormat:@"%@/%@", name, n]]
                                                                   error:&error
                                                           resultHandler:^(NSDictionary *row, BOOL *stop){}];
        if (!success) {
            [[NSException exceptionWithName:@"TXLContextException"
                                     reason:[error localizedDescription]
                                   userInfo:nil] raise];
        }
        
        NSUInteger pk = [[TXLManager sharedManager] database].lastInsertRowid;
        
        result = [[[TXLContext alloc] initContextWithPrimaryKey:pk
                                                           name:n] autorelease];                                                           
    }
    
    return result;
}

#pragma mark -
#pragma mark Update Context

- (void)updateWithStatements:(NSArray *)statements
             completionBlock:(void(^)(TXLRevision *, NSError *))completionBlock {
    [self updateWithStatements:statements
                  movingObject:nil
                inIntervalFrom:nil
                            to:nil
                completionBlock:completionBlock];
}

- (void)updateWithStatements:(NSArray *)statements
                movingObject:(TXLMovingObject *)mo
              inIntervalFrom:(NSDate *)from
                          to:(NSDate *)to
             completionBlock:(void(^)(TXLRevision *, NSError *))completionBlock {
    [[TXLManager sharedManager] updateContext:self
                               withStatements:statements
                                 movingObject:mo
                               inIntervalFrom:from
                                           to:to
                              completionBlock:completionBlock];
}

#pragma mark -
#pragma mark Clear Context

- (void)clear:(void(^)(TXLRevision *, NSError *))completionBlock {
    [self clearInIntervalFrom:nil
                           to:nil
              completionBlock:completionBlock];
}

- (void)clearInIntervalFrom:(NSDate *)from
                         to:(NSDate *)to
            completionBlock:(void(^)(TXLRevision *, NSError *))completionBlock {
    [self updateWithStatements:nil
                  movingObject:nil
                inIntervalFrom:from
                            to:to
               completionBlock:completionBlock];
}

#pragma mark -
#pragma mark Situation Definition

- (NSString *)situationDefinition {
    return [[TXLManager sharedManager] situationDefinitionForContext:self];
}

- (BOOL)setSituationDefinition:(NSString *)expression
                   withOptions:(NSDictionary *)options
                         error:(NSError **)error {
    return [[TXLManager sharedManager] setSituationDefinition:expression
                                                   forContext:self
                                                  withOptions:options
                                                        error:error];
}

- (void)removeSituationDefinition {
    return [[TXLManager sharedManager] removeSituationDefinitionFromContext:self];
}

#pragma mark -
#pragma mark Describing Objects

- (NSString *)description {
    return name;
}

#pragma mark -
#pragma mark NSCopying Protocol Implementation

- (id)copyWithZone:(NSZone *)zone {
    return [self retain];
}

#pragma mark -
#pragma mark Check Equality

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TXLContext class]]) {
        return self.primaryKey == [(TXLContext *)object primaryKey];
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    return primaryKey;
}

#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Autorelease Constructor

+ (id)contextWithPrimaryKey:(NSUInteger)pk {
    NSError *error;
    
    TXLDatabase *database = [[TXLManager sharedManager] database];
    NSArray *result = [database executeSQLWithParameters:@"SELECT id, name FROM txl_context WHERE id = ?" error:&error,
                       [TXLInteger integerWithValue:pk], nil];
    
    if (result == nil) {
        [NSException exceptionWithName:@"TXLContextException"
                                reason:[error localizedDescription]
                              userInfo:nil];
    }
    
    switch ([result count]) {
        case 1:
        {
            NSUInteger pk = [[[result objectAtIndex:0] objectForKey:@"id"] integerValue];
            NSString *n = [[result objectAtIndex:0] objectForKey:@"name"];
            
            return [[[self alloc] initContextWithPrimaryKey:pk name:n] autorelease];
        }
            
        default:
            return nil;
    }
}

+ (id)contextWithName:(NSString *)n {
    NSError *error;
    
    TXLDatabase *database = [[TXLManager sharedManager] database];
    NSArray *result = [database executeSQLWithParameters:@"SELECT id, name FROM txl_context WHERE name = ?" error:&error,
                       n, nil];
    
    if (result == nil) {
        [NSException exceptionWithName:@"TXLContextException"
                                reason:[error localizedDescription]
                              userInfo:nil];
    }
    
    switch ([result count]) {
        case 1:
        {
            NSUInteger pk = [[[result objectAtIndex:0] objectForKey:@"id"] integerValue];
            NSString *_n = [[result objectAtIndex:0] objectForKey:@"name"];
            
            return [[[self alloc] initContextWithPrimaryKey:pk name:_n] autorelease];
        }
            
        default:
            return nil;
    }
}

#pragma mark -
#pragma mark -
#pragma mark Private Methods

#pragma mark -
#pragma mark Memory Management

- (id)initContextWithPrimaryKey:(NSUInteger)pk
                           name:(NSString *)n {
    if ((self = [super init])) {
        primaryKey = pk;
        name = [n retain];
    }
    return self;
}

@end

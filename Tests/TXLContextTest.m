//
//  TXLContextTest.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 22.09.10.
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

#import <GHUnit/GHUnit.h>

#import "TXLDatabase.h"
#import "TXLContext.h"
#import "TXLManager.h"

#define SQL(x) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

@interface TXLContextTest : GHTestCase {

}

@end


@implementation TXLContextTest


- (void)setUp {
    for (NSString *name in [[[TXLManager sharedManager] database] tableNames]) {
        
        // delete content for tables
        if ([name hasPrefix:@"txl_context"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_statement"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_query"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_geometry"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_movingobject"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_movingobjectsequence"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_snapshot"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        if ([name hasPrefix:@"txl_term"]) {
            NSString *expr = [NSString stringWithFormat:@"DELETE FROM %@", name];
            SQL(expr);
        }
        
        // delete tables
        if ([name hasPrefix:@"txl_resultset"]) {
            NSString *expr = [NSString stringWithFormat:@"DROP TABLE %@", name];
            SQL(expr);
        }
    }
}

#pragma mark -
#pragma mark Tests

- (void)testCreateContext {
    NSError *error;
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                host:@"localhost"
                                                                path:[NSArray arrayWithObjects:@"foo", @"bar", nil]
                                                               error:&error];
    GHAssertNotNil(context, [error localizedDescription]);
    GHAssertEqualStrings(context.name, @"txl://localhost/foo/bar", @"The name of the context should be 'txl://localhost/foo/bar'.");
    
    TXLContext *ctx2 = [TXLContext contextWithPrimaryKey:context.primaryKey];
    GHAssertNotNil(ctx2, @"Could not create a context via primary key.");
    GHAssertEqualObjects(context, ctx2, @"Contexts with the same primary key should be equal.");
    GHAssertNotNil(ctx2.name, @"The name of a context created vis primary key should not be nil.");
    GHAssertEqualStrings(ctx2.name, @"txl://localhost/foo/bar", @"The name of the context should be 'txl://localhost/foo/bar'.");
}

- (void)testContextName {
    NSError *error;
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                    host:@"localhost"
                                                                    path:[NSArray arrayWithObjects:@"foo", @"bar", nil]
                                                                   error:&error];
    GHAssertNotNil(context, [error localizedDescription]);
    
    GHAssertEqualStrings(context.name, @"txl://localhost/foo/bar", nil);
}

- (void)testCreateAndSave {
    NSError *error;
    
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                    host:@"localhost"
                                                                    path:[NSArray arrayWithObjects:@"testfoo", @"testbar", nil]
                                                                   error:&error];
    GHAssertNotNil(context, [error localizedDescription]);
    
    TXLContext *duplicateContext = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                             host:@"localhost"
                                                                             path:[NSArray arrayWithObjects:@"testfoo", @"testbar", nil]
                                                                            error:&error];
    GHAssertNotNil(duplicateContext, [error localizedDescription]);
    
    GHAssertEquals(context.primaryKey, duplicateContext.primaryKey, @"Contexts with the same protocol, host, and path must have the same primary key.");
}

- (void)testContextChildren {
    NSError *error;
    
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                    host:@"example.com"
                                                                    path:nil
                                                                   error:&error];
    GHAssertNotNil(context, [error localizedDescription]);
    
    GHAssertEquals([[context subcontextsMatchingPattern:@"*"] count], (NSUInteger)0, @"Expecting 0 children.");

    TXLContext *childContext = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                    host:@"example.com"
                                                                    path:[NSArray arrayWithObject:@"foo"]
                                                                   error:&error];
    GHAssertNotNil(childContext, [error localizedDescription]);
                   
    GHAssertEquals([[context subcontextsMatchingPattern:@"*"] count], (NSUInteger)1, @"Expecting 1 child.");
    GHAssertEqualStrings([[[[context subcontextsMatchingPattern:@"*"] allObjects] objectAtIndex:0] name], @"txl://example.com/foo", @"Name of child should be 'txl://example.com/foo'.");
	
    TXLContext *grandChildContext = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                              host:@"example.com"
                                                                              path:[NSArray arrayWithObjects:@"foo", @"bar", nil]
                                                                             error:&error];
    GHAssertNotNil(grandChildContext, [error localizedDescription]);

    GHAssertEquals([[context subcontextsMatchingPattern:@"*"] count], (NSUInteger)2, @"Expecting 2 children.");
    BOOL found = NO;
    for (TXLContext *ctx in [context subcontextsMatchingPattern:@"*"]) {
        if ([ctx.name isEqualToString:@"txl://example.com/foo/bar"]) {
            found = YES;
            break;
        }
    }
    GHAssertTrue(found, @"Name of child should be 'txl://example.com/foo/bar'.");

    TXLContext *anotherChildContext = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                                host:@"example.com"
                                                                                path:[NSArray arrayWithObjects:@"baz", nil]
                                                                               error:&error];
    GHAssertNotNil(anotherChildContext, [error localizedDescription]);
    
    GHAssertEquals([[context subcontextsMatchingPattern:@"*"] count], (NSUInteger)3, @"Expecting 3 children.");
    GHTestLog(@"%@", [context subcontextsMatchingPattern:@"*"]);
    
    TXLContext *grandGrandChildContext = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                                   host:@"example.com"
                                                                                   path:[NSArray arrayWithObjects:@"foo", @"bar", @"baz", nil]
                                                                                  error:&error];
    GHAssertNotNil(grandGrandChildContext, [error localizedDescription]);
    
    GHAssertEquals([[context subcontextsMatchingPattern:@"*"] count], (NSUInteger)4, @"Expecting 4 children.");
    GHTestLog(@"%@", [context subcontextsMatchingPattern:@"*"]);
}

- (void)testIsDescendantOf {
    NSError *error;
    TXLContext *ctx1 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                    host:@"localhost"
                                                                    path:nil
                                                                   error:&error];
    GHAssertNotNil(ctx1, [error localizedDescription]);
    
    TXLContext *ctx2 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                 host:@"localhost"
                                                                 path:[NSArray arrayWithObjects:@"foo", @"bar", nil]
                                                                error:&error];
    GHAssertNotNil(ctx2, [error localizedDescription]);
    
    GHAssertTrue([ctx2 isDescendantOf:ctx1], nil);
}

- (void)testIsAntecendentOf {
    NSError *error;
    TXLContext *ctx1 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                 host:@"localhost"
                                                                 path:nil
                                                                error:&error];
    GHAssertNotNil(ctx1, [error localizedDescription]);
    
    TXLContext *ctx2 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                 host:@"localhost"
                                                                 path:[NSArray arrayWithObjects:@"foo", @"bar", nil]
                                                                error:&error];
    GHAssertNotNil(ctx2, [error localizedDescription]);
    
    GHAssertTrue([ctx1 isAntecendentOf:ctx2], nil);
}

@end



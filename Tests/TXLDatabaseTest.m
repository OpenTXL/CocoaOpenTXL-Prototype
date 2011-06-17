//
//  TXLDatabaseTest.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 17.09.10.
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
#import "TXLInteger.h"
#import "TXLContext.h"

#import "TXLPropertiesReader.h"

#import <TargetConditionals.h>

#define SQL(x) {NSError *error; NSArray *result = [self.database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

@interface TXLDatabaseTest : GHTestCase {
    TXLDatabase *database;
}

@property (retain) TXLDatabase *database;

@end

@implementation TXLDatabaseTest

@synthesize database;

- (void)setUp {
    
    NSString *databasePath = nil;
    
#if TARGET_OS_IPHONE
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *tempDocumentsDirectory = [paths objectAtIndex:0];
    databasePath = [tempDocumentsDirectory stringByAppendingPathComponent:@"OpenTXL.db"];
#else
    databasePath = [TXLPropertiesReader propertyForKey:TXL_DATABASE_FILE_NAME_PROPERTY];
    if (databasePath == nil) {
        databasePath = @"/tmp/OpenTXL.db";
    }
#endif
    
    self.database = [[TXLDatabase alloc] initWithPath:databasePath];
}

- (void)tearDown {
    self.database = nil;
}

#pragma mark -
#pragma mark Tests

- (void)testExecuteSQL {
    NSError *error = nil;
    NSArray *result;
    
    result = [self.database executeSQL:@"select 5*5 as result" error:&error];
    GHAssertNotNil(result, [error localizedDescription]);
    
    GHAssertEquals([result count], (NSUInteger)1, @"Expecting only 1 row.");
    GHAssertEquals([[[result objectAtIndex:0] objectForKey:@"result"] intValue], 25, @"The result should be 25.");
}

- (void)testExecuteSQLWithArguments {
    NSError *error = nil;
    NSArray *result;
    
    NSString *stmt = @"select ?*? as result";
    result = [self.database executeSQLWithParameters:stmt error:&error,
                       [NSNumber numberWithInt:5],
                       [NSNumber numberWithInt:5], nil];
    
    GHAssertNotNil(result, [error localizedDescription]);
    
    GHAssertEquals([result count], (NSUInteger)1, @"Expecting only 1 row.");
    GHAssertEqualObjects([[result objectAtIndex:0] objectForKey:@"result"],
                         [NSNumber numberWithInt:25],
                         @"The result should be 25.");
}

- (void)testIsValid {
    NSError *error = nil;
    NSArray *result;
    
    result = [self.database executeSQL:@"SELECT IsValid(GeomFromText('POINT(10 15)', 4326)) AS result" error:&error];
    GHAssertNotNil(result, [error localizedDescription]);
    
    GHAssertEquals([result count], (NSUInteger)1, nil);
    GHAssertEquals([[[result objectAtIndex:0] objectForKey:@"result"] intValue], 1, nil);
}

- (void)testDynamicTyping {
    
    NSError *error = nil;
    NSArray *result;
    
    SQL(@"CREATE TABLE IF NOT EXISTS test_dynamic_typing (i primary key, a, b, c integer)");
    SQL(@"DELETE FROM test_dynamic_typing");
    
    result = [self.database executeSQLWithParameters:@"INSERT INTO test_dynamic_typing (i, a, b, c) VALUES (1, ?, ?, ?)"  error:&error,
     @"foo",
     [NSNull null],
     [NSNull null],
     nil];
    GHAssertNotNil(result, [error localizedDescription]);
    
    result = [self.database executeSQLWithParameters:@"INSERT INTO test_dynamic_typing (i, a, b, c) VALUES (2, ?, ?, ?)" error:&error,
     [TXLInteger integerWithValue:0],
     @"bar",
     [NSNull null],
     nil];
    GHAssertNotNil(result, [error localizedDescription]);
    
    result = [self.database executeSQL:@"SELECT a, b, c FROM test_dynamic_typing ORDER BY i" error:&error];
    GHAssertNotNil(result, [error localizedDescription]);
    
    GHTestLog(@"result: %@", result);
    
    GHAssertEquals([result count], (NSUInteger)2, nil);
    
    GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"a"] isKindOfClass:[NSString class]], nil);
    GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"b"] isKindOfClass:[NSNull class]], nil);
    GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"c"] isKindOfClass:[TXLInteger class]], nil);
    
    GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"a"] isKindOfClass:[TXLInteger class]], nil);
    GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"b"] isKindOfClass:[NSString class]], nil);
    GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"c"] isKindOfClass:[TXLInteger class]], nil);
    
    SQL(@"DROP TABLE test_dynamic_typing");
}

- (void)testConstrains {
    
    NSArray *result;
    NSError *error;
    
    SQL(@"CREATE TABLE IF NOT EXISTS testConstrains (a unique)");
    SQL(@"DELETE FROM testConstrains");
    
    result = [self.database executeSQL:@"INSERT INTO testConstrains (a) VALUES (1)" error:&error];
    GHTestLog(@"Table content after first insert: %@", [self.database executeSQL:@"select * from testConstrains" error:&error]);
    GHAssertNotNil(result, @"First insert should succeed: %@", error);
    
    result = [self.database executeSQL:@"INSERT INTO testConstrains (a) VALUES (1)" error:&error];
    GHTestLog(@"Table content after second insert: %@", [self.database executeSQL:@"select * from testConstrains" error:&error]);
    GHTestLog(@"Error message from second insert: %@", [error localizedDescription]);
    GHAssertNil(result, @"Second insert should fail.");
    
    SQL(@"DROP TABLE testConstrains");
}

- (void)testSyntaxError {
    NSArray *result;
    NSError *error = nil;
    
    result = [self.database executeSQL:@"CREATE TABLE testSyntaxError (a" error:&error];
    GHTestLog(@"Error message: %@", [error localizedDescription]);
    GHAssertNil(result, @"Table should not be created.");
}

- (void)testParameterMismatch {
    NSArray *result = nil;
    NSError *error = nil;

    SQL(@"CREATE TABLE IF NOT EXISTS testParameterMismatch (a)");
    
    result = [self.database executeSQL:@"INSERT INTO testParameterMismatch (a) VALUES (?)" error:&error];
    GHTestLog(@"Error message: %@", [error localizedDescription]);
    GHAssertNil(result, @"Insert should fail.");
    
    SQL(@"DROP TABLE testParameterMismatch");
}

- (void)testStoreNumbers {
    NSArray *result = nil;
    NSError *error = nil;

    SQL(@"CREATE TABLE IF NOT EXISTS testStoreNumbers (a, b)");
    SQL(@"DELETE FROM testStoreNumbers");
    
    result = [self.database executeSQLWithParameters:@"INSERT INTO testStoreNumbers (a, b) VALUES (?, ?)"
                                               error:&error,
              [TXLInteger integerWithValue:12],
              [NSNumber numberWithDouble:3.4],
              nil];
    GHAssertNotNil(result, [error localizedDescription]);
    
    result = [self.database executeSQL:@"SELECT * from testStoreNumbers" error:&error];
    GHAssertNotNil(result, [error localizedDescription]);
    
    GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"a"] isKindOfClass:[TXLInteger class]], @"Expecting object of type TXLInteger.");
    GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"b"] isKindOfClass:[NSNumber class]], @"Expecting object of type TXLFloat.");
    
    GHAssertEquals([[[result objectAtIndex:0] objectForKey:@"a"] integerValue], (NSInteger)12, @"TXLInteger should contain value 12.");
    
    SQL(@"DROP TABLE testStoreNumbers");
}

@end

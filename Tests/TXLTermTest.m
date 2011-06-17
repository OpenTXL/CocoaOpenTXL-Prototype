//
//  TXLTermTest.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 27.09.10.
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

#import "TXLTerm.h"

#import "TXLDatabase.h"
#import "TXLManager.h"

#define SQL(x) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

@interface TXLTermTest : GHTestCase {

}

@end


@implementation TXLTermTest

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

#pragma mark Blank Node

- (void)testCreateBlankNode {
    TXLTerm *bn = [TXLTerm termWithBlankNode:@"foo"];
    
    GHAssertTrue([bn isType:kTXLTermTypeBlankNode], nil);
    GHAssertEquals([bn type], kTXLTermTypeBlankNode, nil);
    
    GHAssertEqualObjects([bn blankNodeValue], @"foo", nil);
    GHAssertEqualObjects([bn description], @"_:foo", nil);
}

- (void)testSaveBlankNode {
    NSError *error;
    
    TXLTerm *bn = [TXLTerm termWithBlankNode:@"foo"];
    GHAssertFalse([bn isSavedInDatabase], nil);
    
    [bn save:&error];
    GHAssertTrue([bn isSavedInDatabase], nil);
    
    NSUInteger pk = bn.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, nil);
    
    GHAssertEqualObjects(bn, [[TXLTerm termWithBlankNode:@"foo"] save:&error], nil);
    GHAssertEqualObjects([TXLTerm termWithPrimaryKey:bn.primaryKey], [TXLTerm termWithBlankNode:@"foo"], nil);
}

#pragma mark IRI

- (void)testCreateIRI {
    TXLTerm *iri = [TXLTerm termWithIRI:@"http://example.com/foo#bar"];
    
    GHAssertTrue([iri isType:kTXLTermTypeIRI], nil);
    GHAssertEquals([iri type], kTXLTermTypeIRI, nil);
    
    GHAssertEqualObjects([iri iriValue], @"http://example.com/foo#bar", nil);
    GHAssertEqualObjects([iri description], @"<http://example.com/foo#bar>", nil);
}

- (void)testSaveIRI {
    NSError *error;
    TXLTerm *iri = [TXLTerm termWithIRI:@"http://example.com/foo#bar"];
    GHAssertFalse([iri isSavedInDatabase], nil);
    
    [iri save:&error];
    GHAssertTrue([iri isSavedInDatabase], nil);
    
    NSUInteger pk = iri.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, nil);
    
    GHAssertEqualObjects(iri, [[TXLTerm termWithIRI:@"http://example.com/foo#bar"] save:&error], nil);
    GHAssertEqualObjects([TXLTerm termWithPrimaryKey:iri.primaryKey], [TXLTerm termWithIRI:@"http://example.com/foo#bar"], nil);
}

- (void)testIsEqualIRI {
    GHAssertEqualObjects([TXLTerm termWithIRI:@"http://example.com/foo#bar"],
                         [TXLTerm termWithIRI:@"http://example.com/foo#bar"], nil);
}

#pragma mark Plain Literal

- (void)testCreatePlainLiteral {
    TXLTerm *lit = [TXLTerm termWithLiteral:@"Hallo!" language:@"de_DE"];
    
    GHAssertTrue([lit isType:kTXLTermTypePlainLiteral], nil);
    GHAssertEquals([lit type], kTXLTermTypePlainLiteral, nil);
    
    GHAssertEqualObjects([lit literalValue], @"Hallo!", nil);
    GHAssertEqualObjects([lit language], @"de_DE", nil);
    GHAssertEqualObjects([lit description], @"\"Hallo!\"@de_DE", nil);
}

- (void)testSavePlainLiteral {
    NSError *error;
    TXLTerm *lit = [TXLTerm termWithLiteral:@"Hallo!" language:@"de_DE"];
    GHAssertFalse([lit isSavedInDatabase], nil);
    
    [lit save:&error];
    GHAssertTrue([lit isSavedInDatabase], nil);
    
    NSUInteger pk = lit.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, nil);
    
    GHAssertEquals(lit.primaryKey, [[[TXLTerm termWithLiteral:@"Hallo!" language:@"de_DE"] save:&error] primaryKey], nil);
    GHAssertEqualObjects(lit, [[TXLTerm termWithLiteral:@"Hallo!" language:@"de_DE"] save:&error], nil);
    GHAssertEqualObjects([TXLTerm termWithPrimaryKey:lit.primaryKey], [TXLTerm termWithLiteral:@"Hallo!" language:@"de_DE"], nil);
}

#pragma mark Typed Literal

- (void)testCreateTypedLiteral {
    TXLTerm *lit = [TXLTerm termWithLiteral:@"baz" dataType:[TXLTerm termWithIRI:@"http://example.com/foo#bar"]];
    
    GHAssertTrue([lit isType:kTXLTermTypeTypedLiteral], nil);
    GHAssertEquals([lit type], kTXLTermTypeTypedLiteral, nil);
    
    GHAssertEqualObjects([lit literalValue], @"baz", nil);
    GHAssertEqualObjects([lit dataType], [TXLTerm termWithIRI:@"http://example.com/foo#bar"], nil);
    GHAssertEqualObjects([lit description], @"\"baz\"^^<http://example.com/foo#bar>", nil);
}

- (void)testSaveTypedLiteral {
    NSError *error;
    
    TXLTerm *lit = [TXLTerm termWithLiteral:@"baz" dataType:[TXLTerm termWithIRI:@"http://example.com/foo#bar"]];
    GHAssertFalse([lit isSavedInDatabase], nil);
    
    [lit save:&error];
    GHAssertTrue([lit isSavedInDatabase], nil);
    
    NSUInteger pk = lit.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, nil);
    
    GHAssertEquals(lit.primaryKey, [[[TXLTerm termWithLiteral:@"baz" dataType:[TXLTerm termWithIRI:@"http://example.com/foo#bar"]] save:&error] primaryKey], nil);
    GHAssertEqualObjects(lit, [[TXLTerm termWithLiteral:@"baz" dataType:[TXLTerm termWithIRI:@"http://example.com/foo#bar"]] save:&error], nil);
    GHAssertEqualObjects([TXLTerm termWithPrimaryKey:lit.primaryKey], [TXLTerm termWithLiteral:@"baz" dataType:[TXLTerm termWithIRI:@"http://example.com/foo#bar"]], nil);
}

#pragma mark Integer Literal

- (void)testCreateIntegerLiteral {
    TXLTerm *lit = [TXLTerm termWithInteger:1234567890];
    
    GHAssertTrue([lit isType:kTXLTermTypeIntegerLiteral], nil);
    GHAssertEquals([lit type], kTXLTermTypeIntegerLiteral, nil);
    
    GHAssertEqualObjects([lit numberValue], [NSNumber numberWithInteger:1234567890], nil);
    GHAssertEqualObjects([lit literalValue], @"1234567890", nil);
    GHAssertEqualObjects([lit dataType], [TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#integer"], nil);
    GHAssertEqualObjects([lit description], @"1234567890", nil);
}

- (void)testSaveIntegerLiteral {
    NSError *error;
    
    TXLTerm *lit = [TXLTerm termWithInteger:1234567890];
    GHAssertFalse([lit isSavedInDatabase], nil);
    
    [lit save:&error];
    GHAssertTrue([lit isSavedInDatabase], nil);
    
    NSUInteger pk = lit.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, nil);
    
    GHAssertEquals(lit.primaryKey, [[[TXLTerm termWithInteger:1234567890] save:&error] primaryKey], nil);
    GHAssertEqualObjects(lit, [[TXLTerm termWithInteger:1234567890] save:&error], nil);
    GHAssertEqualObjects([TXLTerm termWithPrimaryKey:lit.primaryKey], [TXLTerm termWithInteger:1234567890], nil);
}

- (void)testCreateIntegerWithTypedLiteral {
    TXLTerm *lit = [TXLTerm termWithLiteral:@"1234567890" dataType:[TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#integer"]];
    
    GHAssertTrue([lit isType:kTXLTermTypeIntegerLiteral], nil);
    GHAssertEquals([lit type], kTXLTermTypeIntegerLiteral, nil);
    
    GHAssertEqualObjects([lit numberValue], [NSNumber numberWithInteger:1234567890], nil);
    GHAssertEqualObjects([lit literalValue], @"1234567890", nil);
    GHAssertEqualObjects([lit dataType], [TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#integer"], nil);
    GHAssertEqualObjects([lit description], @"1234567890", nil);
}

#pragma mark Double Literal

- (void)testCreateDoubleLiteral {
    TXLTerm *lit = [TXLTerm termWithDouble:12.56];
    
    GHAssertTrue([lit isType:kTXLTermTypeDoubleLiteral], nil);
    GHAssertEquals([lit type], kTXLTermTypeDoubleLiteral, nil);
    
    GHAssertEqualObjects([lit numberValue], [NSNumber numberWithDouble:12.56], nil);
    GHAssertEqualObjects([lit literalValue], @"1.256000e+01", nil);
    GHAssertEqualObjects([lit dataType], [TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#double"], nil);
    GHAssertEqualObjects([lit description], @"1.256000e+01", nil);
}

- (void)testSaveDoubleLiteral {
    NSError *error;
    
    TXLTerm *lit = [TXLTerm termWithDouble:12.56];
    GHAssertFalse([lit isSavedInDatabase], nil);
    
    [lit save:&error];
    GHAssertTrue([lit isSavedInDatabase], nil);
    
    NSUInteger pk = lit.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, nil);
    
    GHAssertEquals(lit.primaryKey, [[[TXLTerm termWithDouble:12.56] save:&error] primaryKey], nil);
    GHAssertEqualObjects(lit, [[TXLTerm termWithDouble:12.56] save:&error], nil);
    GHAssertEqualObjects([TXLTerm termWithPrimaryKey:lit.primaryKey], [TXLTerm termWithDouble:12.56], nil);
}

- (void)testCreateDoubleWithTypedLiteral {
    TXLTerm *lit = [TXLTerm termWithLiteral:@"2.300000e-04" dataType:[TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#double"]];
    
    GHAssertTrue([lit isType:kTXLTermTypeDoubleLiteral], nil);
    GHAssertEquals([lit type], kTXLTermTypeDoubleLiteral, nil);
    
    GHAssertEqualObjects([lit numberValue], [NSNumber numberWithDouble:23e-5], nil);
    GHAssertEqualObjects([lit literalValue], @"2.300000e-04", nil);
    GHAssertEqualObjects([lit dataType], [TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#double"], nil);
    GHAssertEqualObjects([lit description], @"2.300000e-04", nil);
}

#pragma mark Boolean Literal

- (void)testCreateBooleanLiteral {
    TXLTerm *lit = [TXLTerm termWithBool:YES];
    
    GHAssertTrue([lit isType:kTXLTermTypeBooleanLiteral], nil);
    GHAssertEquals([lit type], kTXLTermTypeBooleanLiteral, nil);
    
    GHAssertTrue([lit booleanValue], nil);
    GHAssertEqualObjects([lit literalValue], @"true", nil);
    GHAssertEqualObjects([lit dataType], [TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#boolean"], nil);
    GHAssertEqualObjects([lit description], @"true", nil);
}

- (void)testSaveBooleanLiteral {
    NSError *error;
    
    TXLTerm *lit = [TXLTerm termWithBool:YES];
    GHAssertFalse([lit isSavedInDatabase], nil);
    
    [lit save:&error];
    GHAssertTrue([lit isSavedInDatabase], nil);
    
    NSUInteger pk = lit.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, nil);
    
    GHAssertEquals(lit.primaryKey, [[[TXLTerm termWithBool:YES] save:&error] primaryKey], nil);
    GHAssertEqualObjects(lit, [[TXLTerm termWithBool:YES] save:&error], nil);
    GHAssertEqualObjects([TXLTerm termWithPrimaryKey:lit.primaryKey], [TXLTerm termWithBool:YES], nil);
}

- (void)testCreateBooleanLiteralWithTypedLiteral {
    TXLTerm *lit = [TXLTerm termWithLiteral:@"true" dataType:[TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#boolean"]];
    GHAssertTrue([lit isType:kTXLTermTypeBooleanLiteral], nil);
    GHAssertEquals([lit type], kTXLTermTypeBooleanLiteral, nil);
    
    GHAssertTrue([lit booleanValue], nil);
    GHAssertEqualObjects([lit literalValue], @"true", nil);
    GHAssertEqualObjects([lit dataType], [TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#boolean"], nil);
    GHAssertEqualObjects([lit description], @"true", nil);
}

#pragma mark Date Time Literal

- (void)testCreateDateTimeLiteral {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    
    TXLTerm *lit = [TXLTerm termWithDate:date];
    
    GHAssertTrue([lit isType:kTXLTermTypeDateTimeLiteral], nil);
    GHAssertEquals([lit type], kTXLTermTypeDateTimeLiteral, nil);
    
    GHAssertEqualObjects([lit dateValue], date, nil);
    GHAssertEqualObjects([lit dataType], [TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#dateTime"], nil);
}

- (void)testSaveDateTimeLiteral {
    NSError *error;
    
    NSDate *date = [NSDate date];
    
    TXLTerm *lit = [TXLTerm termWithDate:date];
    GHAssertFalse([lit isSavedInDatabase], nil);
    
    [lit save:&error];
    GHAssertTrue([lit isSavedInDatabase], nil);
    
    NSUInteger pk = lit.primaryKey;
    GHAssertNotEquals(pk, (NSUInteger)0, nil);
    
    GHAssertEquals(lit.primaryKey, [[[TXLTerm termWithDate:date] save:&error] primaryKey], nil);
    GHAssertEqualObjects(lit, [[TXLTerm termWithDate:date] save:&error], nil);
    GHAssertEqualObjects([TXLTerm termWithPrimaryKey:lit.primaryKey], [TXLTerm termWithDate:date], nil);
}

@end






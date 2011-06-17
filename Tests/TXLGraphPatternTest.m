//  TXLGraphPatternTest.m
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

#import "TXLGraphPattern.h"
#import "TXLTerm.h"
#import "TXLStatement.h"
#import "TXLContext.h"
#import "TXLManager.h"
#import "TXLDatabase.h"
#import "TXLInteger.h"
#import "TXLRevision.h"
#import "TXLSPARQLCompiler.h"
#import "TXLQuery.h"

#define SQL(x) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

@interface TXLGraphPatternTest : GHAsyncTestCase {
    
}

- (BOOL)buildDataSet;
- (TXLGraphPattern *)buildQueryPattern1;
- (TXLGraphPattern *)buildQueryPattern2;
- (TXLGraphPattern *)buildQueryPattern3;
- (TXLGraphPattern *)buildQueryPattern4;
- (TXLGraphPattern *)buildQueryPattern5;
- (TXLGraphPattern *)buildQueryPattern6;
- (TXLGraphPattern *)buildQueryPattern7;
- (TXLGraphPattern *)buildQueryPattern8;

@end


@implementation TXLGraphPatternTest

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

- (BOOL)buildDataSet {
    
    /*
     * Data Set:
     * --------------------------------------
     * (_:x, http://schema.situmet.at/meteorology#temperature, warm)            at (always - everywhere) in context (txl://weather)
     * (_:x, http://schema.situmet.at/meteorology#temperature, 9.0)             at (always - everywhere) in context (txl://weather)
     * (_:x, http://schema.situmet.at/meteorology#rain, 1.1)                    at (always - everywhere) in context (txl://weather)
     * (_:x, http://schema.situmet.at/meteorology#sky_coverage, 10.0)           at (always - everywhere) in context (txl://weather)
     * (_:x, http://schema.situmet.at/meteorology#frost, 1.0)                   at (always - everywhere) in context (txl://weather/situmet/at/a)
     * (_:x, http://schema.situmet.at/meteorology#rain, 1.0)                    at (always - everywhere) in context (txl://weather/situmet/at/a)
     * (_:x, http://schema.situmet.at/meteorology#category, "rain")             at (always - everywhere) in context (txl://weather/situmet/at/a)
     * (_:x, http://schema.situmet.at/meteorology#temperature, 10.0)            at (always - everywhere) in context (txl://weather/situmet/at)
     * (_:x, http://schema.situmet.at/meteorology#temperature, 12.0)            at (always - everywhere) in context (txl://weather/situmet/at)
     * (_:x, http://schema.situmet.at/meteorology#rain, 1.0)                    at (always - everywhere) in context (txl://weather/situmet/at)
     * (_:x, http://schema.situmet.at/meteorology#temperature, 13.0)            at (always - everywhere) in context (txl://weather/situmet/de)
     * (_:x, http://schema.situmet.at/meteorology#temperature, warm)            at (always - everywhere) in context (txl://weather/situmet/de)
     * (_:x, http://schema.situmet.at/meteorology#sky_coverage, 11.0)           at (always - everywhere) in context (txl://weather/situmet/de)
     * (_:x, http://schema.situmet.at/meteorology#temperature, warm)            at (always - everywhere) in context (txl://weather/situmet/fr)
     * (_:x, http://schema.situmet.at/meteorology#rain, 1.0)                    at (always - everywhere) in context (txl://weather/situmet/fr)
     * (_:x, http://schema.situmet.at/meteorology#temperature, 10.0)            at (always - everywhere) in context (txl://weather/situmet/uk)
     * (_:x, http://schema.situmet.at/meteorology#temperature, warm)            at (always - everywhere) in context (txl://weather/situmet/po)
     * (_:x, http://schema.situmet.at/meteorology#temperature, 10.0)            at (always - everywhere) in context (txl://weather/situmet/po)
     * (_:x, http://schema.situmet.at/meteorology#temperature, warm)            at (always - everywhere) in context (txl://weather/situmet2)
     * (_:x, http://schema.situmet.at/meteorology#sky_coverage, 13.0)           at (always - everywhere) in context (txl://weather/situmet2/de/a/b)
     * (_:x, http://schema.situmet.at/meteorology#temperature, warm)            at (always - everywhere) in context (txl://weather/situmet3)
     * (_:x, http://schema.situmet.at/meteorology#rain, 10.0)                   at (always - everywhere) in context (txl://weather/situmet3/de/a/b)
     * (_:x, http://schema.situmet.at/meteorology#temperature, warm)            at (always - everywhere) in context (txl://weather/situmet4)
     * (_:x, http://schema.situmet.at/meteorology#sky_coverage, 13.0)           at (always - everywhere) in context (txl://weather/situmet4/de/a/b)
     * (_:x, http://schema.situmet.at/meteorology#rain, 10.0)                   at (always - everywhere) in context (txl://weather/situmet4/de/a/b/c)
     * (_:x, http://schema.situmet.at/meteorology#rain, 1.0)                    at (always - everywhere) in context (txl://weather/situmet5)
     * (_:x, http://schema.situmet.at/meteorology#temperature, warm)            at (always - everywhere) in context (txl://weather/situmet5/de/a/b/c)
     * (_:x, http://schema.situmet.at/meteorology#sky_coverage, 1.0)            at (always - everywhere) in context (txl://weather/situmet6)
     * (_:x, http://schema.situmet.at/meteorology#temperature, warm)            at (always - everywhere) in context (txl://weather/situmet6/de/a/b/c)
     * (_:x, http://schema.situmet.at/meteorology#rain, 1.0)                    at (always - everywhere) in context (txl://weather/situmet7)
     * (_:x, http://schema.situmet.at/meteorology#sky_coverage, 10.0)           at (always - everywhere) in context (txl://weather/situmet7/de/a/b)
     * (_:x, http://schema.situmet.at/meteorology#temperature, warm)            at (always - everywhere) in context (txl://weather/situmet7/de/a/b/c)
     * (_:x, http://schema.situmet.at/meteorology#rain, 1.0)                    at (always - everywhere) in context (txl://weather/situmet8)
     * (_:x, http://schema.situmet.at/meteorology#temperature, warm)            at (always - everywhere) in context (txl://weather/situmet8/de/a/b)
     * (_:x, http://schema.situmet.at/meteorology#sky_coverage, 10.0)           at (always - everywhere) in context (txl://weather/situmet8/de/a/b/c)
     * (_:x, http://schema.situmet.at/meteorology#temperature, warm)            at (always - everywhere) in context (txl://weather/situmet9/de/a/b/c)     
     * (_:x, http://schema.situmet.at/events#name, "Impressionism")             at (always - everywhere) in context (txl://events/situmet/at)
     * (_:x, http://schema.situmet.at/events#category, "art exhibition")        at (always - everywhere) in context (txl://events/situmet/at)
     * (_:x, http://schema.situmet.at/events#suitable_if, "storm")              at (always - everywhere) in context (txl://events/situmet/at)
     * (_:x, http://schema.situmet.at/events#suitable_if, "rain")               at (always - everywhere) in context (txl://events/situmet/at)
     * (_:y, http://schema.situmet.at/events#category, "musical")               at (always - everywhere) in context (txl://events/situmet/at)
     * (_:y, http://schema.situmet.at/events#suitable_if, "rain")               at (always - everywhere) in context (txl://events/situmet/at)
     * (_:z, http://schema.situmet.at/events#name, "ABCDEFG")                   at (always - everywhere) in context (txl://events/situmet/at)
     * (_:z, http://schema.situmet.at/events#category, "concert")               at (always - everywhere) in context (txl://events/situmet/at)
     * (_:u, http://schema.situmet.at/events#suitable_if, "flooding")           at (always - everywhere) in context (txl://events/situmet/at)
     * (_:x, http://schema.situmet.at/events#name, "Dogs")                      at (always - everywhere) in context (txl://events/situmet/at/vienna)
     * (_:x, http://schema.situmet.at/events#category, "musical")               at (always - everywhere) in context (txl://events/situmet/at/vienna)
     * (_:x, http://schema.situmet.at/events#suitable_if, "rain")               at (always - everywhere) in context (txl://events/situmet/at/vienna)
     * (_:x, http://schema.situmet.at/events#suitable_if, "cyclone")            at (always - everywhere) in context (txl://events/situmet/at/vienna)
     * (_:x, http://schema.situmet.at/events#suitable_if, "flooding")           at (always - everywhere) in context (txl://events/situmet/at/vienna)
     */
    
    [self prepare];
    
    __block NSError *error;
    
    // Create terms
    TXLTerm *subject = [TXLTerm termWithBlankNode:@"x"];
    TXLTerm *subject2 = [TXLTerm termWithBlankNode:@"y"];
    TXLTerm *subject3 = [TXLTerm termWithBlankNode:@"z"];
    TXLTerm *subject4 = [TXLTerm termWithBlankNode:@"u"];
    TXLTerm *predicate = [TXLTerm termWithIRI:@"http://schema.situmet.at/meteorology#temperature"];
    TXLTerm *predicate2 = [TXLTerm termWithIRI:@"http://schema.situmet.at/meteorology#rain"];
    TXLTerm *predicate3 = [TXLTerm termWithIRI:@"http://schema.situmet.at/meteorology#sky_coverage"];
    TXLTerm *predicate4 = [TXLTerm termWithIRI:@"http://schema.situmet.at/meteorology#frost"];
    TXLTerm *predicate5 = [TXLTerm termWithIRI:@"http://schema.situmet.at/events#name"];
    TXLTerm *predicate6 = [TXLTerm termWithIRI:@"http://schema.situmet.at/events#category"];
    TXLTerm *predicate7 = [TXLTerm termWithIRI:@"http://schema.situmet.at/events#suitable_if"];
    TXLTerm *predicate8 = [TXLTerm termWithIRI:@"http://schema.situmet.at/meteorology#category"];
    TXLTerm *object1 = [TXLTerm termWithDouble:10.0];
    TXLTerm *object2 = [TXLTerm termWithDouble:12.0];
    TXLTerm *object3 = [TXLTerm termWithDouble:13.0];
    TXLTerm *object4 = [TXLTerm termWithDouble:9.0];
    TXLTerm *object5 = [TXLTerm termWithDouble:11.0];
    TXLTerm *object6 = [TXLTerm termWithDouble:1.0];
    TXLTerm *object7 = [TXLTerm termWithDouble:1.1];
    TXLTerm *object8 = [TXLTerm termWithLiteral:@"warm"];
    TXLTerm *object9 = [TXLTerm termWithLiteral:@"Impressionism"];
    TXLTerm *object10 = [TXLTerm termWithLiteral:@"art exhibition"];
    TXLTerm *object11 = [TXLTerm termWithLiteral:@"storm"];
    TXLTerm *object12 = [TXLTerm termWithLiteral:@"rain"];
    TXLTerm *object13 = [TXLTerm termWithLiteral:@"musical"];
    TXLTerm *object14 = [TXLTerm termWithLiteral:@"ABCDEFG"];
    TXLTerm *object15 = [TXLTerm termWithLiteral:@"concert"];
    TXLTerm *object16 = [TXLTerm termWithLiteral:@"Dogs"];
    TXLTerm *object17 = [TXLTerm termWithLiteral:@"cyclone"];
    TXLTerm *object18 = [TXLTerm termWithLiteral:@"flooding"];
    
    // Create statements
    TXLStatement *statement1 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object1];
    TXLStatement *statement2 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object2];    
    TXLStatement *statement3 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object3];    
    TXLStatement *statement4 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object4];    
    TXLStatement *statement5 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate
                                                           object:object8];    
    TXLStatement *statement6 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate2
                                                           object:object6];    
    TXLStatement *statement7 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate2
                                                           object:object7];   
    TXLStatement *statement8 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate3
                                                           object:object1];   
    TXLStatement *statement9 = [TXLStatement statementWithSubject:subject
                                                        predicate:predicate3
                                                           object:object5];   
    TXLStatement *statement10 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate
                                                            object:object8];  
    TXLStatement *statement11 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate4
                                                            object:object6];  
    TXLStatement *statement12 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate2
                                                            object:object6];  
    TXLStatement *statement13 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate
                                                            object:object8];  
    TXLStatement *statement14 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate3
                                                            object:object3];  
    TXLStatement *statement15 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate
                                                            object:object8];  
    TXLStatement *statement16 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate2
                                                            object:object1];  
    TXLStatement *statement17 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate
                                                            object:object8];  
    TXLStatement *statement18 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate3
                                                            object:object3];  
    TXLStatement *statement19 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate2
                                                            object:object1];  
    TXLStatement *statement20 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate2
                                                            object:object6];  
    TXLStatement *statement21 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate
                                                            object:object8];  
    TXLStatement *statement22 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate3
                                                            object:object6];  
    TXLStatement *statement23 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate
                                                            object:object8];  
    TXLStatement *statement24 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate2
                                                            object:object6];  
    TXLStatement *statement25 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate3
                                                            object:object1];  
    TXLStatement *statement26 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate
                                                            object:object8];  
    TXLStatement *statement27 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate2
                                                            object:object6];  
    TXLStatement *statement28 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate
                                                            object:object8];  
    TXLStatement *statement29 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate3
                                                            object:object1];  
    TXLStatement *statement30 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate
                                                            object:object8];  
    TXLStatement *statement31 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate5
                                                            object:object9];
    TXLStatement *statement32 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate6
                                                            object:object10];
    TXLStatement *statement33 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate7
                                                            object:object11];
    TXLStatement *statement34 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate7
                                                            object:object12];
    TXLStatement *statement35 = [TXLStatement statementWithSubject:subject2
                                                         predicate:predicate6
                                                            object:object13];
    TXLStatement *statement36 = [TXLStatement statementWithSubject:subject2
                                                         predicate:predicate7
                                                            object:object12];
    TXLStatement *statement37 = [TXLStatement statementWithSubject:subject3
                                                         predicate:predicate5
                                                            object:object14];
    TXLStatement *statement38 = [TXLStatement statementWithSubject:subject3
                                                         predicate:predicate6
                                                            object:object15];
    TXLStatement *statement39 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate5
                                                            object:object16];
    TXLStatement *statement40 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate6
                                                            object:object13];
    TXLStatement *statement41 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate7
                                                            object:object12];
    TXLStatement *statement42 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate7
                                                            object:object17];
    TXLStatement *statement43 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate7
                                                            object:object18];
    TXLStatement *statement44 = [TXLStatement statementWithSubject:subject
                                                         predicate:predicate8
                                                            object:object12];
    TXLStatement *statement45 = [TXLStatement statementWithSubject:subject4
                                                         predicate:predicate7
                                                            object:object18];
    
    // Create contexts
    
    TXLContext *context1 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", nil]
                                                                    error:&error];
    GHAssertNotNil(context1, [error localizedDescription]);
    TXLContext *context2 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"de", nil]
                                                                    error:&error];
    GHAssertNotNil(context2, [error localizedDescription]);
    TXLContext *context3 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray array]
                                                                    error:&error];
    GHAssertNotNil(context3, [error localizedDescription]);
    TXLContext *context4 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"fr", nil]
                                                                    error:&error];
    GHAssertNotNil(context4, [error localizedDescription]);
    TXLContext *context5 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"uk", nil]
                                                                    error:&error];
    GHAssertNotNil(context5, [error localizedDescription]);
    TXLContext *context6 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"po", nil]
                                                                    error:&error];
    GHAssertNotNil(context6, [error localizedDescription]);
    TXLContext *context7 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", @"a", nil]
                                                                    error:&error];
    GHAssertNotNil(context7, [error localizedDescription]);
    TXLContext *context8 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet2", nil]
                                                                    error:&error];
    GHAssertNotNil(context8, [error localizedDescription]);
    TXLContext *context9 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet2", @"de", @"a", @"b", nil]
                                                                    error:&error];
    GHAssertNotNil(context9, [error localizedDescription]);
    TXLContext *context10 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet3", nil]
                                                                     error:&error];
    GHAssertNotNil(context10, [error localizedDescription]);
    TXLContext *context11 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet3", @"de", @"a", @"b", nil]
                                                                     error:&error];
    GHAssertNotNil(context11, [error localizedDescription]);
    TXLContext *context12 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet4", nil]
                                                                     error:&error];
    GHAssertNotNil(context12, [error localizedDescription]);
    TXLContext *context13 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet4", @"de", @"a", @"b", nil]
                                                                     error:&error];
    GHAssertNotNil(context13, [error localizedDescription]);
    TXLContext *context14 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet4", @"de", @"a", @"b", @"c", nil]
                                                                     error:&error];
    GHAssertNotNil(context14, [error localizedDescription]);
    TXLContext *context15 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet5", nil]
                                                                     error:&error];
    GHAssertNotNil(context15, [error localizedDescription]);
    TXLContext *context16 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet5", @"de", @"a", @"b", @"c", nil]
                                                                     error:&error];
    GHAssertNotNil(context16, [error localizedDescription]);
    TXLContext *context17 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet6", nil]
                                                                     error:&error];
    GHAssertNotNil(context17, [error localizedDescription]);
    TXLContext *context18 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet6", @"de", @"a", @"b", @"c", nil]
                                                                     error:&error];
    GHAssertNotNil(context18, [error localizedDescription]);
    TXLContext *context19 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet7", nil]
                                                                     error:&error];
    GHAssertNotNil(context19, [error localizedDescription]);
    TXLContext *context20= [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet7", @"de", @"a", @"b", nil]
                                                                    error:&error];
    GHAssertNotNil(context20, [error localizedDescription]);
    TXLContext *context21 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet7", @"de", @"a", @"b", @"c", nil]
                                                                     error:&error];
    GHAssertNotNil(context21, [error localizedDescription]);
    TXLContext *context22 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet8", nil]
                                                                     error:&error];
    GHAssertNotNil(context22, [error localizedDescription]);
    TXLContext *context23 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet8", @"de", @"a", @"b", nil]
                                                                     error:&error];
    GHAssertNotNil(context23, [error localizedDescription]);
    TXLContext *context24 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet8", @"de", @"a", @"b", @"c", nil]
                                                                     error:&error];
    GHAssertNotNil(context24, [error localizedDescription]);
    TXLContext *context25 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet9", @"de", @"a", @"b", @"c", nil]
                                                                     error:&error];
    GHAssertNotNil(context25, [error localizedDescription]);
    TXLContext *context26 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"events"
                                                                      path:[NSArray arrayWithObjects:@"situmet", @"at", nil]
                                                                     error:&error];
    GHAssertNotNil(context26, [error localizedDescription]);
    TXLContext *context27 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"events"
                                                                      path:[NSArray arrayWithObjects:@"situmet", @"at", @"vienna", nil]
                                                                     error:&error];
    GHAssertNotNil(context27, [error localizedDescription]);
    
    // Create statement sets, each set for a specific context
    __block NSArray *statementSet1 = [NSArray arrayWithObjects:statement1, 
                                      statement2,
                                      statement6,
                                      nil];
    __block NSArray *statementSet2 = [NSArray arrayWithObjects:statement3,
                                      statement9,
                                      statement10,
                                      nil];
    __block NSArray *statementSet3 = [NSArray arrayWithObjects:statement4,
                                      statement5,
                                      statement7,
                                      statement8,
                                      nil];
    __block NSArray *statementSet4 = [NSArray arrayWithObjects:statement10,
                                      statement6,
                                      nil];
    __block NSArray *statementSet5 = [NSArray arrayWithObjects:statement1,
                                      nil];
    __block NSArray *statementSet6 = [NSArray arrayWithObjects:statement10,
                                      statement1,
                                      nil];
    __block NSArray *statementSet7 = [NSArray arrayWithObjects:statement11,
                                      statement12,
                                      statement44,
                                      nil];
    __block NSArray *statementSet8 = [NSArray arrayWithObjects:statement13,
                                      nil];
    __block NSArray *statementSet9 = [NSArray arrayWithObjects:statement14,
                                      nil];
    __block NSArray *statementSet10 = [NSArray arrayWithObjects:statement15,
                                       nil];
    __block NSArray *statementSet11 = [NSArray arrayWithObjects:statement16,
                                       nil];
    __block NSArray *statementSet12 = [NSArray arrayWithObjects:statement17,
                                       nil];
    __block NSArray *statementSet13 = [NSArray arrayWithObjects:statement18,
                                       nil];
    __block NSArray *statementSet14 = [NSArray arrayWithObjects:statement19,
                                       nil];
    __block NSArray *statementSet15 = [NSArray arrayWithObjects:statement20,
                                       nil];
    __block NSArray *statementSet16 = [NSArray arrayWithObjects:statement21,
                                       nil];
    __block NSArray *statementSet17 = [NSArray arrayWithObjects:statement22,
                                       nil];
    __block NSArray *statementSet18 = [NSArray arrayWithObjects:statement23,
                                       nil];
    __block NSArray *statementSet19 = [NSArray arrayWithObjects:statement24,
                                       nil];
    __block NSArray *statementSet20 = [NSArray arrayWithObjects:statement25,
                                       nil];
    __block NSArray *statementSet21 = [NSArray arrayWithObjects:statement26,
                                       nil];
    __block NSArray *statementSet22 = [NSArray arrayWithObjects:statement27,
                                       nil];
    __block NSArray *statementSet23 = [NSArray arrayWithObjects:statement28,
                                       nil];
    __block NSArray *statementSet24 = [NSArray arrayWithObjects:statement29,
                                       nil];
    __block NSArray *statementSet25 = [NSArray arrayWithObjects:statement30,
                                       nil];
    __block NSArray *statementSet26 = [NSArray arrayWithObjects:statement31,
                                       statement32,
                                       statement33,
                                       statement34,
                                       statement35,
                                       statement36,
                                       statement37,
                                       statement38,
                                       statement45,
                                       nil];
    __block NSArray *statementSet27 = [NSArray arrayWithObjects:statement39,
                                       statement40,
                                       statement41,
                                       statement42,
                                       statement43,
                                       nil];
    // ---------------------------------------
    
    // Update Contexts
    
    __block void (^saveStatementSets)(NSMutableArray *,
                                      NSMutableArray *);
    saveStatementSets = ^(NSMutableArray *contexts,
                          NSMutableArray* statementSets) {
        
        if ([contexts count] > 0 &&
            [statementSets count] > 0) {
            
            TXLContext *context = [contexts lastObject];
            NSArray *statementSet = [statementSets lastObject];
            
            [context updateWithStatements:statementSet
                          completionBlock:^(TXLRevision *r, NSError *e){
                       
                              if (r != nil) {
                                  
                                  [contexts removeLastObject];
                                  [statementSets removeLastObject];
                                  
                                  saveStatementSets(contexts,
                                                    statementSets);
                                  
                              } else {
                                  
                                  error = [e retain];
                                  
                                  // ---------------------------------------
                                  // Notify the successful end of the operation.
                                  [self notify:kGHUnitWaitStatusSuccess];
                                  
                              }
                              
                          }];            
            
        } else {
            // ---------------------------------------
            // Notify the successful end of the operation.
            [self notify:kGHUnitWaitStatusSuccess];
        }
        
    };
    
    saveStatementSets([NSMutableArray arrayWithObjects:
                       context1,
                       context2,
                       context3,
                       context4,
                       context5,
                       context6,
                       context7,
                       context8,
                       context9,
                       context10,
                       context11,
                       context12,
                       context13,
                       context14,
                       context15,
                       context16,
                       context17,
                       context18,
                       context19,
                       context20,
                       context21,
                       context22,
                       context23,
                       context24,
                       context25,
                       context26,
                       context27,
                       nil],
                      [NSMutableArray arrayWithObjects:
                       statementSet1,
                       statementSet2,
                       statementSet3,
                       statementSet4,
                       statementSet5,
                       statementSet6,
                       statementSet7,
                       statementSet8,
                       statementSet9,
                       statementSet10,
                       statementSet11,
                       statementSet12,
                       statementSet13,
                       statementSet14,
                       statementSet15,
                       statementSet16,
                       statementSet17,
                       statementSet18,
                       statementSet19,
                       statementSet20,
                       statementSet21,
                       statementSet22,
                       statementSet23,
                       statementSet24,
                       statementSet25,
                       statementSet26,
                       statementSet27,
                       nil]);
    
    // Wait for completion
    [self waitForStatus:kGHUnitWaitStatusSuccess
                timeout:10.0];
    
    if (error != nil) {
        return FALSE;
    } else {
        return TRUE;
    }
    
}

- (TXLGraphPattern *)buildQueryPattern1 {
    
    /*
     * Query Pattern: { [m:temperature ?temp]. }
     */
    
    NSError *error;
    
    TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> SELECT ?temp FROM <txl://weather.situmet.at> WHERE { [m:temperature ?temp]. }" 
                                                         parameters:nil 
                                                            options:nil 
                                                              error:&error];
    
    if (query == nil) {
        [NSException raise:@"TXLGraphPatternTestException" format:@"Could not compile query: %@", [error localizedDescription]];
    }
    
    return [query queryPattern];
    
}

- (TXLGraphPattern *)buildQueryPattern2 {
    
    /*
     * Query Pattern: { [m:rain ?rain]. }
     */
    
    NSError *error;
    
    TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> SELECT ?rain FROM <txl://weather.situmet.at> WHERE { [m:rain ?rain]. }" 
                                                         parameters:nil 
                                                            options:nil 
                                                              error:&error];
    
    if (query == nil) {
        [NSException raise:@"TXLGraphPatternTestException" format:@"Could not compile query: %@", [error localizedDescription]];
    }
    
    return [query queryPattern];
    
}

- (TXLGraphPattern *)buildQueryPattern3 {
    
    /*
     * Query Pattern: { [m:frost ?frost]. }
     */
    
    NSError *error;
    
    TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> SELECT ?frost FROM <txl://weather.situmet.at> WHERE { [m:frost ?frost]. }" 
                                                         parameters:nil 
                                                            options:nil 
                                                              error:&error];
    
    if (query == nil) {
        [NSException raise:@"TXLGraphPatternTestException" format:@"Could not compile query: %@", [error localizedDescription]];
    }
    
    return [query queryPattern];
    
}

- (TXLGraphPattern *)buildQueryPattern4 {
    
    /*
     * Query Pattern: { [m:temperature "warm"]. NOT EXISTS { [m:rain []]. } NOT EXISTS { [m:sky_coverage []]. }}
     */
    
    NSError *error;
    
    TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> ASK FROM <txl://weather.situmet.at> WHERE { [m:temperature \"warm\"]. NOT EXISTS { [m:rain []]. } NOT EXISTS { [m:sky_coverage []]. } }" 
                                                         parameters:nil 
                                                            options:nil 
                                                              error:&error];
    
    if (query == nil) {
        [NSException raise:@"TXLGraphPatternTestException" format:@"Could not compile query: %@", [error localizedDescription]];
    }
    
    return [query queryPattern];
    
}

- (TXLGraphPattern *)buildQueryPattern5 {
    
    /*
     * Query Pattern: { NOT EXISTS { [m:rain []]. } NOT EXISTS { [m:sky_coverage []]. }}
     */
    
    NSError *error;
    
    TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> ASK FROM <txl://weather.situmet.at> WHERE { NOT EXISTS { [m:rain []]. } NOT EXISTS { [m:sky_coverage []]. } }" 
                                                         parameters:nil 
                                                            options:nil 
                                                              error:&error];
    
    if (query == nil) {
        [NSException raise:@"TXLGraphPatternTestException" format:@"Could not compile query: %@", [error localizedDescription]];
    }
    
    return [query queryPattern];
    
}

- (TXLGraphPattern *)buildQueryPattern6 {
    
    /*
     * Query Pattern: { NOT EXISTS { [m:rain 1.1]. } NOT EXISTS { [m:sky_coverage []]. } NOT EXISTS { [m:frost []]. }}
     */
    
    NSError *error;
    
    TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> ASK FROM <txl://weather.situmet.at> WHERE { NOT EXISTS { [m:rain 1.1]. } NOT EXISTS { [m:sky_coverage []]. } NOT EXISTS { [m:frost []]. } }" 
                                                         parameters:nil 
                                                            options:nil 
                                                              error:&error];
    
    if (query == nil) {
        [NSException raise:@"TXLGraphPatternTestException" format:@"Could not compile query: %@", [error localizedDescription]];
    }
    
    return [query queryPattern];
    
}

- (TXLGraphPattern *)buildQueryPattern7 {
    
    /*
     * Query Pattern: { [e:name ?name; e:category ?category; e:suitable_if ?suitable_if]. }
     */
    
    NSError *error;
    
    TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX e: <http://schema.situmet.at/events#> SELECT ?name ?category ?suitable_if FROM <txl://events.situmet.at> WHERE { [e:name ?name; e:category ?category; e:suitable_if ?suitable_if]. }" 
                                                         parameters:nil 
                                                            options:nil 
                                                              error:&error];
    
    if (query == nil) {
        [NSException raise:@"TXLGraphPatternTestException" format:@"Could not compile query: %@", [error localizedDescription]];
    }
    
    return [query queryPattern];
    
}

- (TXLGraphPattern *)buildQueryPattern8 {
    
    /*
     * Query Pattern: { ?event e:suitable_if ?s. [m:category ?s]. }
     */
    
    NSError *error;
    
    TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX e: <http://schema.situmet.at/events#> PREFIX m: <http://schema.situmet.at/meteorology#> SELECT ?event ?s FROM <txl://events.situmet.at> FROM <txl://weather.situmet.at> WHERE { ?event e:suitable_if ?s. [m:category ?s]. }" 
                                                         parameters:nil 
                                                            options:nil 
                                                              error:&error];
    
    if (query == nil) {
        [NSException raise:@"TXLGraphPatternTestException" format:@"Could not compile query: %@", [error localizedDescription]];
    }
    
    return [query queryPattern];
    
}

- (void)testEvaluateQueryPattern1WithoutWindowConstraints {
    
    // without window constraints means, that any statement is specified without a window constraint
    // so any statement is valid always everywhere and we try to evaluate the query pattern 
    // over these statements without any window constraint, so we try to find matches 
    // for a query pattern at any time and at any geographical point without such restrictions
    
    NSError *error;
    
    GHAssertTrue([self buildDataSet], @"building dataset failed!");
    
    TXLInteger *queryPatternPk = [TXLInteger integerWithValue:[[self buildQueryPattern1] primaryKey]];
    
    // ---------------------------------------------------------------------------------
    // preparations for evaluating the basic graph pattern
    // ---------------------------------------------------------------------------------
    
    NSDictionary *vars = [NSDictionary dictionary];
    
    TXLGraphPattern *graphPattern = [TXLGraphPattern graphPatternWithPrimaryKey:[queryPatternPk intValue]];    
    
    TXLContext *context1 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", nil]
                                                                    error:&error];
    GHAssertNotNil(context1, [error localizedDescription]);
    TXLContext *context2 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"de", nil]
                                                                    error:&error];
    GHAssertNotNil(context2, [error localizedDescription]);
    TXLContext *context3 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray array]
                                                                    error:&error];
    GHAssertNotNil(context3, [error localizedDescription]);
    TXLContext *context4 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"ch", nil]
                                                                    error:&error];
    GHAssertNotNil(context4, [error localizedDescription]);
    TXLContext *context5 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", @"a", nil]
                                                                    error:&error];
    GHAssertNotNil(context5, [error localizedDescription]);
    
    TXLRevision *rev = [[TXLManager sharedManager] headRevision];
    
    BOOL found = FALSE;            
    
    NSMutableArray *results = [NSMutableArray array];
    
    // ---------------------------------------------------------------------------------
    // test evaluate pattern
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has only a direct child context and no
    // deeper relationships, where temperature is defined once in the context but not
    // in the direct child context
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context1]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 2 results - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 2, @"2 results should be found - but there were (%d results) found!", [results count]);
    NSMutableArray *temperature = [NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithDouble:10.0], 
                                   [NSNumber numberWithDouble:12.0], 
                                   nil];
    for (NSDictionary *res in results) {
        for (TXLInteger *val in [res allValues]) {
            NSNumber *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] numberValue];
            [temperature removeObject:temp];
        }
    }
    GHAssertTrue([temperature count] == 0, @"Not all statements were found - (%d) statements were not found!", [temperature count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no child contexts, 
    // where temperature is defined twice in the context
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context2]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 2 result - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 2, @"2 result should be found - but there were (%d results) found!", [results count]);
    temperature = [NSMutableArray arrayWithObjects:
                   [NSNumber numberWithDouble:13.0],
                   @"warm",
                   nil];
    for (NSDictionary *res in results) {
        for (TXLInteger *val in [res allValues]) {
            NSNumber *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] numberValue];
            if (temp != nil) {
                [temperature removeObject:temp];
            } else {
                NSString *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] literalValue];
                if (temp != nil) {
                    [temperature removeObject:temp];
                }
            }
            
        }
    }
    GHAssertTrue([temperature count] == 0, @"Not all statements were found - (%d) statements were not found!", [temperature count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has several direct child contexts and
    // deeper relationships, where temperature is defined in the context and
    // in some direct child contexts several times but not in deeper relationships
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context3]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 10 result - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 18, @"18 result should be found - but there were (%d results) found!", [results count]);
    temperature = [NSMutableArray arrayWithObjects:
                   [NSNumber numberWithDouble:9.0],
                   [NSNumber numberWithDouble:10.0],
                   [NSNumber numberWithDouble:10.0],
                   [NSNumber numberWithDouble:10.0],
                   [NSNumber numberWithDouble:12.0],
                   [NSNumber numberWithDouble:13.0],
                   @"warm",
                   @"warm",
                   @"warm",
                   @"warm",
                   @"warm",
                   @"warm",
                   @"warm",
                   @"warm",
                   @"warm",
                   @"warm",
                   @"warm",
                   @"warm",
                   nil];
    for (NSDictionary *res in results) {
        for (TXLInteger *val in [res allValues]) {
            NSNumber *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] numberValue];
            if (temp != nil) {
                [temperature removeObject:temp];
            } else {
                NSString *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] literalValue];
                if (temp != nil) {
                    [temperature removeObject:temp];
                }
            }
            
        }
    }
    GHAssertTrue([temperature count] == 0, @"Not all statements were found - (%d) statements were not found!", [temperature count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, that does not exist
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context4]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into zero results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 result should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, where temperature is not defined
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context5]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into zero results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 result should be found - but there were (%d results) found!", [results count]);
    
}

- (void)testEvaluateQueryPattern2WithoutWindowConstraints {
    
    // without window constraints means, that any statement is specified without a window constraint
    // so any statement is valid always everywhere and we try to evaluate the query pattern 
    // over these statements without any window constraint, so we try to find matches 
    // for a query pattern at any time and at any geographical point without such restrictions
    
    NSError *error;
    
    GHAssertTrue([self buildDataSet], @"building dataset failed!");
    
    TXLInteger *queryPatternPk = [TXLInteger integerWithValue:[[self buildQueryPattern2] primaryKey]];
    
    // ---------------------------------------------------------------------------------
    // preparations for evaluating the basic graph pattern
    // ---------------------------------------------------------------------------------
    
    NSDictionary *vars = [NSDictionary dictionary];
    
    TXLGraphPattern *graphPattern = [TXLGraphPattern graphPatternWithPrimaryKey:[queryPatternPk intValue]];    
    
    TXLContext *context1 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", nil]
                                                                    error:&error];
    GHAssertNotNil(context1, [error localizedDescription]);
    TXLContext *context2 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"de", nil]
                                                                    error:&error];
    GHAssertNotNil(context2, [error localizedDescription]);
    TXLContext *context3 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray array]
                                                                    error:&error];
    GHAssertNotNil(context3, [error localizedDescription]);
    TXLContext *context4 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", @"a", nil]
                                                                    error:&error];
    GHAssertNotNil(context4, [error localizedDescription]);
    
    TXLRevision *rev = [[TXLManager sharedManager] headRevision];
    
    BOOL found = FALSE;            
    
    NSMutableArray *results = [NSMutableArray array];
    
    // ---------------------------------------------------------------------------------
    // test evaluate pattern
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has only a direct child context and no
    // deeper relationships, where rain is defined once in the context
    // and once in the direct child context
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context1]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 1 results - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 2, @"2 results should be found - but there were (%d results) found!", [results count]);
    NSMutableArray *rain = [NSMutableArray arrayWithObjects:
                            [NSNumber numberWithDouble:1.0],
                            [NSNumber numberWithDouble:1.0],
                            nil];
    for (NSDictionary *res in results) {
        for (TXLInteger *val in [res allValues]) {
            NSNumber *r = [[TXLTerm termWithPrimaryKey:[val integerValue]] numberValue];
            [rain removeObject:r];
        }
    }
    GHAssertTrue([rain count] == 0, @"Not all statements were found - (%d) statements were not found!", [rain count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, where rain is not defined
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context2]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has several direct child contexts and several
    // deeper relationships, where rain is defined in the context, in some direct child contexts
    // and in some deeper relationships several times
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context3]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 3 result - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 9, @"9 results should be found - but there were (%d results) found!", [results count]);
    rain = [NSMutableArray arrayWithObjects:
            [NSNumber numberWithDouble:1.0],
            [NSNumber numberWithDouble:1.0],
            [NSNumber numberWithDouble:1.0],
            [NSNumber numberWithDouble:1.1],
            [NSNumber numberWithDouble:1.0],
            [NSNumber numberWithDouble:1.0],
            [NSNumber numberWithDouble:1.0],
            [NSNumber numberWithDouble:10.0],
            [NSNumber numberWithDouble:10.0],
            nil];
    for (NSDictionary *res in results) {
        for (TXLInteger *val in [res allValues]) {
            NSNumber *r = [[TXLTerm termWithPrimaryKey:[val integerValue]] numberValue];
            [rain removeObject:r];
        }
    }
    GHAssertTrue([rain count] == 0, @"Not all statements were found - (%d) statements were not found!", [rain count]);            
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a deeper context, which has no child context,
    // where rain is defined once
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context4]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 3 result - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 1, @"1 result should be found - but there were (%d results) found!", [results count]);
    rain = [NSMutableArray arrayWithObjects:
            [NSNumber numberWithDouble:1.0],
            nil];
    for (NSDictionary *res in results) {
        for (TXLInteger *val in [res allValues]) {
            NSNumber *r = [[TXLTerm termWithPrimaryKey:[val integerValue]] numberValue];
            [rain removeObject:r];
        }
    }
    GHAssertTrue([rain count] == 0, @"Not all statements were found - (%d) statements were not found!", [rain count]);      
    
}

- (void)testEvaluateQueryPattern3WithoutWindowConstraints {
    
    // without window constraints means, that any statement is specified without a window constraint
    // so any statement is valid always everywhere and we try to evaluate the query pattern 
    // over these statements without any window constraint, so we try to find matches 
    // for a query pattern at any time and at any geographical point without such restrictions
    
    NSError *error;
    
    GHAssertTrue([self buildDataSet], @"building dataset failed!");
    
    TXLInteger *queryPatternPk = [TXLInteger integerWithValue:[[self buildQueryPattern3] primaryKey]];
    
    // ---------------------------------------------------------------------------------
    // preparations for evaluating the basic graph pattern
    // ---------------------------------------------------------------------------------
    
    NSDictionary *vars = [NSDictionary dictionary];
    
    TXLGraphPattern *graphPattern = [TXLGraphPattern graphPatternWithPrimaryKey:[queryPatternPk intValue]];    
    
    TXLContext *context1 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", nil]
                                                                    error:&error];
    GHAssertNotNil(context1, [error localizedDescription]);
    TXLContext *context2 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"de", nil]
                                                                    error:&error];
    GHAssertNotNil(context2, [error localizedDescription]);
    TXLContext *context3 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray array]
                                                                    error:&error];
    GHAssertNotNil(context3, [error localizedDescription]);
    TXLContext *context4 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", @"a", nil]
                                                                    error:&error];
    GHAssertNotNil(context4, [error localizedDescription]);
    
    TXLRevision *rev = [[TXLManager sharedManager] headRevision];
    
    BOOL found = FALSE;            
    
    NSMutableArray *results = [NSMutableArray array];
    
    // ---------------------------------------------------------------------------------
    // test evaluate pattern
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has only a direct child context and no
    // deeper relationships, where frost is not defined in the context
    // but once in the direct child context
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context1]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 2 results - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 1, @"1 result should be found - but there were (%d results) found!", [results count]);
    NSMutableArray *temperature = [NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithDouble:1.0], 
                                   nil];
    for (NSDictionary *res in results) {
        for (TXLInteger *val in [res allValues]) {
            NSNumber *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] numberValue];
            [temperature removeObject:temp];
        }
    }
    GHAssertTrue([temperature count] == 0, @"Not all statements were found - (%d) statements were not found!", [temperature count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, where frost is not defined
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context2]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into zero results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has several direct child contexts and several
    // deeper relationships, where frost is not defined in the context and not defined
    // in the direct child contexts but once in one deeper relationship
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context3]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 2 result - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 1, @"1 result should be found - but there were (%d results) found!", [results count]);
    temperature = [NSMutableArray arrayWithObjects:
                   [NSNumber numberWithDouble:1.0],
                   nil];
    for (NSDictionary *res in results) {
        for (TXLInteger *val in [res allValues]) {
            NSNumber *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] numberValue];
            if (temp != nil) {
                [temperature removeObject:temp];
            } else {
                NSString *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] literalValue];
                if (temp != nil) {
                    [temperature removeObject:temp];
                }
            }
            
        }
    }
    GHAssertTrue([temperature count] == 0, @"Not all statements were found - (%d) statements were not found!", [temperature count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a deeper context, where frost is defined once
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context4]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 10 result - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 1, @"1 result should be found - but there were (%d results) found!", [results count]);
    temperature = [NSMutableArray arrayWithObjects:
                   [NSNumber numberWithDouble:1.0],
                   nil];
    for (NSDictionary *res in results) {
        for (TXLInteger *val in [res allValues]) {
            NSNumber *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] numberValue];
            if (temp != nil) {
                [temperature removeObject:temp];
            } else {
                NSString *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] literalValue];
                if (temp != nil) {
                    [temperature removeObject:temp];
                }
            }
            
        }
    }
    GHAssertTrue([temperature count] == 0, @"Not all statements were found - (%d) statements were not found!", [temperature count]);
    
}

- (void)testEvaluateQueryPattern4WithoutWindowConstraints {
    
    // without window constraints means, that any statement is specified without a window constraint
    // so any statement is valid always everywhere and we try to evaluate the query pattern 
    // over these statements without any window constraint, so we try to find matches 
    // for a query pattern at any time and at any geographical point without such restrictions
    
    NSError *error;
    
    GHAssertTrue([self buildDataSet], @"building dataset failed!");
    
    TXLInteger *queryPatternPk = [TXLInteger integerWithValue:[[self buildQueryPattern4] primaryKey]];
    
    // ---------------------------------------------------------------------------------
    // preparations for evaluating the basic graph pattern
    // ---------------------------------------------------------------------------------
    
    NSDictionary *vars = [NSDictionary dictionary];
    
    TXLGraphPattern *graphPattern = [TXLGraphPattern graphPatternWithPrimaryKey:[queryPatternPk intValue]];    
    
    TXLContext *context1 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", nil]
                                                                    error:&error];
    GHAssertNotNil(context1, [error localizedDescription]);
    TXLContext *context2 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"de", nil]
                                                                    error:&error];
    GHAssertNotNil(context2, [error localizedDescription]);
    TXLContext *context3 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray array]
                                                                    error:&error];
    GHAssertNotNil(context3, [error localizedDescription]);
    TXLContext *context4 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"fr", nil]
                                                                    error:&error];
    GHAssertNotNil(context4, [error localizedDescription]);
    TXLContext *context5 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"uk", nil]
                                                                    error:&error];
    GHAssertNotNil(context5, [error localizedDescription]);
    TXLContext *context6 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"po", nil]
                                                                    error:&error];
    GHAssertNotNil(context6, [error localizedDescription]);
    TXLContext *context8 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet2", nil]
                                                                    error:&error];
    GHAssertNotNil(context8, [error localizedDescription]);
    TXLContext *context9 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet2", @"de", @"a", @"b", nil]
                                                                    error:&error];
    GHAssertNotNil(context9, [error localizedDescription]);
    TXLContext *context10 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet3", nil]
                                                                     error:&error];
    GHAssertNotNil(context10, [error localizedDescription]);
    TXLContext *context11 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet3", @"de", @"a", @"b", nil]
                                                                     error:&error];
    GHAssertNotNil(context11, [error localizedDescription]);
    TXLContext *context12 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet4", nil]
                                                                     error:&error];
    GHAssertNotNil(context12, [error localizedDescription]);
    TXLContext *context13 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet4", @"de", @"a", @"b", nil]
                                                                     error:&error];
    GHAssertNotNil(context13, [error localizedDescription]);
    TXLContext *context14 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet4", @"de", @"a", @"b", @"c", nil]
                                                                     error:&error];
    GHAssertNotNil(context14, [error localizedDescription]);
    TXLContext *context15 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet5", nil]
                                                                     error:&error];
    GHAssertNotNil(context15, [error localizedDescription]);
    TXLContext *context16 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet5", @"de", @"a", @"b", @"c", nil]
                                                                     error:&error];
    GHAssertNotNil(context16, [error localizedDescription]);
    TXLContext *context17 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet6", nil]
                                                                     error:&error];
    GHAssertNotNil(context17, [error localizedDescription]);
    TXLContext *context19 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet7", nil]
                                                                     error:&error];
    GHAssertNotNil(context19, [error localizedDescription]);
    TXLContext *context22 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet8", nil]
                                                                     error:&error];
    GHAssertNotNil(context22, [error localizedDescription]);
    TXLContext *context25 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet9", nil]
                                                                     error:&error];
    GHAssertNotNil(context25, [error localizedDescription]);
    
    TXLRevision *rev = [[TXLManager sharedManager] headRevision];
    
    BOOL found = FALSE;            
    
    NSMutableArray *results = [NSMutableArray array];
    
    // ---------------------------------------------------------------------------------
    // test evaluate pattern
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has only a direct child context and no
    // deeper relationships, where (temperature, warm) is not defined in the context
    // and not defined in the direct child context
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context1]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts, 
    // where (temperature, warm) is defined in the context
    // but also sky_coverage is defined
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context2]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has several direct child contexts and several
    // deeper relationships, where (temperature, warm) is defined in the context
    // and in some direct child contexts but where rain and sky_coverage is also defined
    // in the context, in some direct child contexts and in some deeper relationships
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context3]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);           
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts, 
    // where (temperature, warm) is defined in the context
    // but also rain is defined in the context
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context4]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts,
    // where temperature is defined but not (temperature, warm)
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context5]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts,
    // where (temperature, warm) and another temperature is defined
    // in the context
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context6]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 1 results - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 1, @"1 result should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child context and several
    // deeper relationships, where (temperature, warm) is defined in the context
    // but sky_coverage is also defined in one deeper relationship
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context8]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a deeper context, which has no direct child contexts, 
    // where (temperature, warm) is not defined but sky_coverage
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context9]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child context and several
    // deeper relationships, where (temperature, warm) is defined in the context
    // but rain is also defined in one deeper relationship
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context10]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts, 
    // where (temperature, warm) is not defined but rain
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context11]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child context and several
    // deeper relationships, where (temperature, warm) is defined in the context
    // but rain and sky_coverage are also defined in seperate deeper relationships
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context12]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts, 
    // where (temperature, warm) is not defined in the context
    // but sky_coverage is defined
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context13]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts, 
    // where (temperature, warm) is not defined in the context
    // but rain is defined
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context14]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child context and several
    // deeper relationships, where rain is defined in the context and 
    // (temperature, warm) is defined in one deeper context
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context15]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a deeper context, which has no direct child contexts, 
    // where (temperature, warm) is defined
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context16]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 1 result - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 1, @"1 result should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child context and several
    // deeper relationships, where sky_coverage is defined in the context and
    // (temperature, warm) is defined in one deeper context
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context17]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has noe direct child context and several
    // deeper relationships, where rain is defined in the context, sky_coverage is
    // defined in a deeper context c1 and (temperature, warm) is defined in a deeper
    // context c2, where c2 is deeper in relation to c1
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context19]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child context and several
    // deeper relationships, where rain is defined in the context, (temperate, warm)
    // is defined in a deeper context c1 and sky_coverage is defined in a deeper
    // context c2, where c2 is deeper in relation to c1
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context22]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one child context and several
    // deeper relationships, where (temperature, warm) is defined in one
    // deeper relationship
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context25]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 1 results - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 1, @"1 result should be found - but there were (%d results) found!", [results count]);
    
}

- (void)testEvaluateQueryPattern5WithoutWindowConstraints {
    
    // without window constraints means, that any statement is specified without a window constraint
    // so any statement is valid always everywhere and we try to evaluate the query pattern 
    // over these statements without any window constraint, so we try to find matches 
    // for a query pattern at any time and at any geographical point without such restrictions
    
    NSError *error;
    
    GHAssertTrue([self buildDataSet], @"building dataset failed!");
    
    TXLInteger *queryPatternPk = [TXLInteger integerWithValue:[[self buildQueryPattern5] primaryKey]];
    
    // ---------------------------------------------------------------------------------
    // preparations for evaluating the basic graph pattern
    // ---------------------------------------------------------------------------------
    
    NSDictionary *vars = [NSDictionary dictionary];
    
    TXLGraphPattern *graphPattern = [TXLGraphPattern graphPatternWithPrimaryKey:[queryPatternPk intValue]];    
    
    TXLContext *context1 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray array]
                                                                    error:&error];
    GHAssertNotNil(context1, [error localizedDescription]);
    TXLContext *context2 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"de", nil]
                                                                    error:&error];
    GHAssertNotNil(context2, [error localizedDescription]);
    TXLContext *context3 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"fr", nil]
                                                                    error:&error];
    GHAssertNotNil(context3, [error localizedDescription]);
    TXLContext *context4 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"po", nil]
                                                                    error:&error];
    GHAssertNotNil(context4, [error localizedDescription]);
    TXLContext *context5 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet2", nil]
                                                                    error:&error];
    GHAssertNotNil(context5, [error localizedDescription]);
    TXLContext *context6 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet3", nil]
                                                                    error:&error];
    GHAssertNotNil(context6, [error localizedDescription]);
    TXLContext *context7 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet4", nil]
                                                                    error:&error];
    GHAssertNotNil(context7, [error localizedDescription]);
    TXLContext *context8 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet5", nil]
                                                                    error:&error];
    GHAssertNotNil(context8, [error localizedDescription]);
    TXLContext *context9 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet6", nil]
                                                                    error:&error];
    GHAssertNotNil(context9, [error localizedDescription]);
    TXLContext *context10 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet7", nil]
                                                                     error:&error];
    GHAssertNotNil(context10, [error localizedDescription]);
    TXLContext *context11 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet2", @"de", @"a", @"b", nil]
                                                                     error:&error];
    GHAssertNotNil(context11, [error localizedDescription]);
    TXLContext *context12 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                      host:@"weather"
                                                                      path:[NSArray arrayWithObjects:@"situmet3", @"de", @"a", @"b", nil]
                                                                     error:&error];
    GHAssertNotNil(context12, [error localizedDescription]);
    
    TXLRevision *rev = [[TXLManager sharedManager] headRevision];
    
    BOOL found = FALSE;            
    
    NSMutableArray *results = [NSMutableArray array];
    
    // ---------------------------------------------------------------------------------
    // test evaluate pattern
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has several direct child contexts and several
    // deeper relationships, where rain and sky_coverage are defined in the context and
    // in child contexts and in deeper relationships several times
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context1]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts, 
    // where sky_coverage is defined in the context but rain is not
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context2]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts, 
    // where rain is defined in the context but sky_coverage is not
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context3]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts, 
    // where rain and sky_coverage are not defined
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context4]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 2 results - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 2, @"2 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child contexts and several
    // deeper relationships, where sky_coverage is defined in a deeper context
    // but rain is not defined
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context5]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child contexts and several
    // deeper relationships, where rain is defined in a deeper context
    // but sky_coverage is not defined
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context6]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child contexts and several
    // deeper relationships, where sky_coverage and rain are defined in seperate 
    // deeper contexts
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context7]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child contexts and several
    // deeper relationships, where rain is defined in the context but sky_coverage is not
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context8]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child contexts and several
    // deeper relationships, where sky_coverage is defined in the context but
    // but rain is not
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context9]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child contexts and several
    // deeper relationships, where rain is defined in the context
    // and sky_coverage is defined in a deeper context
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context10]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts, 
    // where only sky_coverage is defined in the context
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context11]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts, 
    // where only rain is defined in the context
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context12]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);        
    
}

- (void)testEvaluateQueryPattern6WithoutWindowConstraints {
    
    // without window constraints means, that any statement is specified without a window constraint
    // so any statement is valid always everywhere and we try to evaluate the query pattern 
    // over these statements without any window constraint, so we try to find matches 
    // for a query pattern at any time and at any geographical point without such restrictions
    
    NSError *error;
    
    GHAssertTrue([self buildDataSet], @"building dataset failed!");
    
    TXLInteger *queryPatternPk = [TXLInteger integerWithValue:[[self buildQueryPattern6] primaryKey]];
    
    // ---------------------------------------------------------------------------------
    // preparations for evaluating the basic graph pattern
    // ---------------------------------------------------------------------------------
    
    NSDictionary *vars = [NSDictionary dictionary];
    
    TXLGraphPattern *graphPattern = [TXLGraphPattern graphPatternWithPrimaryKey:[queryPatternPk intValue]];    
    
    TXLContext *context1 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray array]
                                                                    error:&error];
    GHAssertNotNil(context1, [error localizedDescription]);
    TXLContext *context2 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet5", nil]
                                                                    error:&error];
    GHAssertNotNil(context2, [error localizedDescription]);
    
    TXLRevision *rev = [[TXLManager sharedManager] headRevision];
    
    BOOL found = FALSE;            
    
    NSMutableArray *results = [NSMutableArray array];
    
    // ---------------------------------------------------------------------------------
    // test evaluate pattern
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has several direct child contexts and several
    // deeper relationships, where rain 1.1, sky_coverage and frost are defined in the context and
    // in child contexts and in deeper relationships several times
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context1]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child context and several
    // deeper relationships, where rain is defined but not with value 1.1 and
    // where sky_coverage and frost are not defined
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context2]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 1 results - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 2, @"2 results should be found - but there were (%d results) found!", [results count]);
    
}

- (void)testEvaluateQueryPattern7WithoutWindowConstraints {
    
    // without window constraints means, that any statement is specified without a window constraint
    // so any statement is valid always everywhere and we try to evaluate the query pattern 
    // over these statements without any window constraint, so we try to find matches 
    // for a query pattern at any time and at any geographical point without such restrictions
    
    NSError *error;
    
    GHAssertTrue([self buildDataSet], @"building dataset failed!");
    
    TXLInteger *queryPatternPk = [TXLInteger integerWithValue:[[self buildQueryPattern7] primaryKey]];
    
    // ---------------------------------------------------------------------------------
    // preparations for evaluating the basic graph pattern
    // ---------------------------------------------------------------------------------
    
    NSDictionary *vars = [NSDictionary dictionary];
    
    TXLGraphPattern *graphPattern = [TXLGraphPattern graphPatternWithPrimaryKey:[queryPatternPk intValue]];    
    
    TXLContext *context1 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"events"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", nil]
                                                                    error:&error];
    GHAssertNotNil(context1, [error localizedDescription]);
    TXLContext *context2 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"events"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", @"vienna", nil]
                                                                    error:&error];
    GHAssertNotNil(context2, [error localizedDescription]);
    TXLContext *context3 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray array]
                                                                    error:&error];
    GHAssertNotNil(context3, [error localizedDescription]);
    
    TXLRevision *rev = [[TXLManager sharedManager] headRevision];
    
    BOOL found = FALSE;            
    
    NSMutableArray *results = [NSMutableArray array];
    
    // ---------------------------------------------------------------------------------
    // test evaluate pattern
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has one direct child context and no
    // deeper relationships, where name, category and suitable_if are defined in the context and
    // in the child context
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context1]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 20 results - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 20, @"20 results should be found - but there were (%d results) found!", [results count]);
    NSMutableArray *name = [NSMutableArray arrayWithObjects:
                            @"Impressionism",
                            @"Impressionism",
                            @"Impressionism",
                            @"Impressionism",
                            @"Impressionism",
                            @"Impressionism",
                            @"Impressionism",
                            @"Impressionism",
                            @"Impressionism",
                            @"Impressionism",
                            @"Dogs",
                            @"Dogs",
                            @"Dogs",
                            @"Dogs",
                            @"Dogs",
                            @"Dogs",
                            @"Dogs",
                            @"Dogs",
                            @"Dogs",
                            @"Dogs",
                            nil];
    NSMutableArray *category = [NSMutableArray arrayWithObjects:
                                @"art exhibition",
                                @"art exhibition",
                                @"art exhibition",
                                @"art exhibition",
                                @"art exhibition",
                                @"art exhibition",
                                @"art exhibition",
                                @"art exhibition",
                                @"art exhibition",
                                @"art exhibition",
                                @"musical",
                                @"musical",
                                @"musical",
                                @"musical",
                                @"musical",
                                @"musical",
                                @"musical",
                                @"musical",
                                @"musical",
                                @"musical",
                                nil];
    NSMutableArray *suitable_if = [NSMutableArray arrayWithObjects:
                                   @"storm",
                                   @"rain",
                                   @"rain",
                                   @"cyclone",
                                   @"flooding",
                                   @"storm",
                                   @"rain",
                                   @"rain",
                                   @"cyclone",
                                   @"flooding",
                                   @"storm",
                                   @"rain",
                                   @"rain",
                                   @"cyclone",
                                   @"flooding",
                                   @"storm",
                                   @"rain",
                                   @"rain",
                                   @"cyclone",
                                   @"flooding",
                                   nil];
    for (NSDictionary *res in results) {
        for (TXLInteger *val in [res allValues]) {
            NSString *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] literalValue];
            if (temp != nil) {
                [name removeObject:temp];
                [category removeObject:temp];
                [suitable_if removeObject:temp];
            }
        }
    }
    GHAssertTrue([name count] == 0, @"Not all matches for variable name were found - (%d) matches were not found!", [name count]);
    GHAssertTrue([category count] == 0, @"Not all matches for variable category were found - (%d) matches were not found!", [category count]);
    GHAssertTrue([suitable_if count] == 0, @"Not all matches for variable suitable_if were found - (%d) matches were not found!", [suitable_if count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a context, which has no direct child contexts, 
    // where rain, category and suitable_if are defined in the context
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context2]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 3 results - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 3, @"3 results should be found - but there were (%d results) found!", [results count]);
    name = [NSMutableArray arrayWithObjects:
            @"Dogs",
            @"Dogs",
            @"Dogs",
            nil];
    category = [NSMutableArray arrayWithObjects:
                @"musical",
                @"musical",
                @"musical",
                nil];
    suitable_if = [NSMutableArray arrayWithObjects:
                   @"rain",
                   @"cyclone",
                   @"flooding",
                   @"rain",
                   @"cyclone",
                   @"flooding",
                   @"rain",
                   @"cyclone",
                   @"flooding",
                   nil];
    for (NSDictionary *res in results) {
        for (TXLInteger *val in [res allValues]) {
            NSString *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] literalValue];
            if (temp != nil) {
                [name removeObject:temp];
                [category removeObject:temp];
                [suitable_if removeObject:temp];
            }
        }
    }
    GHAssertTrue([name count] == 0, @"Not all matches for variable name were found - (%d) matches were not found!", [name count]);
    GHAssertTrue([category count] == 0, @"Not all matches for variable category were found - (%d) matches were not found!", [category count]);
    GHAssertTrue([suitable_if count] == 0, @"Not all matches for variable suitable_if were found - (%d) matches were not found!", [suitable_if count]);
    
    // ---------------------------------------------------------------------------------
    
    // test evaluation in a complex context where rain, category and suitable_if
    // are not defined
    
    [results removeAllObjects];
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObject:context3]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertFalse(found, @"Evaluating the query pattern should conclude into 0 results - but the return value indicates that min. one result was found!");
    GHAssertTrue([results count] == 0, @"0 results should be found - but there were (%d results) found!", [results count]);
    
}

- (void)testEvaluateQueryPattern8WithoutWindowConstraints {
    
    // without window constraints means, that any statement is specified without a window constraint
    // so any statement is valid always everywhere and we try to evaluate the query pattern 
    // over these statements without any window constraint, so we try to find matches 
    // for a query pattern at any time and at any geographical point without such restrictions
    
    NSError *error;
    
    GHAssertTrue([self buildDataSet], @"building dataset failed!");
    
    TXLInteger *queryPatternPk = [TXLInteger integerWithValue:[[self buildQueryPattern8] primaryKey]];
    
    // ---------------------------------------------------------------------------------
    // preparations for evaluating the basic graph pattern
    // ---------------------------------------------------------------------------------
    
    NSDictionary *vars = [NSDictionary dictionary];
    
    TXLGraphPattern *graphPattern = [TXLGraphPattern graphPatternWithPrimaryKey:[queryPatternPk intValue]];    
    
    TXLContext *context1 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"events"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", nil]
                                                                    error:&error];
    GHAssertNotNil(context1, [error localizedDescription]);
    TXLContext *context2 = [[TXLManager sharedManager] contextForProtocol:@"txl"
                                                                     host:@"weather"
                                                                     path:[NSArray arrayWithObjects:@"situmet", @"at", nil]
                                                                    error:&error];
    GHAssertNotNil(context2, [error localizedDescription]);
    
    TXLRevision *rev = [[TXLManager sharedManager] headRevision];
    
    BOOL found = FALSE;            
    
    NSMutableArray *results = [NSMutableArray array];
    
    // ---------------------------------------------------------------------------------
    // test evaluate pattern
    // ---------------------------------------------------------------------------------
    
    // test evaluation in two different contexts, each having one direct child context and no
    // deeper relationships, where suitable_if and category are defined several times
    
    found = [graphPattern evaluatePatternWithVariables:vars
                                            inContexts:[NSArray arrayWithObjects:
                                                        context1,
                                                        context2,
                                                        nil]
                                                window:nil
                                           forRevision:rev
                                         resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                             [results addObject:vars];
                                         }];
    
    GHAssertTrue(found, @"Evaluating the query pattern should conclude into 3 results - but the return value indicates that no result was found!");
    GHAssertTrue([results count] == 3, @"3 results should be found - but there were (%d results) found!", [results count]);
    NSMutableArray *event = [NSMutableArray arrayWithObjects:
                             @"x",
                             @"x",
                             @"y",
                             nil];
    NSMutableArray *s = [NSMutableArray arrayWithObjects:
                         @"rain",
                         @"rain",
                         @"rain",
                         nil];
    for (NSDictionary *res in results) {
        for (TXLInteger *val in [res allValues]) {
            NSString *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] literalValue];
            if (temp != nil) {
                [s removeObject:temp];
            } else {
                NSString *temp = [[TXLTerm termWithPrimaryKey:[val integerValue]] blankNodeValue];
                [event removeObject:temp];
            }
        }
    }
    GHAssertTrue([event count] == 0, @"Not all matches for variable event were found - (%d) matches were not found!", [event count]);
    GHAssertTrue([s count] == 0, @"Not all matches for variable s were found - (%d) matches were not found!", [s count]);
    
}

@end

//
//  TXLSPARQLCompilerTest.m
//  OpenTXL
//
//  Created by Eleni Tsigka on 29.11.10.
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
#import "TXLSPARQLCompiler.h"
#import "TXLQuery.h"
#import "TXLContext.h"
#import "TXLDatabase.h"
#import "TXLManager.h"
#import "TXLTerm.h"

#define SQL(x) {TXLDatabase *database = [[TXLManager sharedManager] database]; NSError *error; NSArray *result = [database executeSQL:x error:&error]; GHAssertNotNil(result, [error localizedDescription]);}

@interface TXLSPARQLCompilerTest : GHTestCase {
	
}
@end


@implementation TXLSPARQLCompilerTest

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
#pragma mark Tests for OpenTXL example SELECT queries. 


- (void)testCompilerForSelectQueryWithBlankNode {
	
	/*
	PREFIX m: <http://schema.situmet.at/meteorology#>
	
	SELECT ?temp
	FROM <txl://weather.situmet.at>
	WHERE {
		[m:temperature ?temp].
	}
	*/
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> SELECT ?temp FROM <txl://weather.situmet.at> WHERE { [m:temperature ?temp]. }" 
														 parameters:nil 
															options:nil 
															  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check query's sparql text.
	result = [database executeSQLWithParameters:@"SELECT sparql, pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId],
			  nil]; 
	
	NSString *sparqlText = nil;
	NSUInteger queryPatternId = 0;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		sparqlText = [[result objectAtIndex:0] objectForKey:@"sparql"]; 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] intValue]; 
	} 
	
	GHAssertEqualStrings(sparqlText, @"PREFIX m: <http://schema.situmet.at/meteorology#> SELECT ?temp FROM <txl://weather.situmet.at> WHERE { [m:temperature ?temp]. }", 
						 @"The sparql query text is not correct.");
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");	
	
	// Check query's context.
	result = [database executeSQLWithParameters:@"SELECT context_id FROM txl_query_context WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	TXLContext *context = nil;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		context = [TXLContext contextWithPrimaryKey:[[[result objectAtIndex:0] objectForKey:@"context_id"] intValue]]; 
	}
	
	GHAssertNotEquals([context primaryKey], (NSUInteger)0, @"Context id should not be 0.");
	GHAssertEqualObjects([context description], @"txl://weather.situmet.at", @"Absolute path missmatch.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		NSString *name = [[result objectAtIndex:0] objectForKey:@"name"];
		GHAssertEqualStrings(name, @"temp", [NSString stringWithFormat:@"Variable %@ should have name 'temp'.", name]);
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], [NSString stringWithFormat:@"Variable %@ should be in the result set.", name]);
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], [NSString stringWithFormat:@"Variable %@ should not be a blank node.", name]);
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's pattern.
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	NSUInteger subjectVarId = 0;
	NSUInteger predicateId = 0;
	NSUInteger objectVarId = 0;
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		subjectVarId = [[[result objectAtIndex:0] objectForKey:@"subject_var_id"] intValue];
		GHAssertNotEquals(subjectVarId, (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		predicateId = [[[result objectAtIndex:0] objectForKey:@"predicate_id"] intValue];
		GHAssertNotEquals(predicateId, (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		objectVarId = [[[result objectAtIndex:0] objectForKey:@"object_var_id"] intValue];
		GHAssertNotEquals(objectVarId, (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// Check subject of the triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:subjectVarId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:predicateId];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#temperature", @"Predicate should be 'http://schema.situmet.at/meteorology#temperature'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:objectVarId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"temp", @"Object should have the name 'temp'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should not be a blank node.");
	}
}


- (void)testCompilerForAnotherSelectQueryWithBlankNode {
	
	/*
	PREFIX m: <http://schema.situmet.at/meteorology#>
	
	SELECT ?rain
	FROM <txl://weather.situmet.at>
	WHERE {
		[m:rain ?rain].
	}
	
	// Similarly for
	PREFIX m: <http://schema.situmet.at/meteorology#>
	
	SELECT ?sky_coverage
	FROM <txl://weather.situmet.at>
	WHERE {
		[m:sky_coverage ?sky_coverage].
	} 
	*/
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> SELECT ?rain FROM <txl://weather.situmet.at> WHERE {  [m:rain ?rain]. }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check query's sparql text.
	result = [database executeSQLWithParameters:@"SELECT sparql, pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	NSString *sparqlText = nil;
	NSUInteger queryPatternId = 0;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		sparqlText = [[result objectAtIndex:0] objectForKey:@"sparql"]; 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] intValue]; 
	} 
	
	GHAssertEqualStrings(sparqlText, @"PREFIX m: <http://schema.situmet.at/meteorology#> SELECT ?rain FROM <txl://weather.situmet.at> WHERE {  [m:rain ?rain]. }", 
						 @"The sparql query text is not correct.");
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's context.
	result = [database executeSQLWithParameters:@"SELECT context_id FROM txl_query_context WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	TXLContext *context = nil;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		context = [TXLContext contextWithPrimaryKey:[[[result objectAtIndex:0] objectForKey:@"context_id"] intValue]]; 
	}
	
	GHAssertNotEquals([context primaryKey], (NSUInteger)0, @"Context id should not be 0.");
	GHAssertEqualStrings([context description], @"txl://weather.situmet.at", @"Absolute path missmatch.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		NSString *name = [[result objectAtIndex:0] objectForKey:@"name"];
		GHAssertEqualStrings(name, @"rain", [NSString stringWithFormat:@"Variable %@ should have name 'rain'.", name]);
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], [NSString stringWithFormat:@"Variable %@ should be in the result set.", name]);
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], [NSString stringWithFormat:@"Variable %@ should not be a blank node.", name]);
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's pattern.
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	NSUInteger subjectVarId = 0;
	NSUInteger predicateId = 0;
	NSUInteger objectVarId = 0;
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		subjectVarId = [[[result objectAtIndex:0] objectForKey:@"subject_var_id"] intValue];
		GHAssertNotEquals(subjectVarId, (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		predicateId = [[[result objectAtIndex:0] objectForKey:@"predicate_id"] intValue];
		GHAssertNotEquals(predicateId, (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		objectVarId = [[[result objectAtIndex:0] objectForKey:@"object_var_id"] intValue];
		GHAssertNotEquals(objectVarId, (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// Check subject of the triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:subjectVarId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:predicateId];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#rain", @"Predicate should be 'http://schema.situmet.at/meteorology#rain'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:objectVarId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"rain", @"Object should have the name 'rain'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should not be a blank node.");
	}
}


- (void)testCompilerForSelectQueryTriplePatternsSameSubjectWithBlankNode {
	
	/*
	PREFIX e: <http://schema.situmet.at/events#>
	
	SELECT ?name ?category ?suitable_if
	FROM <txl://events.situmet.at>
	WHERE {
		[e:name ?name;
		 e:category ?category;
		 e:suitable_if ?suitable_if].
	}
	*/
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX e: <http://schema.situmet.at/events#> SELECT ?name ?category ?suitable_if FROM <txl://events.situmet.at> WHERE { [e:name ?name; e:category ?category; e:suitable_if ?suitable_if]. }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result  = nil;
	
	// Check query's sparql text.
	result = [database executeSQLWithParameters:@"SELECT sparql, pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	NSString *sparqlText  = nil;
	NSUInteger queryPatternId = 0;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		sparqlText = [[result objectAtIndex:0] objectForKey:@"sparql"]; 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] intValue]; 
	} 
	
	GHAssertEqualStrings(sparqlText, @"PREFIX e: <http://schema.situmet.at/events#> SELECT ?name ?category ?suitable_if FROM <txl://events.situmet.at> WHERE { [e:name ?name; e:category ?category; e:suitable_if ?suitable_if]. }", 
						 @"The sparql query text is not correct.");
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's context.
	result = [database executeSQLWithParameters:@"SELECT context_id FROM txl_query_context WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	TXLContext *context = nil;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		context = [TXLContext contextWithPrimaryKey:[[[result objectAtIndex:0] objectForKey:@"context_id"] intValue]]; 
	}
	
	GHAssertNotEquals([context primaryKey], (NSUInteger)0, @"Context id should not be 0.");
	GHAssertEqualObjects([context description], @"txl://events.situmet.at", @"Absolute path missmatch.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)4, @"There should be 4 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 4) { 
		
		NSString *name = [[result objectAtIndex:0] objectForKey:@"name"];
		GHAssertEqualStrings(name, @"name", [NSString stringWithFormat:@"Variable %@ should have name 'name'.", name]);
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], [NSString stringWithFormat:@"Variable %@ should be in the result set.", name]);
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], [NSString stringWithFormat:@"Variable %@ should not be a blank node.", name]);
		
		name = [[result objectAtIndex:1] objectForKey:@"name"];
		GHAssertEqualStrings(name, @"category", [NSString stringWithFormat:@"Variable %@ should have name 'category'.", name]);
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], [NSString stringWithFormat:@"Variable %@ should be in the result set.", name]);
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], [NSString stringWithFormat:@"Variable %@ should not be a blank node.", name]);
		
		name = [[result objectAtIndex:2] objectForKey:@"name"];
		GHAssertEqualStrings(name, @"suitable_if", [NSString stringWithFormat:@"Variable %@ should have name 'suitable_if'.", name]);
		GHAssertTrue([[[result objectAtIndex:2] objectForKey:@"in_resultset"] boolValue], [NSString stringWithFormat:@"Variable %@ should be in the result set.", name]);
		GHAssertFalse([[[result objectAtIndex:2] objectForKey:@"is_blanknode"] boolValue], [NSString stringWithFormat:@"Variable %@ should not be a blank node.", name]);
		
		GHAssertNotNil([[result objectAtIndex:3] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:3] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:3] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's pattern.
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];
	NSMutableArray *thirdTriple = [NSMutableArray array];
	
	GHAssertEquals([result count], (NSUInteger)3, @"There should be 3 triple patterns saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 3) { 
		
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
		
		// Second triple		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
		
		// Third triple		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:2] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:2] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:2] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:2] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[thirdTriple addObject:[[result objectAtIndex:2] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:2] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:2] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// Check subjects of the triple patterns.
	GHAssertEquals([[firstTriple objectAtIndex:0] intValue] , [[secondTriple objectAtIndex:0] intValue], @"The subjects of the first and second triples should have the same id.");
	GHAssertEquals([[secondTriple objectAtIndex:0] intValue] , [[thirdTriple objectAtIndex:0] intValue], @"The subjects of the first and second triples should have the same id.");
	
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the first triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/events#name", @"Predicate should be 'http://schema.situmet.at/events#name'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:2], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"name", @"Object should have the name 'name'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should not be a blank node.");
	}
}


- (void)testResultSetTablesCreatedForSelectQuery {
	
	/*
	PREFIX e: <http://schema.situmet.at/events#>
	
	SELECT ?name ?category ?suitable_if
	FROM <txl://events.situmet.at>
	WHERE {
		_:x e:name ?name;
		e:category ?category;
		e:suitable_if ?suitable_if.
	}
	*/
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX e: <http://schema.situmet.at/events#> SELECT ?name ?category ?suitable_if FROM <txl://events.situmet.at> WHERE { _:x e:name ?name; e:category ?category; e:suitable_if ?suitable_if. }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Construct the expected names of the variables columns in the result set table.
	NSMutableArray *varColNames = [NSMutableArray array];
	
	result = [database executeSQLWithParameters:@"SELECT id FROM txl_query_variable WHERE query_id = ? and in_resultset = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId],
			  [NSNumber numberWithBool:YES], 
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)3, @"There should be 3 variables in the resultset for this query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 3) { 
		
		[varColNames addObject:[NSString stringWithFormat:@"var_%d", [[[result objectAtIndex:0] objectForKey:@"id"] intValue]]];
		[varColNames addObject:[NSString stringWithFormat:@"var_%d", [[[result objectAtIndex:1] objectForKey:@"id"] intValue]]];
		[varColNames addObject:[NSString stringWithFormat:@"var_%d", [[[result objectAtIndex:2] objectForKey:@"id"] intValue]]];
	}
	
	// Check if the result set table was created.
	BOOL resultsetTable = [database.tableNames containsObject:[NSString stringWithFormat:@"txl_resultset_%d", queryId]];
	
	GHAssertTrue(resultsetTable, [NSString stringWithFormat:@"Result set table for query with id %d was not created.", queryId]);
	
	// Check if the columns of the resultset table are correct.	
	result = [database executeSQL:[NSString stringWithFormat:@"PRAGMA table_info(txl_resultset_%d)", queryId]
							error:&error]; 
	
	GHAssertEquals([result count], (NSUInteger)5, @"The table 'txl_resultset_%d' should have 5 columns.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 5) { 
		
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"id", @"The first column of the resultset table should have the name 'id'.");
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"type"], @"integer", @"The id column of the resultset table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"name"], @"mos_id", @"The second column of the resultset table should have the name 'mos_id'.");
		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"type"], @"integer", @"The mos_id column of the resultset table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:2] objectForKey:@"name"], [varColNames objectAtIndex:0], [NSString stringWithFormat:@"The third column of the resultset table should have the name '%@'.", [varColNames objectAtIndex:0]]);
		GHAssertEqualStrings([[result objectAtIndex:2] objectForKey:@"type"], @"integer", @"The first variable column of the resultset table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:3] objectForKey:@"name"], [varColNames objectAtIndex:1], [NSString stringWithFormat:@"The forth column of the resultset table should have the name '%@'.", [varColNames objectAtIndex:1]]);
		GHAssertEqualStrings([[result objectAtIndex:3] objectForKey:@"type"], @"integer", @"The second variable column of the resultset table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:4] objectForKey:@"name"], [varColNames objectAtIndex:2], [NSString stringWithFormat:@"The fifth column of the resultset table should have the name '%@'.", [varColNames objectAtIndex:2]]);
		GHAssertEqualStrings([[result objectAtIndex:4] objectForKey:@"type"], @"integer", @"The third variable column of the resultset table should be of type integer.");
	} 
	
	// Check if the resultset_created table was created.
	BOOL resultsetCreatedTable = [database.tableNames containsObject:[NSString stringWithFormat:@"txl_resultset_%d_created", queryId]];
	
	GHAssertTrue(resultsetCreatedTable, [NSString stringWithFormat:@"Resultset_created table for query with id %d was not created.", queryId]);
	
	// Check if the columns of the resultset_created table are correct.	
	result = [database executeSQL:[NSString stringWithFormat:@"PRAGMA table_info(txl_resultset_%d_created)", queryId]
							error:&error]; 
	
	GHAssertEquals([result count], (NSUInteger)3, @"The table 'txl_resultset_%d_created' should have 3 columns.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 3) { 
		
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"id", @"The first column of the resultset_created table should have the name 'id'.");
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"type"], @"integer", @"The id column of the resultset_created table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"name"], @"resultset_id", @"The second column of the resultset_created table should have the name 'resultset_id'.");
		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"type"], @"integer", @"The resultset_id column of the resultset_created table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:2] objectForKey:@"name"], @"revision_id", @"The third column of the resultset_created table should have the name 'revision_id'.");
		GHAssertEqualStrings([[result objectAtIndex:2] objectForKey:@"type"], @"integer", @"The revision_id column of the resultset_created table should be of type integer.");
	}
	
	// Check if the resultset_removed table was created.
	BOOL resultsetRemovedTable = [database.tableNames containsObject:[NSString stringWithFormat:@"txl_resultset_%d_removed", queryId]];
	
	GHAssertTrue(resultsetRemovedTable, [NSString stringWithFormat:@"Resultset_removed table for query with id %d was not created.", queryId]);
	
	// Check if the columns of the resultset_removed table are correct.	
	result = [database executeSQL:[NSString stringWithFormat:@"PRAGMA table_info(txl_resultset_%d_removed)", queryId]
							error:&error]; 
	
	GHAssertEquals([result count], (NSUInteger)3, @"The table 'txl_resultset_%d_removed' should have 3 columns.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 3) { 
		
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"id", @"The first column of the resultset_removed table should have the name 'id'.");
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"type"], @"integer", @"The id column of the resultset_removed table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"name"], @"resultset_id", @"The second column of the resultset_removed table should have the name 'resultset_id'.");
		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"type"], @"integer", @"The resultset_id column of the resultset_removed table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:2] objectForKey:@"name"], @"revision_id", @"The third column of the resultset_removed table should have the name 'revision_id'.");
		GHAssertEqualStrings([[result objectAtIndex:2] objectForKey:@"type"], @"integer", @"The revision_id column of the resultset_removed table should be of type integer.");
	}
}


#pragma mark -
#pragma mark Tests for OpenTXL example ASK queries. 

- (void)testCompilerForAskQueryWithNotExistsAndBlankNodes {
	
	/*
	PREFIX m: <http://schema.situmet.at/meteorology#>
	
	ASK
	FROM <txl://weather.situmet.at>
	WHERE {
		[m:temperature "warm"].
		NOT EXISTS { 
			[m:rain []].
		}
		NOT EXISTS {
			[m:sky_coverage []].
		}
	}
	*/
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> ASK FROM <txl://weather.situmet.at> WHERE { [m:temperature \"warm\"]. NOT EXISTS { [m:rain []]. } NOT EXISTS { [m:sky_coverage []]. } }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result  = nil;
	NSUInteger queryPatternId = 0;
	
	result = [database executeSQLWithParameters:@"SELECT pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] intValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)5, @"There should be 5 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 5) { 
		
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:2] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:2] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:2] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:3] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:3] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:3] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:4] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:4] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:4] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's patterns (not exists).
	NSMutableArray *patterns = [NSMutableArray array];
	
	result = [database executeSQLWithParameters:@"SELECT id, pattern_id FROM txl_query_pattern_not_exists WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 NOT EXISTS saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		// First NOT EXISTS pattern
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The txl_query_pattern_not_exists id should not be 0.");
		[patterns addObject:[[result objectAtIndex:0] objectForKey:@"pattern_id"]];
		GHAssertNotEquals((NSUInteger)[[patterns objectAtIndex:0] intValue], (NSUInteger)0, @"The pattern_id should not be 0.");
		
		// Second NOT EXISTS pattern
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] intValue], (NSUInteger)0, @"The txl_query_pattern_not_exists id should not be 0.");
		[patterns addObject:[[result objectAtIndex:1] objectForKey:@"pattern_id"]];
		GHAssertNotEquals((NSUInteger)[[patterns objectAtIndex:1] intValue], (NSUInteger)0, @"The pattern_id should not be 0.");
	}
	
	// Check query's triples.
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];
	NSMutableArray *thirdTriple = [NSMutableArray array];
	
	// For the outer pattern (in the WHERE clause)
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			   [NSNumber numberWithInt:queryPatternId],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the outer pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_var_id"] intValue], (NSUInteger)0, @"The object should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object term id should not be 0.");
	}
	
	// For the first NOT EXISTS pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [patterns objectAtIndex:0],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the first NOT EXISTS pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		// Second triple		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// For the second NOT EXISTS pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [patterns objectAtIndex:1],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the second NOT EXISTS pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		// Third triple		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// Check subject of the second triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [secondTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the second triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[secondTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#rain", @"Predicate should be 'http://schema.situmet.at/meteorology#rain'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the second triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [secondTriple objectAtIndex:2], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Object should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should be a blank node.");
	}
	
	// Check subject of the third triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [thirdTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the third triple pattern.
	predicate = [TXLTerm termWithPrimaryKey:[[thirdTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#sky_coverage", @"Predicate should be 'http://schema.situmet.at/meteorology#sky_coverage'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the third triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [thirdTriple objectAtIndex:2], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Object should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should be a blank node.");
	}
}

- (void)testCompilerForAnotherAskQueryWithNotExistsAndBlankNode {
	
	/*
	PREFIX m: <http://schema.situmet.at/meteorology#>
	
	ASK
	FROM <txl://weather.situmet.at>
	WHERE {
		NOT EXISTS {
			[m:temperature \"kalt\"].
		}
		NOT EXISTS { 
			[m:rain []].
		}
		NOT EXISTS {
			[m:sky_coverage []].
		}
	}
	*/
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> ASK FROM <txl://weather.situmet.at> WHERE { NOT EXISTS { [m:temperature \"kalt\"]. } NOT EXISTS { [m:rain []]. } NOT EXISTS { [m:sky_coverage []]. } }" 
											 parameters:nil 
												options:nil 
												  error:&error];
    
    GHAssertNotNil(query, [error localizedDescription]);
    
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result  = nil;
	NSUInteger queryPatternId = 0;
	
	result = [database executeSQLWithParameters:@"SELECT pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] intValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)5, @"There should be 5 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 5) { 
		
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:2] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:2] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:2] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:3] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:3] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:3] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:4] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:4] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:4] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's patterns (not exists).
	NSMutableArray *patterns = [NSMutableArray array];
	
	result = [database executeSQLWithParameters:@"SELECT id, pattern_id FROM txl_query_pattern_not_exists WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)3, @"There should be 3 NOT EXISTS patterns saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 3) { 
		
		// First NOT EXISTS pattern
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The txl_query_pattern_not_exists id should not be 0.");
		[patterns addObject:[[result objectAtIndex:0] objectForKey:@"pattern_id"]];
		GHAssertNotEquals((NSUInteger)[[patterns objectAtIndex:0] intValue], (NSUInteger)0, @"The pattern_id should not be 0.");
		
		// Second NOT EXISTS pattern
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] intValue], (NSUInteger)0, @"The txl_query_pattern_not_exists id should not be 0.");
		[patterns addObject:[[result objectAtIndex:1] objectForKey:@"pattern_id"]];
		GHAssertNotEquals((NSUInteger)[[patterns objectAtIndex:1] intValue], (NSUInteger)0, @"The pattern_id should not be 0.");
		
		// Third NOT EXISTS pattern
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:2] objectForKey:@"id"] intValue], (NSUInteger)0, @"The txl_query_pattern_not_exists id should not be 0.");
		[patterns addObject:[[result objectAtIndex:2] objectForKey:@"pattern_id"]];
		GHAssertNotEquals((NSUInteger)[[patterns objectAtIndex:2] intValue], (NSUInteger)0, @"The pattern_id should not be 0.");
	}
	
	// Check query's triples.
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];
	NSMutableArray *thirdTriple = [NSMutableArray array];
	
	// For the first NOT EXISTS pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [patterns objectAtIndex:0],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the first NOT EXISTS pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_var_id"] intValue], (NSUInteger)0, @"The object should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object term id should not be 0.");
	}
	
	// For the second NOT EXISTS pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [patterns objectAtIndex:1],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the second NOT EXISTS pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		// Second triple		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// For the third NOT EXISTS pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [patterns objectAtIndex:2],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the third NOT EXISTS pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		// Third triple		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// Check subject of the first triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the first triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#temperature", @"Predicate should be 'http://schema.situmet.at/meteorology#temperature'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first triple pattern.
	TXLTerm *object = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:2] unsignedIntegerValue]];

	GHAssertEqualStrings([object literalValue], @"kalt", @"Object should have the name 'kalt'.");
	GHAssertEquals([object type], kTXLTermTypePlainLiteral, @"Object term should be of type kTXLTermTypePlainLiteral.");
	
	// Check subject of the second triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [secondTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the second triple pattern.
	predicate = [TXLTerm termWithPrimaryKey:[[secondTriple objectAtIndex:1] unsignedIntegerValue]];
	
	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#rain", @"Predicate should be 'http://schema.situmet.at/meteorology#rain'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the second triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [secondTriple objectAtIndex:2], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Object should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should be a blank node.");
	}
}


- (void)testResultSetTablesCreatedForAskQuery {
	
	/*
	PREFIX e: <http://schema.situmet.at/events#>
	
	ASK 
	FROM <txl://events.situmet.at>
	WHERE {
		_:x e:name ?name;
		e:category ?category;
		e:suitable_if ?suitable_if.
	}
	*/
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX e: <http://schema.situmet.at/events#> ASK FROM <txl://events.situmet.at> WHERE { _:x e:name ?name; e:category ?category; e:suitable_if ?suitable_if. }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check if the result set table was created.
	BOOL resultsetTable = [database.tableNames containsObject:[NSString stringWithFormat:@"txl_resultset_%d", queryId]];
	
	GHAssertTrue(resultsetTable, [NSString stringWithFormat:@"Result set table for query with id %d was not created.", queryId]);
	
	// Check if the columns of the resultset table are correct.	
	result = [database executeSQL:[NSString stringWithFormat:@"PRAGMA table_info(txl_resultset_%d)", queryId]
							error:&error]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"The table 'txl_resultset_%d' should have 2 columns.", queryId);
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"id", @"The first column of the resultset table should have the name 'id'.");
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"type"], @"integer", @"The id column of the resultset table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"name"], @"mos_id", @"The second column of the resultset table should have the name 'mos_id'.");
		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"type"], @"integer", @"The mos_id column of the resultset table should be of type integer.");
	} 
	
	// Check if the resultset_created table was created.
	BOOL resultsetCreatedTable = [database.tableNames containsObject:[NSString stringWithFormat:@"txl_resultset_%d_created", queryId]];
	
	GHAssertTrue(resultsetCreatedTable, [NSString stringWithFormat:@"Resultset_created table for query with id %d was not created.", queryId]);
	
	// Check if the columns of the resultset_created table are correct.	
	result = [database executeSQL:[NSString stringWithFormat:@"PRAGMA table_info(txl_resultset_%d_created)", queryId]
							error:&error]; 
	
	GHAssertEquals([result count], (NSUInteger)3, @"The table 'txl_resultset_%d_created' should have 3 columns.", queryId);
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 3) { 
		
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"id", @"The first column of the resultset_created table should have the name 'id'.");
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"type"], @"integer", @"The id column of the resultset_created table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"name"], @"resultset_id", @"The second column of the resultset_created table should have the name 'resultset_id'.");
		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"type"], @"integer", @"The resultset_id column of the resultset_created table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:2] objectForKey:@"name"], @"revision_id", @"The third column of the resultset_created table should have the name 'revision_id'.");
		GHAssertEqualStrings([[result objectAtIndex:2] objectForKey:@"type"], @"integer", @"The revision_id column of the resultset_created table should be of type integer.");
	}
	
	// Check if the resultset_removed table was created.
	BOOL resultsetRemovedTable = [database.tableNames containsObject:[NSString stringWithFormat:@"txl_resultset_%d_removed", queryId]];
	
	GHAssertTrue(resultsetRemovedTable, [NSString stringWithFormat:@"Resultset_removed table for query with id %d was not created.", queryId]);
	
	// Check if the columns of the resultset_removed table are correct.	
	result = [database executeSQL:[NSString stringWithFormat:@"PRAGMA table_info(txl_resultset_%d_removed)", queryId]
							error:&error]; 
	
	GHAssertEquals([result count], (NSUInteger)3, @"The table 'txl_resultset_%d_removed' should have 3 columns.", queryId);
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 3) { 
		
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"id", @"The first column of the resultset_removed table should have the name 'id'.");
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"type"], @"integer", @"The id column of the resultset_removed table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"name"], @"resultset_id", @"The second column of the resultset_removed table should have the name 'resultset_id'.");
		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"type"], @"integer", @"The resultset_id column of the resultset_removed table should be of type integer.");
		
		GHAssertEqualStrings([[result objectAtIndex:2] objectForKey:@"name"], @"revision_id", @"The third column of the resultset_removed table should have the name 'revision_id'.");
		GHAssertEqualStrings([[result objectAtIndex:2] objectForKey:@"type"], @"integer", @"The revision_id column of the resultset_removed table should be of type integer.");
	}
}


#pragma mark -
#pragma mark Tests for OpenTXL example CONSTRUCT queries. 


- (void)testCompilerForConstructQuery {
	
	/*
	 PREFIX e: <http://schema.situmet.at/events#>
	 PREFIX m: <http://schema.situmet.at/meteorology#>
	 
	 CONSTRUCT {
	 	?event e:suitable true.
	 }
	 FROM <txl://events.situmet.at>
	 FROM <txl://weather.situmet.at>
	 WHERE {
	 	?event e:suitable_if ?s.
	 	[m:category ?s].
	 }
	 */
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX e: <http://schema.situmet.at/events#> PREFIX m: <http://schema.situmet.at/meteorology#> CONSTRUCT { ?event e:suitable true. } FROM <txl://events.situmet.at> FROM <txl://weather.situmet.at> WHERE { ?event e:suitable_if ?s. [m:category ?s]. }" 
														 parameters:nil 
															options:nil 
															  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result  = nil;
	NSUInteger queryPatternId = 0;
	NSUInteger constructQueryPatternId = 0;
	
	result = [database executeSQLWithParameters:@"SELECT pattern_id, construct_template_pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] intValue]; 
		constructQueryPatternId = [[[result objectAtIndex:0] objectForKey:@"construct_template_pattern_id"] intValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	GHAssertNotEquals(constructQueryPatternId, (NSUInteger)0, @"Construct pattern id should not be 0.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)3, @"There should be 3 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 3) { 
		
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"event", @"Variable should have name 'event'.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], @"This variable should be in the result set.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"This variable should not be a blank node.");

		GHAssertEqualStrings([[result objectAtIndex:1] objectForKey:@"name"], @"s", @"Variable should have name 's'.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should not be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:2] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:2] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:2] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's triples.
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];
	NSMutableArray *thirdTriple = [NSMutableArray array];
	
	// For the Construct pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:constructQueryPatternId],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the CONSTRUCT pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_var_id"] intValue], (NSUInteger)0, @"The object should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object term id should not be 0.");
	}
	
	// For the WHERE patterns
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 triple pattern saved in the WHERE pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		// Second triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
		
		// Third triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:1] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[thirdTriple addObject:[[result objectAtIndex:1] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:1] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");		
	}
	
	// Check subject of the first triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode, in_resultset FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"event", @"Subject should have the name 'event'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should not be a blank node.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], @"Subject should be in the result set.");
	}
	
	// Check predicate of the first triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:1] unsignedIntegerValue]];
	
	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/events#suitable", @"Predicate should be 'http://schema.situmet.at/events#suitable'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first triple pattern.
	TXLTerm *object = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:2] unsignedIntegerValue]];

	GHAssertTrue(object.booleanValue, @"Object should have value 'true'.");
	GHAssertEquals([object type], kTXLTermTypeBooleanLiteral, @"Object term should be of type kTXLTermTypeBooleanLiteral.");
	
	// Check subject of the second triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode, in_resultset FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [secondTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"event", @"Subject should have the name 'event'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should not be a blank node.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], @"Subject should be in the result set.");
	}
	
	// Check predicate of the second pattern.
	predicate = [TXLTerm termWithPrimaryKey:[[secondTriple objectAtIndex:1] unsignedIntegerValue]];
	
	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/events#suitable_if", @"Predicate should be 'http://schema.situmet.at/events#suitable_if'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first second pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode, in_resultset FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [secondTriple objectAtIndex:2], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"s", @"Subject should have the name 's'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should not be a blank node.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], @"Subject should not be in the result set.");
	}
}


- (void)testCompilerForConstructQueryWithBlankNode {
	
	/*
	PREFIX m: <http://schema.situmet.at/meteorology#>
	
	CONSTRUCT {
		[m:category "Schoenwetter"].
	}
	FROM <txl://weather.situmet.at>
	WHERE {
		[m:temperature "warm"].
	}
	*/

	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> CONSTRUCT { [m:category \"Schoenwetter\"]. } FROM <txl://weather.situmet.at> WHERE { [m:temperature \"warm\"]. }" 
														 parameters:nil 
															options:nil 
															  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result  = nil;
	NSUInteger queryPatternId = 0;
	NSUInteger constructQueryPatternId = 0;
	
	result = [database executeSQLWithParameters:@"SELECT pattern_id, construct_template_pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] intValue]; 
		constructQueryPatternId = [[[result objectAtIndex:0] objectForKey:@"construct_template_pattern_id"] intValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	GHAssertNotEquals(constructQueryPatternId, (NSUInteger)0, @"Construct pattern id should not be 0.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's triples.
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];

	// For the Construct pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:constructQueryPatternId],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the CONSTRUCT pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_var_id"] intValue], (NSUInteger)0, @"The object should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object term id should not be 0.");
	}
	
	// For the WHERE pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the WHERE pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		// Second triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_var_id"] intValue], (NSUInteger)0, @"The object should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object term id should not be 0.");
	}
	
	// Check subject of the first triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode, in_resultset FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], @"Subject should not be in the result set.");
	}
	
	// Check predicate of the first triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:1] unsignedIntegerValue]];
						  
	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#category", @"Predicate should be 'http://schema.situmet.at/meteorology#category'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first triple pattern.
	TXLTerm *object = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:2] unsignedIntegerValue]];

	GHAssertEqualStrings([object literalValue], @"Schoenwetter", @"Object should have value 'Schoenwetter'.");
	GHAssertEquals([object type], kTXLTermTypePlainLiteral, @"Object term should be of type kTXLTermTypePlainLiteral.");
}


#pragma mark -
#pragma mark Tests for ASK / SELECT queries with OPTIONAL feature. 


- (void)testCompilerForAskQueryWithOptional {
	
	/*
	PREFIX m: <http://schema.situmet.at/meteorology#>
	
	ASK
	FROM <txl://weather.situmet.at>
	WHERE {
		[m:temperature "warm"].
		OPTIONAL { 
			[m:rain []].
		}
		OPTIONAL { 
			[m:sky_coverage []].
	 	}
	}
	*/
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> ASK FROM <txl://weather.situmet.at> WHERE { [m:temperature \"warm\"]. OPTIONAL { [m:rain []]. } OPTIONAL { [m:sky_coverage []]. } }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result  = nil;
	NSUInteger queryPatternId = 0;
	
	result = [database executeSQLWithParameters:@"SELECT pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] intValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)5, @"There should be 5 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 5) { 
		
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:2] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:2] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:2] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:3] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:3] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:3] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:4] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:4] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:4] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's patterns (OPTIONAL).
	NSMutableArray *patterns = [NSMutableArray array];
	
	result = [database executeSQLWithParameters:@"SELECT id, pattern_id FROM txl_query_pattern_optional WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 OPTIONAL patterns saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		// First group pattern
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The txl_query_pattern_optional id should not be 0.");
		[patterns addObject:[[result objectAtIndex:0] objectForKey:@"pattern_id"]];
		GHAssertNotEquals((NSUInteger)[[patterns objectAtIndex:0] intValue], (NSUInteger)0, @"The pattern_id should not be 0.");
		
		// Second group pattern
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] intValue], (NSUInteger)0, @"The txl_query_pattern_optional id should not be 0.");
		[patterns addObject:[[result objectAtIndex:1] objectForKey:@"pattern_id"]];
		GHAssertNotEquals((NSUInteger)[[patterns objectAtIndex:1] intValue], (NSUInteger)0, @"The pattern_id should not be 0.");
	}
	
	// Check query's triples.
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];
	NSMutableArray *thirdTriple = [NSMutableArray array];
	
	// For the outer pattern (in the WHERE clause)
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the outer pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_var_id"] intValue], (NSUInteger)0, @"The object should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object term id should not be 0.");
	}
		
	// For the first OPTIONAL pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [patterns objectAtIndex:0],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the first OPTIONAL pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		// Second triple		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// For the second OPTIONAL pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [patterns objectAtIndex:1],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the second OPTIONAL pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		// Third triple		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
	}	
	// Check subject of the first triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the first triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:1] unsignedIntegerValue]];
	
	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#temperature", @"Predicate should be 'http://schema.situmet.at/meteorology#temperature'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first triple pattern.
	TXLTerm *object = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:2] unsignedIntegerValue]];

	GHAssertEqualStrings([object literalValue], @"warm", @"Object should have value 'warm'.");
	GHAssertEquals([object type], kTXLTermTypePlainLiteral, @"Object term should be of type kTXLTermTypePlainLiteral.");
	
	// Check subject of the third triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [thirdTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the third triple pattern.
	predicate = [TXLTerm termWithPrimaryKey:[[thirdTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#sky_coverage", @"Predicate should be 'http://schema.situmet.at/meteorology#sky_coverage'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the third triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [thirdTriple objectAtIndex:2], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Object should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should be a blank node.");
	}
}


#pragma mark -
#pragma mark Tests for ASK / SELECT queries with UNION feature. 

- (void)testCompilerForAskQueryWithUnion {
	/*
	PREFIX m: <http://schema.situmet.at/meteorology#>
	
	ASK
	FROM <txl://weather.situmet.at>
	WHERE {
		{
	 		[m:temperature "warm"].
	 	}
		UNION { 
			[m:rain []].
		}
	 	UNION { 
	 		[m:sky_coverage []].
	 	}
	}
	*/
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> ASK FROM <txl://weather.situmet.at> WHERE { { [m:temperature \"warm\"]. } UNION { [m:rain []]. } UNION { [m:sky_coverage []]. } }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result  = nil;
	NSUInteger queryPatternId = 0;
	
	result = [database executeSQLWithParameters:@"SELECT pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] intValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)5, @"There should be 5 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 5) { 
		
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:2] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:2] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:2] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:3] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:3] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:3] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:4] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:4] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:4] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's patterns (UNION).
	NSMutableArray *patterns = [NSMutableArray array];
	NSUInteger unionPatternId = 0;
	
	// Check the id of the union pattern.
	result = [database executeSQLWithParameters:@"SELECT id FROM txl_query_pattern_union WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 union pattern saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		unionPatternId = [[[result objectAtIndex:0] objectForKey:@"id"] unsignedIntegerValue];
		GHAssertNotEquals(unionPatternId, (NSUInteger)0, @"The txl_query_pattern_group id should not be 0.");
	}

	// Check the ids of the UNION subpatterns
	result = [database executeSQLWithParameters:@"SELECT id, pattern_id FROM txl_query_pattern_union_pattern WHERE union_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:unionPatternId], nil]; 

	GHAssertEquals([result count], (NSUInteger)3, @"There should be 3 union patterns saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 3) { 
		
		// First UNION pattern
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The txl_query_pattern_union_pattern id should not be 0.");
		[patterns addObject:[[result objectAtIndex:0] objectForKey:@"pattern_id"]];
		GHAssertNotEquals((NSUInteger)[[patterns objectAtIndex:0] intValue], (NSUInteger)0, @"The pattern_id should not be 0.");
		
		// Second UNION pattern
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] intValue], (NSUInteger)0, @"The txl_query_pattern_union_pattern id should not be 0.");
		[patterns addObject:[[result objectAtIndex:1] objectForKey:@"pattern_id"]];
		GHAssertNotEquals((NSUInteger)[[patterns objectAtIndex:1] intValue], (NSUInteger)0, @"The pattern_id should not be 0.");
		
		// Third UNION pattern
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:2] objectForKey:@"id"] intValue], (NSUInteger)0, @"The txl_query_pattern_union_pattern id should not be 0.");
		[patterns addObject:[[result objectAtIndex:2] objectForKey:@"pattern_id"]];
		GHAssertNotEquals((NSUInteger)[[patterns objectAtIndex:2] intValue], (NSUInteger)0, @"The pattern_id should not be 0.");
	}

	// Check query's triples.
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];
	NSMutableArray *thirdTriple = [NSMutableArray array];
	
	// For the first UNION pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [patterns objectAtIndex:0],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the first UNION pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_var_id"] intValue], (NSUInteger)0, @"The object should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object term id should not be 0.");
	}
	
	// For the second UNION pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [patterns objectAtIndex:1],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the second UNION pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		// Second triple		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// For the third UNION pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [patterns objectAtIndex:2],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the third UNION pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		// Third triple		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// Check subject of the first triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the first triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#temperature", @"Predicate should be 'http://schema.situmet.at/meteorology#temperature'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first triple pattern.
	TXLTerm *object = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:2] unsignedIntegerValue]];

	GHAssertEqualStrings([object literalValue], @"warm", @"Object should have value 'warm'.");
	GHAssertEquals([object type], kTXLTermTypePlainLiteral, @"Object term should be of type kTXLTermTypePlainLiteral.");
	
	// Check subject of the third triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [thirdTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the third triple pattern.
	predicate = [TXLTerm termWithPrimaryKey:[[thirdTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#sky_coverage", @"Predicate should be 'http://schema.situmet.at/meteorology#sky_coverage'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the third triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [thirdTriple objectAtIndex:2], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Object should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should be a blank node.");
	}
}

#pragma mark -
#pragma mark Tests for ASK / SELECT queries with group patterns feature. 

- (void)testCompilerForAskQueryWithGroup {
	/*
	PREFIX m: <http://schema.situmet.at/meteorology#>
	
	ASK
	FROM <txl://weather.situmet.at>
	WHERE {
		{ 
			[m:temperature "warm"].
	 		[m:rain []].
	 	}
	 	{
			[m:sky_coverage []].
		}
	}
	*/
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> ASK FROM <txl://weather.situmet.at> WHERE { { [m:temperature \"warm\"]. [m:rain []]. } { [m:sky_coverage []]. } }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result  = nil;
	NSUInteger queryPatternId = 0;
	
	result = [database executeSQLWithParameters:@"SELECT pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] intValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)5, @"There should be 5 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 5) { 
		
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:2] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:2] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:2] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:3] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:3] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:3] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
		
		GHAssertNotNil([[result objectAtIndex:4] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:4] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:4] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's patterns (group patterns).
	NSMutableArray *patterns = [NSMutableArray array];
	
	result = [database executeSQLWithParameters:@"SELECT id, pattern_id FROM txl_query_pattern_group WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 group patterns saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		// First group pattern
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The txl_query_pattern_group id should not be 0.");
		[patterns addObject:[[result objectAtIndex:0] objectForKey:@"pattern_id"]];
		GHAssertNotEquals((NSUInteger)[[patterns objectAtIndex:0] intValue], (NSUInteger)0, @"The pattern_id should not be 0.");
		
		// Second group pattern
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] intValue], (NSUInteger)0, @"The txl_query_pattern_group id should not be 0.");
		[patterns addObject:[[result objectAtIndex:1] objectForKey:@"pattern_id"]];
		GHAssertNotEquals((NSUInteger)[[patterns objectAtIndex:1] intValue], (NSUInteger)0, @"The pattern_id should not be 0.");
	}
	
	// Check query's triples.
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];
	NSMutableArray *thirdTriple = [NSMutableArray array];
	
	// For the first group pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [patterns objectAtIndex:0],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 triple patterns saved in the first group pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_var_id"] intValue], (NSUInteger)0, @"The object should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object term id should not be 0.");
		
		// Second triple		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[secondTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// For the second group pattern
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [patterns objectAtIndex:1],
			  nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved in the second group pattern of the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		// Third triple		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] intValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] intValue], (NSUInteger)0, @"The subject should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:0] intValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] intValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:1] intValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] intValue], (NSUInteger)0, @"The object should not be a term.");
		[thirdTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[thirdTriple objectAtIndex:2] intValue], (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// Check subject of the first triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the first triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:1] unsignedIntegerValue]];
	
	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#temperature", @"Predicate should be 'http://schema.situmet.at/meteorology#temperature'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first triple pattern.
	TXLTerm *object = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:2] unsignedIntegerValue]];

	GHAssertEqualStrings([object literalValue], @"warm", @"Object should have value 'warm'.");
	GHAssertEquals([object type], kTXLTermTypePlainLiteral, @"Object term should be of type kTXLTermTypePlainLiteral.");
	
	// Check subject of the third triple.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [thirdTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the third triple pattern.
	predicate = [TXLTerm termWithPrimaryKey:[[thirdTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#sky_coverage", @"Predicate should be 'http://schema.situmet.at/meteorology#sky_coverage'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the third triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [thirdTriple objectAtIndex:2], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Object should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should be a blank node.");
	}
}

/*
#pragma mark -
#pragma mark Tests for ASK / SELECT queries with combination of OPTIONAL, UNION, NOT EXISTS, group patterns, simple triples and blank nodes features. 

- (void)testCompilerForAskQueryWithFeaturesCombination {
	/*
	PREFIX m: <http://schema.situmet.at/meteorology#>
	
	ASK
	FROM <txl://weather.situmet.at>
	WHERE {
		[m:temperature "warm"].
		UNION { 
			[m:rain []].
		}
		UNION { 
			[m:rain []].
		}
	}
	/
}
*/


#pragma mark -
#pragma mark Tests for general SELECT queries with various forms of blank nodes. 

- (void)testCompilerForSelectQueryWithSimpleBlankNode {
	
	/*
	SELECT ?temp
	WHERE {
		[<http://schema.situmet.at/meteorology#temperature> ?temp].
	}
		 
	should be saved as 
	SELECT ?temp
	WHERE {
		[] <http://schema.situmet.at/meteorology#temperature> ?temp.
	}
		 
	The [] is saved as a blank node variable with a null name.
	*/
		 
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"SELECT ?temp WHERE { [<http://schema.situmet.at/meteorology#temperature> ?temp]. }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check query's patterns stored.
	result = [database executeSQLWithParameters:@"SELECT pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	NSUInteger queryPatternId = 0;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] unsignedIntegerValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		NSString *name = [[result objectAtIndex:0] objectForKey:@"name"];
		GHAssertEqualStrings(name, @"temp", [NSString stringWithFormat:@"Variable %@ should have name 'temp'.", name]);
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], [NSString stringWithFormat:@"Variable %@ should be in the result set.", name]);
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], [NSString stringWithFormat:@"Variable %@ should not be a blank node.", name]);
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's pattern.
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	NSUInteger subjectVarId = 0;
	NSUInteger predicateId = 0;
	NSUInteger objectVarId = 0;
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 triple pattern saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] unsignedIntegerValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] unsignedIntegerValue], (NSUInteger)0, @"The subject should not be a term.");
		subjectVarId = [[[result objectAtIndex:0] objectForKey:@"subject_var_id"] unsignedIntegerValue];
		GHAssertNotEquals(subjectVarId, (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The predicate should not be a variable.");
		predicateId = [[[result objectAtIndex:0] objectForKey:@"predicate_id"] unsignedIntegerValue];
		GHAssertNotEquals(predicateId, (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] unsignedIntegerValue], (NSUInteger)0, @"The object should not be a term.");
		objectVarId = [[[result objectAtIndex:0] objectForKey:@"object_var_id"] unsignedIntegerValue];
		GHAssertNotEquals(objectVarId, (NSUInteger)0, @"The object variable id should not be 0.");
	}
	
	// Check subject of the triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:subjectVarId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:predicateId];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#temperature", @"Predicate should be 'http://schema.situmet.at/meteorology#temperature'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:objectVarId], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"temp", @"Object should have the name 'temp'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should not be a blank node.");
	}
}


- (void)testCompilerForSelectQueryWithBlankNodeAsSubject {
	
	/*
	 SELECT ?temp
	 WHERE {
	 	[<http://schema.situmet.at/meteorology#temperature> ?temp] <http://schema.situmet.at/meteorology#rain> \"much\".
	 }
	 
	 should be saved as 
	 SELECT ?temp
	 WHERE {
		 [] <http://schema.situmet.at/meteorology#temperature> ?temp.
		 [] <http://schema.situmet.at/meteorology#rain> \"much\".
	 }
	 
	 The [] is saved as a blank node variable with a null name. The two occurrences of [] here correspond to the same blank node variable.
	 */
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"SELECT ?temp WHERE { [<http://schema.situmet.at/meteorology#temperature> ?temp] <http://schema.situmet.at/meteorology#rain> \"much\". }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check query's patterns stored.
	result = [database executeSQLWithParameters:@"SELECT pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	NSUInteger queryPatternId = 0;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] unsignedIntegerValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		NSString *name = [[result objectAtIndex:0] objectForKey:@"name"];
		GHAssertEqualStrings(name, @"temp", [NSString stringWithFormat:@"Variable %@ should have name 'temp'.", name]);
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], [NSString stringWithFormat:@"Variable %@ should be in the result set.", name]);
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], [NSString stringWithFormat:@"Variable %@ should not be a blank node.", name]);
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's pattern.
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 triple patterns saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] unsignedIntegerValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] unsignedIntegerValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] unsignedIntegerValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] unsignedIntegerValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] unsignedIntegerValue], (NSUInteger)0, @"The object should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] unsignedIntegerValue], (NSUInteger)0, @"The object variable id should not be 0.");
		
		// Second triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] unsignedIntegerValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"subject_id"] unsignedIntegerValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:0] unsignedIntegerValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"predicate_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"predicate_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:1] unsignedIntegerValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"object_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The object should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"object_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:2] unsignedIntegerValue], (NSUInteger)0, @"The object term id should not be 0.");		
	}
	
	// First triple
	// Check subject of the first triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the first triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#temperature", @"Predicate should be 'http://schema.situmet.at/meteorology#temperature'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:2], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"temp", @"Object should have the name 'temp'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should not be a blank node.");
	}
	
	// Second triple
	// Check that the subject of the second triple pattern has the same id as the subject of the first triple pattern.
	GHAssertEquals([[firstTriple objectAtIndex:0] unsignedIntegerValue], [[secondTriple objectAtIndex:0] unsignedIntegerValue], @"The subjects of the two triples should have the same id.");
	
	// Check predicate of the second triple pattern.
	predicate = [TXLTerm termWithPrimaryKey:[[secondTriple objectAtIndex:1] unsignedIntegerValue]];
	
	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#rain", @"Predicate should be 'http://schema.situmet.at/meteorology#rain'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the second triple pattern.
	TXLTerm *object = [TXLTerm termWithPrimaryKey:[[secondTriple objectAtIndex:2] unsignedIntegerValue]];

	GHAssertEqualStrings([object literalValue], @"much", @"Object should have the value 'much'.");
	GHAssertEquals([object type], kTXLTermTypePlainLiteral, @"Object term should be of type kTXLTermTypePlainLiteral.");
}


- (void)testCompilerForSelectQueryWithBlankNodeSameSubject {
	
	/*
	 SELECT ?temp
	 WHERE {
	 	[<http://schema.situmet.at/meteorology#temperature> ?temp;
		 <http://schema.situmet.at/meteorology#rain> \"much\"].
	 }
	 
	 should be saved as 
	 SELECT ?temp
	 WHERE {
		 [] <http://schema.situmet.at/meteorology#temperature> ?temp.
		 [] <http://schema.situmet.at/meteorology#rain> \"much\".
	 }
	 
	 The [] is saved as a blank node variable with a null name. The two occurrences of [] here correspond to the same blank node variable.
	 */
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"SELECT ?temp WHERE { [<http://schema.situmet.at/meteorology#temperature> ?temp; <http://schema.situmet.at/meteorology#rain> \"much\"]. }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check query's patterns stored.
	result = [database executeSQLWithParameters:@"SELECT pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	NSUInteger queryPatternId = 0;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] unsignedIntegerValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		NSString *name = [[result objectAtIndex:0] objectForKey:@"name"];
		GHAssertEqualStrings(name, @"temp", [NSString stringWithFormat:@"Variable %@ should have name 'temp'.", name]);
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], [NSString stringWithFormat:@"Variable %@ should be in the result set.", name]);
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], [NSString stringWithFormat:@"Variable %@ should not be a blank node.", name]);
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's pattern.
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 triple patterns saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] unsignedIntegerValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] unsignedIntegerValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] unsignedIntegerValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] unsignedIntegerValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] unsignedIntegerValue], (NSUInteger)0, @"The object should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] unsignedIntegerValue], (NSUInteger)0, @"The object variable id should not be 0.");
		
		// Second triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] unsignedIntegerValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"subject_id"] unsignedIntegerValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:0] unsignedIntegerValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"predicate_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"predicate_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:1] unsignedIntegerValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"object_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The object should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"object_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:2] unsignedIntegerValue], (NSUInteger)0, @"The object term id should not be 0.");		
	}
	
	// First triple
	// Check subject of the first triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the first triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#temperature", @"Predicate should be 'http://schema.situmet.at/meteorology#temperature'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:2], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"temp", @"Object should have the name 'temp'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should not be a blank node.");
	}
	
	// Second triple
	// Check that the subject of the second triple pattern has the same id as the subject of the first triple pattern.
	GHAssertEquals([[firstTriple objectAtIndex:0] unsignedIntegerValue], [[secondTriple objectAtIndex:0] unsignedIntegerValue], @"The subjects of the two triples should have the same id.");
	
	// Check predicate of the second triple pattern.
	predicate = [TXLTerm termWithPrimaryKey:[[secondTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#rain", @"Predicate should be 'http://schema.situmet.at/meteorology#rain'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the second triple pattern.
	TXLTerm *object = [TXLTerm termWithPrimaryKey:[[secondTriple objectAtIndex:2] unsignedIntegerValue]];

	GHAssertEqualStrings([object literalValue], @"much", @"Object should have the value 'much'.");
	GHAssertEquals([object type], kTXLTermTypePlainLiteral, @"Object term should be of type kTXLTermTypePlainLiteral.");
}


- (void)testCompilerForSelectQueryWithBlankNodeSamePredicate {
	
	/*
	 SELECT ?temp
	 WHERE {
	 	[<http://schema.situmet.at/meteorology#temperature> ?temp, \"much\"].
	 }
	 
	 should be saved as 
	 SELECT ?temp
	 WHERE {
	 	[] <http://schema.situmet.at/meteorology#temperature> ?temp.
	 	[] <http://schema.situmet.at/meteorology#temperature> \"much\".
	 }
	 
	 The [] is saved as a blank node variable with a null name. The two occurrences of [] here correspond to the same blank node variable.
	 */
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"SELECT ?temp WHERE { [<http://schema.situmet.at/meteorology#temperature> ?temp, \"much\"]. }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check query's patterns stored.
	result = [database executeSQLWithParameters:@"SELECT pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	NSUInteger queryPatternId = 0;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] unsignedIntegerValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		NSString *name = [[result objectAtIndex:0] objectForKey:@"name"];
		GHAssertEqualStrings(name, @"temp", [NSString stringWithFormat:@"Variable %@ should have name 'temp'.", name]);
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], [NSString stringWithFormat:@"Variable %@ should be in the result set.", name]);
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], [NSString stringWithFormat:@"Variable %@ should not be a blank node.", name]);
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's pattern.
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 triple patterns saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] unsignedIntegerValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] unsignedIntegerValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] unsignedIntegerValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] unsignedIntegerValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_id"] unsignedIntegerValue], (NSUInteger)0, @"The object should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] unsignedIntegerValue], (NSUInteger)0, @"The object variable id should not be 0.");
		
		// Second triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] unsignedIntegerValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"subject_id"] unsignedIntegerValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:0] unsignedIntegerValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"predicate_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"predicate_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:1] unsignedIntegerValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"object_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The object should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"object_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:2] unsignedIntegerValue], (NSUInteger)0, @"The object term id should not be 0.");		
	}
	
	// First triple
	// Check subject of the first triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the first triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#temperature", @"Predicate should be 'http://schema.situmet.at/meteorology#temperature'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:2], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"temp", @"Object should have the name 'temp'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should not be a blank node.");
	}
	
	// Second triple
	// Check that the subject of the second triple pattern has the same id as the subject of the first triple pattern.
	GHAssertEquals([[firstTriple objectAtIndex:0] unsignedIntegerValue], [[secondTriple objectAtIndex:0] unsignedIntegerValue], @"The subjects of the two triples should have the same id.");
	
	// Check that the predicates of the first and second triple patterns have the same id.
	GHAssertEquals([[firstTriple objectAtIndex:1] unsignedIntegerValue], [[secondTriple objectAtIndex:1] unsignedIntegerValue], @"The predicates of the two triples should have the same id.");
	
	// Check object of the second triple pattern.
	TXLTerm *object = [TXLTerm termWithPrimaryKey:[[secondTriple objectAtIndex:2] unsignedIntegerValue]];

	GHAssertEqualStrings([object literalValue], @"much", @"Object should have the value 'much'.");
	GHAssertEquals([object type], kTXLTermTypePlainLiteral, @"Object term should be of type kTXLTermTypePlainLiteral.");
}


- (void)testCompilerForSelectQueryWithBlankNodeAsObject {
	
	/*
	 SELECT ?temp
	 WHERE {
	 	?temp <http://schema.situmet.at/meteorology#temperature> [<http://schema.situmet.at/meteorology#rain> \"much\"].
	 }
	 
	 should be saved as 
	 SELECT ?temp
	 WHERE {
	 	[] <http://schema.situmet.at/meteorology#rain> \"much\".
	 	?temp <http://schema.situmet.at/meteorology#temperature> [].
	 }
	 
	 The [] is saved as a blank node variable with a null name. The two occurrences of [] here correspond to the same blank node variable.
	 */
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"SELECT ?temp WHERE { ?temp <http://schema.situmet.at/meteorology#temperature> [<http://schema.situmet.at/meteorology#rain> \"much\"]. }" 
											 parameters:nil 
												options:nil 
												  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check query's patterns stored.
	result = [database executeSQLWithParameters:@"SELECT pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	NSUInteger queryPatternId = 0;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] unsignedIntegerValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's variables.
	result = [database executeSQLWithParameters:@"SELECT name, in_resultset, is_blanknode FROM txl_query_variable WHERE query_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 variables saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		
		NSString *name = [[result objectAtIndex:0] objectForKey:@"name"];
		GHAssertEqualStrings(name, @"temp", [NSString stringWithFormat:@"Variable %@ should have name 'temp'.", name]);
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"in_resultset"] boolValue], [NSString stringWithFormat:@"Variable %@ should be in the result set.", name]);
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], [NSString stringWithFormat:@"Variable %@ should not be a blank node.", name]);
		
		GHAssertNotNil([[result objectAtIndex:1] objectForKey:@"name"], @"Variable should not have name nil.");
		GHAssertFalse([[[result objectAtIndex:1] objectForKey:@"in_resultset"] boolValue], @"This variable should not be in the result set.");
		GHAssertTrue([[[result objectAtIndex:1] objectForKey:@"is_blanknode"] boolValue], @"This variable should be a blank node.");
	}
	
	// Check query's pattern.
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 triple patterns saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] unsignedIntegerValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] unsignedIntegerValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] unsignedIntegerValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] unsignedIntegerValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The object should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] unsignedIntegerValue], (NSUInteger)0, @"The object term id should not be 0.");
		
		// Second triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] unsignedIntegerValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"subject_id"] unsignedIntegerValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:0] unsignedIntegerValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"predicate_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"predicate_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:1] unsignedIntegerValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"object_id"] unsignedIntegerValue], (NSUInteger)0, @"The object should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"object_var_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:2] unsignedIntegerValue], (NSUInteger)0, @"The object variable id should not be 0.");		
	}
	
	
	// First triple
	// Check subject of the first triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertNotNil([[result objectAtIndex:0] objectForKey:@"name"], @"Subject should not have a nil name.");
		GHAssertTrue([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should be a blank node.");
	}
	
	// Check predicate of the first triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:1] unsignedIntegerValue]];
	
	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#rain", @"Predicate should be 'http://schema.situmet.at/meteorology#rain'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first triple pattern.
	TXLTerm *object = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:2] unsignedIntegerValue]];

	GHAssertEqualStrings([object literalValue], @"much", @"Object should have the value 'much'.");
	GHAssertEquals([object type], kTXLTermTypePlainLiteral, @"Object term should be of type kTXLTermTypePlainLiteral.");
	
	
	// Second triple
	// Check subject of the second triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [secondTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"temp", @"Object should have the name 'temp'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Object should not be a blank node.");
	}
	
	// Check predicate of the second triple pattern.
	predicate = [TXLTerm termWithPrimaryKey:[[secondTriple objectAtIndex:1] unsignedIntegerValue]];

	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#temperature", @"Predicate should be 'http://schema.situmet.at/meteorology#temperature'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the second triple pattern has the same id as the subject of the first triple pattern.
	GHAssertEquals([[firstTriple objectAtIndex:0] unsignedIntegerValue], [[secondTriple objectAtIndex:2] unsignedIntegerValue], @"The object of the second triple pattern should have the same id as the subject of the first triple pattern.");
}


#pragma mark -
#pragma mark Tests for parsing literals. 


- (void)testCompilerForParsingSimpleLiterals {
	
	/*
	 PREFIX m: <http://schema.situmet.at/meteorology#>
	 
	 ASK
	 FROM <txl://weather.situmet.at>
	 WHERE {
	 	_:x m:temperature '42', "42", '''42''', """42""".
	 }
	 */
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> ASK FROM <txl://weather.situmet.at> WHERE { _:x m:temperature '42', \"42\", '''42''', \"\"\"42\"\"\".}" 
														 parameters:nil 
															options:nil 
															  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check query's terms stored.
	result = [database executeSQLWithParameters:@"SELECT DISTINCT object_id FROM txl_query as q, txl_query_pattern_triple as t WHERE q.id = ? AND q.pattern_id = t.in_pattern_id"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 term saved as object for this query.");

	TXLTerm *object = nil;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		object = [TXLTerm termWithPrimaryKey:[[[result objectAtIndex:0] objectForKey:@"object_id"] unsignedIntegerValue]];

		GHAssertEquals([object type], kTXLTermTypePlainLiteral, [NSString stringWithFormat:@"Term with value %@ should be of type kTXLTermTypePlainLiteral.", [object literalValue]]);
		GHAssertEqualStrings([object literalValue], @"42", @"Term should have value '42'.");
		GHAssertNil([object language], [NSString stringWithFormat:@"Term with value %@ should have a nil language meta.", [object literalValue]]);
		GHAssertNil([object dataType], [NSString stringWithFormat:@"Term with value %@ should have a nil datatype meta.", [object literalValue]]);
	}
}


- (void)testCompilerForParsingLiteralsWithEscapeCharacters {
	
	/*
	 PREFIX m: <http://schema.situmet.at/meteorology#>
	 
	 ASK
	 FROM <txl://weather.situmet.at>
	 WHERE {
	 	_:x m:temperature '4\"2', '4\'2', "4\"2", "4\'2", '\"42\"', '\'42\''.
	 }
	 */
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> ASK FROM <txl://weather.situmet.at> WHERE { _:x m:temperature '4\\\"2', '4\\'2', \"4\\\"2\", \"4\\'2\", '\\\"42\\\"', '\\'42\\''.}" 
														 parameters:nil 
															options:nil 
															  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check query's terms stored.
	result = [database executeSQLWithParameters:@"SELECT DISTINCT object_id FROM txl_query as q, txl_query_pattern_triple as t WHERE q.id = ? AND q.pattern_id = t.in_pattern_id"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)4, @"There should be 4 terms saved as objects for this query.");
	
	TXLTerm *object = nil;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 4) { 
		// First term
		object = [TXLTerm termWithPrimaryKey:[[[result objectAtIndex:0] objectForKey:@"object_id"] unsignedIntegerValue]];

		GHAssertEquals([object type], kTXLTermTypePlainLiteral, [NSString stringWithFormat:@"Term with value %@ should be of type kTXLTermTypePlainLiteral.", [object literalValue]]);
		GHAssertEqualStrings([object literalValue], @"4\\\"2", @"Term should have value 4\\\"2.");
		GHAssertNil([object language], [NSString stringWithFormat:@"Term with value %@ should have a nil language meta.", [object literalValue]]);
		GHAssertNil([object dataType], [NSString stringWithFormat:@"Term with value %@ should have a nil datatype meta.", [object literalValue]]);
		
		// Second term
		object = [TXLTerm termWithPrimaryKey:[[[result objectAtIndex:1] objectForKey:@"object_id"] unsignedIntegerValue]];

		GHAssertEquals([object type], kTXLTermTypePlainLiteral, [NSString stringWithFormat:@"Term with value %@ should be of type kTXLTermTypePlainLiteral.", [object literalValue]]);
		GHAssertEqualStrings([object literalValue], @"4\\'2", @"Term should have value 4\\'2.");
		GHAssertNil([object language], [NSString stringWithFormat:@"Term with value %@ should have a nil language meta.", [object literalValue]]);
		GHAssertNil([object dataType], [NSString stringWithFormat:@"Term with value %@ should have a nil datatype meta.", [object literalValue]]);
		
		// Third term
		object = [TXLTerm termWithPrimaryKey:[[[result objectAtIndex:2] objectForKey:@"object_id"] unsignedIntegerValue]];

		GHAssertEquals([object type], kTXLTermTypePlainLiteral, [NSString stringWithFormat:@"Term with value %@ should be of type kTXLTermTypePlainLiteral.", [object literalValue]]);
		GHAssertEqualStrings([object literalValue], @"\\\"42\\\"", @"Term should have value \\\"42\\\".");
		GHAssertNil([object language], [NSString stringWithFormat:@"Term with value %@ should have a nil language meta.", [object literalValue]]);
		GHAssertNil([object dataType], [NSString stringWithFormat:@"Term with value %@ should have a nil datatype meta.", [object literalValue]]);
		
		// Forth term
		object = [TXLTerm termWithPrimaryKey:[[[result objectAtIndex:3] objectForKey:@"object_id"] unsignedIntegerValue]];
		
		GHAssertEquals([object type], kTXLTermTypePlainLiteral, [NSString stringWithFormat:@"Term with value %@ should be of type kTXLTermTypePlainLiteral.", [object literalValue]]);
		GHAssertEqualStrings([object literalValue], @"\\'42\\'", @"Term should have value \\'42\\'.");
		GHAssertNil([object language], [NSString stringWithFormat:@"Term with value %@ should have a nil language meta.", [object literalValue]]);
		GHAssertNil([object dataType], [NSString stringWithFormat:@"Term with value %@ should have a nil datatype meta.", [object literalValue]]);
	
	}
}


- (void)testCompilerForParsingLiteralsWithLanguage {
	
	/*
	 PREFIX m: <http://schema.situmet.at/meteorology#>
	 
	 ASK
	 FROM <txl://weather.situmet.at>
	 WHERE {
	 	_:x m:temperature "high"@en.
	 }
	 */
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> ASK FROM <txl://weather.situmet.at> WHERE { _:x m:temperature \"high\"@en.}" 
														parameters:nil 
														   options:nil 
															 error:&error];
	NSUInteger queryId = [query primaryKey];
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check query's terms stored.
	result = [database executeSQLWithParameters:@"SELECT DISTINCT object_id FROM txl_query as q, txl_query_pattern_triple as t WHERE q.id = ? AND q.pattern_id = t.in_pattern_id"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 term saved as object for this query.");
	
	TXLTerm *object = nil;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		object = [TXLTerm termWithPrimaryKey:[[[result objectAtIndex:0] objectForKey:@"object_id"] unsignedIntegerValue]];

		GHAssertEquals([object type], kTXLTermTypePlainLiteral, [NSString stringWithFormat:@"Term with value %@ should be of type kTXLTermTypePlainLiteral.", [object literalValue]]);
		GHAssertEqualStrings([object literalValue], @"high", @"Term should have value high");
		GHAssertEqualStrings([object language], @"en", [NSString stringWithFormat:@"Term with value %@ should have meta en.", [object literalValue]]);
		GHAssertNil([object dataType], [NSString stringWithFormat:@"Term with value %@ should have a nil datatype meta.", [object literalValue]]);
	}
}


- (void)testCompilerForParsingTypedLiterals {
	
	/*
	 PREFIX m: <http://schema.situmet.at/meteorology#>
	 
	 ASK
	 FROM <txl://weather.situmet.at>
	 WHERE {
	 	_:x m:temperature "txl_high"^^m:tempdatatype.
	 }
	 */
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@"PREFIX m: <http://schema.situmet.at/meteorology#> ASK FROM <txl://weather.situmet.at> WHERE { _:x m:temperature \"txl_high\"^^m:tempdatatype.}" 
														 parameters:nil 
															options:nil 
															  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check query's terms stored.
	result = [database executeSQLWithParameters:@"SELECT DISTINCT object_id FROM txl_query as q, txl_query_pattern_triple as t WHERE q.id = ? AND q.pattern_id = t.in_pattern_id"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	GHAssertEquals([result count], (NSUInteger)1, @"There should be 1 term saved as object for this query.");
	
	TXLTerm *object = nil;
	TXLTerm *datatypeTerm = nil;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		// First term
		object = [TXLTerm termWithPrimaryKey:[[[result objectAtIndex:0] objectForKey:@"object_id"] unsignedIntegerValue]];

		GHAssertEquals([object type], kTXLTermTypeTypedLiteral, [NSString stringWithFormat:@"Term with value %@ should be of type kTXLTermTypeTypedLiteral.", [object literalValue]]);
		GHAssertEqualStrings([object literalValue], @"txl_high", @"Term should have value txl_high.");
		GHAssertNil([object language], [NSString stringWithFormat:@"Term with value %@ should have a nil language meta.", [object literalValue]]);
		
		datatypeTerm = [object dataType];

		GHAssertEquals([datatypeTerm type], kTXLTermTypePlainLiteral, [NSString stringWithFormat:@"Term with value %@ should be of type kTXLTermTypePlainLiteral.", [datatypeTerm literalValue]]);
		GHAssertEqualStrings([datatypeTerm literalValue], @"http://schema.situmet.at/meteorology#tempdatatype", @"Term should have value http://schema.situmet.at/meteorology#tempdatatype.");
		GHAssertNil([datatypeTerm dataType], [NSString stringWithFormat:@"Term with value %@ should have a nil datatype meta.", [datatypeTerm literalValue]]);		
		GHAssertNil([datatypeTerm language], [NSString stringWithFormat:@"Term with value %@ should have a nil language meta.", [datatypeTerm literalValue]]);
	}
}



#pragma mark -
#pragma mark Tests for parsing unicode characters. 

- (void)testCompilerForParsingUnicode {
	
	/*
	 PREFIX m: <http://schema.situmet.at/meteorology#>
	 
	 SELECT ?weather
	 FROM <txl://weather.situmet.at>
	 WHERE {
	 	 ?weather m:catägory "schönwetter".
	 	 ?weather m:category <http://situmet/categoty/schönwetter>.
	 }
	 */
	
	NSError *error;
	
	TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:@" PREFIX m: <http://schema.situmet.at/meteorology#> SELECT ?weather FROM <txl://weather.situmet.at> WHERE { ?weather m:catägory \"schönwetter\". ?weather m:category <http://situmet/categoty/schönwetter>. }" 
														 parameters:nil 
															options:nil 
															  error:&error];
	NSUInteger queryId = [query primaryKey];
	
	// Check that the query was saved, by checking its id.
	GHAssertNotEquals(queryId, (NSUInteger)0, @"PK should not be 0.");
	
	TXLDatabase *database = [[TXLManager sharedManager] database]; 
	NSArray *result = nil;
	
	// Check query's patterns stored.
	result = [database executeSQLWithParameters:@"SELECT pattern_id FROM txl_query WHERE id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryId], nil]; 
	
	NSUInteger queryPatternId = 0;
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		queryPatternId = [[[result objectAtIndex:0] objectForKey:@"pattern_id"] unsignedIntegerValue]; 
	} 
	
	GHAssertNotEquals(queryPatternId, (NSUInteger)0, @"Pattern id should not be 0.");
	
	// Check query's pattern.
	result = [database executeSQLWithParameters:@"SELECT id, subject_id, subject_var_id, predicate_id, predicate_var_id, object_id, object_var_id FROM txl_query_pattern_triple WHERE in_pattern_id = ?"
										  error:&error, 
			  [NSNumber numberWithInt:queryPatternId], nil]; 
	
	NSMutableArray *firstTriple = [NSMutableArray array];
	NSMutableArray *secondTriple = [NSMutableArray array];
	
	GHAssertEquals([result count], (NSUInteger)2, @"There should be 2 triple patterns saved for the query.");
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 2) { 
		// First triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"id"] unsignedIntegerValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"subject_id"] unsignedIntegerValue], (NSUInteger)0, @"The subject should not be a term.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:0] unsignedIntegerValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"predicate_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"predicate_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:1] unsignedIntegerValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:0] objectForKey:@"object_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The object should not be a variable.");
		[firstTriple addObject:[[result objectAtIndex:0] objectForKey:@"object_id"]];
		GHAssertNotEquals((NSUInteger)[[firstTriple objectAtIndex:2] unsignedIntegerValue], (NSUInteger)0, @"The object term id should not be 0.");
		
		// Second triple
		GHAssertNotEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"id"] unsignedIntegerValue], (NSUInteger)0, @"The query_pattern_triple id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"subject_id"] unsignedIntegerValue], (NSUInteger)0, @"The subject should not be a term.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"subject_var_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:0] unsignedIntegerValue], (NSUInteger)0, @"The subject variable id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"predicate_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The predicate should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"predicate_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:1] unsignedIntegerValue], (NSUInteger)0, @"The predicate term id should not be 0.");
		
		GHAssertEquals((NSUInteger)[[[result objectAtIndex:1] objectForKey:@"object_var_id"] unsignedIntegerValue], (NSUInteger)0, @"The object should not be a variable.");
		[secondTriple addObject:[[result objectAtIndex:1] objectForKey:@"object_id"]];
		GHAssertNotEquals([[secondTriple objectAtIndex:2] unsignedIntegerValue], (NSUInteger)0, @"The object term id should not be 0.");		
	}
	
	// First triple
	// Check subject of the first triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [firstTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"weather", @"Subject should have name 'weather'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should not be a blank node.");
	}
	
	// Check predicate of the first triple pattern.
	TXLTerm *predicate = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:1] unsignedIntegerValue]];
	
	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#catägory", @"Predicate should be 'http://schema.situmet.at/meteorology#catägory'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the first triple pattern.
	TXLTerm *object = [TXLTerm termWithPrimaryKey:[[firstTriple objectAtIndex:2] unsignedIntegerValue]];
	
	GHAssertEqualStrings([object literalValue], @"schönwetter", @"Object should have the value 'schönwetter'.");
	GHAssertEquals([object type], kTXLTermTypePlainLiteral, @"Object term should be of type kTXLTermTypePlainLiteral.");
	
	
	// Second triple
	// Check subject of the second triple pattern.
	result = [database executeSQLWithParameters:@"SELECT name, is_blanknode FROM txl_query_variable WHERE id = ?"
										  error:&error, 
			  [secondTriple objectAtIndex:0], nil]; 
	
	if (result == nil) {
		[NSException exceptionWithName:@"TXLSPARQLCompilerTestException"
                                reason:[error localizedDescription]
                              userInfo:nil];
		
	} else if ([result count] == 1) { 
		GHAssertEqualStrings([[result objectAtIndex:0] objectForKey:@"name"], @"weather", @"Subject should have name 'weather'.");
		GHAssertFalse([[[result objectAtIndex:0] objectForKey:@"is_blanknode"] boolValue], @"Subject should not be a blank node.");
	}
	
	// Check predicate of the second triple pattern.
	predicate = [TXLTerm termWithPrimaryKey:[[secondTriple objectAtIndex:1] unsignedIntegerValue]];
	
	GHAssertEqualStrings([predicate iriValue], @"http://schema.situmet.at/meteorology#category", @"Predicate should be 'http://schema.situmet.at/meteorology#category'.");
	GHAssertEquals([predicate type], kTXLTermTypeIRI, @"Predicate term should be of type kTXLTermTypeIRI.");
	
	// Check object of the second triple pattern has the same id as the subject of the first triple pattern.
	object = [TXLTerm termWithPrimaryKey:[[secondTriple objectAtIndex:2] unsignedIntegerValue]];
	
	GHAssertEqualStrings([object iriValue], @"http://situmet/categoty/schönwetter", @"Object should have the value 'http://situmet/categoty/schönwetter'.");
	GHAssertEquals([object type], kTXLTermTypeIRI, @"Object term should be of type kTXLTermTypeIRI.");	
}


@end

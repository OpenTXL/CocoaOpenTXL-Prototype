//
//  TXLSPARQLCompiler.m
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

#import "TXLSPARQLCompiler.h"
#import "TXLContext.h"
#import "TXLTerm.h"
#import "TXLQuery.h"
#import "TXLDatabase.h"
#import "TXLManager.h"

#define SQL_ON_ERROR_RETURN(s) {if ([database executeSQL:s error:error] == nil) {return nil;}}
#define SQL_ON_ERROR_RETURN_FORMAT(...) {if ([database executeSQL:[NSString stringWithFormat:__VA_ARGS__] error:error] == nil) {return nil;}}

NSString * const TXLSPARQLCompilerErrorDomain = @"org.opentxl.TXLSPARQLCompilerErrorDomain";

int sparql_YYINPUT(char* theBuffer, int maxSize, TXLSPARQLCompiler *compiler) {
	return [compiler yyinputToBuffer:theBuffer
                            withSize:maxSize];
}


@interface TXLSPARQLCompiler ()

@property (assign) void *yyscanner;
@property (retain) NSData *buf;
@property (assign) NSInteger pos;
@property (assign) NSUInteger length;

@end


@implementation TXLSPARQLCompiler

@synthesize queryId;
@synthesize partOfQuery;
@synthesize selectStar;
@synthesize prefixes;
@synthesize variables;
@synthesize patternIds;
@synthesize yyscanner;
@synthesize buf;
@synthesize pos;
@synthesize length;
@synthesize compilerError;



#pragma mark -
#pragma mark Memory Management

- (id)init {
    if ((self = [super init])) {
        
        // TODO: Handle Errors
        sparql_lex_init(&yyscanner);
        
        self.selectStar = NO;
        self.prefixes = [NSMutableDictionary dictionary];
        self.variables = [NSMutableDictionary dictionary];
        self.patternIds = [NSMutableArray array];
        
        sparql_set_extra(self, yyscanner);
    }
    return self;
}

- (void)dealloc {
	[buf release];
	[prefixes release];
	[variables release];
	[patternIds release];
	[compilerError release];
    
    sparql_lex_destroy(yyscanner);
    [super dealloc];
}

#pragma mark -
#pragma mark -

- (int)yyinputToBuffer:(char *)theBuffer
              withSize:(int)maxSize {
	int res;
	if (self.pos >= self.length) {
        res = 0;	//YY_NULL;
    } else {												
		res = self.length - self.pos;							
        res = res > (int)maxSize ? maxSize : res;
		const char *bufAsChars = [self.buf bytes];
		memcpy(theBuffer, bufAsChars + self.pos, res);
		self.pos += res;									
	}												
	return res;
}


#pragma mark -
#pragma mark Compile SPARQL Expression

+ (TXLQuery *)compileQueryWithExpression:(NSString *)expression
                              parameters:(NSDictionary *)parameters
                                 options:(NSDictionary *)options
                                   error:(NSError **)error {
    
	TXLDatabase *database = [[TXLManager sharedManager] database];

	
	// The compiler should be reentrant. 
	// Therefore the FLEX scanner and the BISON parser are used in reentrant mode and
	// a new instance of the TXLSPARQLCompiler class is used. That happens because the scanner and parser
	// use properties of this class. 
    TXLSPARQLCompiler *compiler = [[[TXLSPARQLCompiler alloc] init] autorelease];
    
    if (compiler == nil) {
        return nil;
    }
	
	// Create the main graph pattern of the query and save it to the database.
	// Insert the compiled query into the database.
    NSArray *result = [database executeSQLWithParameters:@"INSERT INTO txl_query_pattern DEFAULT VALUES"
										  error:error, nil];

	if (result == nil) {
		return nil;
	}    
    
    [compiler.patternIds addObject:[NSNumber numberWithUnsignedInteger:database.lastInsertRowid]];
	
	
	// ----------------------------------------
	
	// Insert the query into the database, using the query pattern id, of the newly created query pattern.
	result = [database executeSQLWithParameters:@"INSERT INTO txl_query (sparql, pattern_id) VALUES (?, ?)" error:error,
			  expression,
			  [compiler.patternIds lastObject],
			  nil];
	
	if (result == nil) {
		return nil;
	}
    
    compiler.queryId = database.lastInsertRowid;
    
	// ----------------------------------------
	
	// Start the parsing of the query. 
	// The FLEX scanner and the BISON parser are used to parse the query.	
	// The query is parsed sequentially. 
	// First the variables are scanned and stored in the database (select clause). each variable in a query is stored only once.
    // Then the possible contexts are scanned and stored in the database (from clause). Contexts are also stored once.
	// Finally, the patterns are scanned and stored (where clause).
	
	compiler.buf = [expression dataUsingEncoding:NSUTF8StringEncoding];
	compiler.length = [compiler.buf length];
	compiler.pos = 0;
	
	// The value returned by sparql_parse is 0 if parsing was successful (return is due to end-of-input).
	// The value is 1 if parsing failed because of invalid input, i.e., input that contains a syntax error or that causes YYABORT to be invoked.
	// The value is 2 if parsing failed due to memory exhaustion. 
	int parsingResult = sparql_parse(compiler, compiler.yyscanner);
	
	if(parsingResult == 0) {
		// Create the tables for the result set of this query.
		// Find which variables should be in the result set of this query.
		result = [database executeSQLWithParameters:@"SELECT id FROM txl_query_variable WHERE query_id = ? and in_resultset = ?"
											  error:error,
				  [NSNumber numberWithUnsignedInteger:compiler.queryId], 
				  [NSNumber numberWithBool:YES], 
				  nil];
        
        if (result == nil) {
            return nil;
        }
		
		// Create the sql text for the creation of the 'resultset' table
		NSString *resultsetTableName = [NSString stringWithFormat:@"txl_resultset_%d", compiler.queryId];
		NSMutableString *sql;
		
        sql = [NSMutableString stringWithFormat:@"CREATE TABLE %@ ( \
               id integer NOT NULL PRIMARY KEY,	 \
               mos_id integer NOT NULL REFERENCES txl_movingobjectsequence (id)", resultsetTableName];
        
        // Add a column for each variable in the result set
        for (NSDictionary *dict in result) {		
            [sql appendFormat:@", var_%d integer REFERENCES txl_term (id)", [[dict objectForKey:@"id"] unsignedIntegerValue]];
        }
        
        [sql appendString:@")"];
        
        // Create the 'resultset' table
        SQL_ON_ERROR_RETURN(sql);
		
		// Create the 'created' table
		NSString *createdTableName = [NSString stringWithFormat:@"txl_resultset_%d_created", compiler.queryId];
		
        SQL_ON_ERROR_RETURN_FORMAT(@"CREATE TABLE %@ ( \
                                   id integer NOT NULL PRIMARY KEY, \
                                   resultset_id integer NOT NULL UNIQUE REFERENCES %@ (id), \
                                   revision_id integer NOT NULL REFERENCES txl_revision (id))",
                                   createdTableName, resultsetTableName);
        
        SQL_ON_ERROR_RETURN_FORMAT(@"CREATE INDEX txl_resultset_%d_created_resultset_id ON %@ (resultset_id)", compiler.queryId, createdTableName);
        SQL_ON_ERROR_RETURN_FORMAT(@"CREATE INDEX txl_resultset_%d_created_revision_id ON %@ (revision_id)", compiler.queryId, createdTableName);
        
        
        // Create the 'removed' table
        NSString *removedTableName = [NSString stringWithFormat:@"txl_resultset_%d_removed", compiler.queryId];	
        
        SQL_ON_ERROR_RETURN_FORMAT(@"CREATE TABLE %@ ( \
                                   id integer NOT NULL PRIMARY KEY, \
                                   resultset_id integer NOT NULL UNIQUE REFERENCES %@ (id), \
                                   revision_id integer NOT NULL REFERENCES txl_revision (id))",
                                   removedTableName, resultsetTableName);
        
        SQL_ON_ERROR_RETURN_FORMAT(@"CREATE INDEX txl_resultset_%d_removed_resultset_id ON %@ (resultset_id)", compiler.queryId, removedTableName);
		SQL_ON_ERROR_RETURN_FORMAT(@"CREATE INDEX txl_resultset_%d_removed_revision_id ON %@ (revision_id)", compiler.queryId, removedTableName);
		
        
		// ----------------------------------------
		
		return [TXLQuery queryWithPrimaryKey:compiler.queryId];
		
	} else if (parsingResult == 1) {
        
		// raise syntax error
		if(compiler.compilerError == nil){
			NSDictionary *error_dict = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Query parsing failed because of invalid input, i.e., input that contains a syntax error or that causes YYABORT to be invoked.", nil) 
																   forKey:NSLocalizedDescriptionKey];
			if (error != nil) {
				*error = [NSError errorWithDomain:TXLSPARQLCompilerErrorDomain
											 code:TXL_SPARQL_COMPILER_ERROR_SPARQL_SYNTAX_ERROR
										 userInfo:error_dict];
			}
		} else {
			if (error != nil) {
	             *error = compiler.compilerError;
			}
		}
		
		NSLog(@"%@", [[compiler.compilerError userInfo] objectForKey:NSLocalizedDescriptionKey]);
		
		return nil;		
	
	} else if (parsingResult == 2) {
        
		// raise memory error
		if(compiler.compilerError == nil){
			NSDictionary *error_dict = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Query parsing failed due to memory exhaustion.", nil) 
																   forKey:NSLocalizedDescriptionKey];
            if (error != nil) {
				*error = [NSError errorWithDomain:TXLSPARQLCompilerErrorDomain
											 code:TXL_SPARQL_COMPILER_ERROR_MEMORY_EXHAUSTION
										 userInfo:error_dict];
			}
        } else {
			if(error != nil){
				*error = compiler.compilerError;
			}
		}		
		
		NSLog(@"%@", [[compiler.compilerError userInfo] objectForKey:NSLocalizedDescriptionKey]);
		
		return nil;		
		
	} else {
		return nil;
	}
}


@end

//
//  TXLSPARQLCompiler.h
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

#import <Foundation/Foundation.h>


extern NSString * const TXLSPARQLCompilerErrorDomain;

#define TXL_SPARQL_COMPILER_ERROR_QUERY_NAME_USED 1
#define TXL_SPARQL_COMPILER_ERROR_RESULT_SET_TABLE_EXISTS 2
#define TXL_SPARQL_COMPILER_ERROR_RESULT_SET_CREATED_TABLE_EXISTS 3
#define TXL_SPARQL_COMPILER_ERROR_RESULT_SET_REMOVED_TABLE_EXISTS 4
#define TXL_SPARQL_COMPILER_ERROR_SPARQL_SYNTAX_ERROR 5
#define TXL_SPARQL_COMPILER_ERROR_MEMORY_EXHAUSTION 6


typedef enum {
    kTXLQueryPartBase               = 1,
    kTXLQueryPartPrefix             = 2,
    kTXLQueryPartSelectAsk 			= 3,
	kTXLQueryPartConstruct			= 4,
    kTXLQueryPartFrom               = 5,
	kTXLQueryPartWhere              = 6
} kTXLQueryPart;


@class TXLQuery;


@interface TXLSPARQLCompiler : NSObject {

@private
	void *yyscanner;    // state of the lexer 
	
	NSData *buf; 		// buffer we read from 
	NSInteger pos; 		// current position in buf 
	NSUInteger length;	// length of buf 
	
	kTXLQueryPart partOfQuery;	// The part of the query, where the compiler is currenlty:
							 	// 1 for the 'BASE' part
								// 2 for the 'PREFIX' part 
								// 3 for the 'SELECT', 'ASK'
								// 4 for the 'CONSTRUCT' part
								// 5 for the 'FROM' part 
								// 6 for the 'WHERE' part
	
    // the id of the parsed query
	NSUInteger queryId;
    
    
    // TRUE if the parsed query is a select all (*) query,
    // FALSE otherwise (if specific variables are selected
    // or if it is an ASK, CONSTRUCT query).
	BOOL selectStar;	
    
    // Dictionary containing the prefixes defined by the
    // parsed query. Each prefix is a key in the dictionary
    // and prefix's resource is the corresponding value.
	NSMutableDictionary *prefixes; 
    
    // Dictionary containing all the variables and blank nodes
    // included in the whole query. The keys of the dictionary
    // contain the variables' names and the values the
    // corresponding variables' ids in the database.
	NSMutableDictionary *variables;
    
    // The txl_query_pattern ids for the patterns in which
    // the compiler is currently found.
	NSMutableArray *patternIds;
	
	NSError *compilerError;
}

@property (assign) kTXLQueryPart partOfQuery;
@property (assign) NSUInteger queryId;
@property (assign) BOOL selectStar;
@property (retain) NSMutableDictionary *prefixes;
@property (retain) NSMutableDictionary *variables;
@property (retain) NSMutableArray *patternIds;
@property (retain) NSError *compilerError;

#pragma mark -
#pragma mark Compile SPARQL Expression

/*
    This method compiles a SPARQL expression and creates the
    corresponding tables. The result is a handle to these tables.
 
    If an error occurs the method returns nil and the error is stored in the error input variable.
 */
+ (TXLQuery *)compileQueryWithExpression:(NSString *)expression
                              parameters:(NSDictionary *)parameters
                                 options:(NSDictionary *)options
                                   error:(NSError **)error;

- (int)yyinputToBuffer:(char *)theBuffer
              withSize:(int)maxSize;

@end

/*
 ** forward declaration of lexer/parser functions 
 ** so the compiler does not complain about warnings
 */
int		sparql_lex_init(void **);
int		sparql_lex_destroy(void *);
void	sparql_set_extra(TXLSPARQLCompiler *, void *);
int		sparql_parse(TXLSPARQLCompiler *, void *);
int     sparql_YYINPUT(char* theBuffer, int maxSize, TXLSPARQLCompiler *compiler);
void 	sparql_error(TXLSPARQLCompiler *, void *, const char* s);

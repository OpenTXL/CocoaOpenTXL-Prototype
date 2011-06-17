//
//  SpatialSituationCompiler.h
//  OpenTXL
//
//  Created by Eleni Tsigka on 08.02.11.
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


extern NSString * const TXLSpatialSituationImporterErrorDomain;

#define SPATIAL_SITUATION_COMPILER_ERROR_SYNTAX_ERROR 1
#define SPATIAL_SITUATION_COMPILER_ERROR_MEMORY_EXHAUSTION 2
#define SPATIAL_SITUATION_COMPILER_ERROR_MISSING_INFO 3

@class TXLStatement;
@class TXLMovingObject;
@class TXLContext;

@interface TXLSpatialSituationImporter : NSObject {

@private
	// Variables to store the output 
	NSMutableArray *statementList;
	TXLContext *context;
	TXLMovingObject *mo;
	
	// Help variables	
	NSMutableArray *snapshots;
	// Dictionary containing the prefixes defined by the
    // parsed query. Each prefix is a key in the dictionary
    // and prefix's resource is the corresponding value.
	NSMutableDictionary *prefixes; 
	
	//NSMutableDictionary *keywords; 
	//NSMutableDictionary *quickVariables; 

	NSError *compilerError;
	
	void *yyscanner;    // state of the lexer 
	NSData *buf; 		// buffer we read from 
	NSInteger pos; 		// current position in buf 
	NSUInteger length;	// length of buf 
}

@property (retain) NSMutableArray *statementList;
@property (retain) TXLContext *context;
@property (retain) TXLMovingObject *mo;

@property (retain) NSMutableArray *snapshots;
@property (retain) NSMutableDictionary *prefixes; 
@property (retain) NSError *compilerError;

//@property (retain) NSMutableDictionary *keywords; 
//@property (retain) NSMutableDictionary *quickVariables; 

#pragma mark -
#pragma mark Compile Spatial Situation Expression

/*
    This method compiles a Spatial Situation expression 
 
    If an error occurs the method returns nil and the error is stored in the error input variable.
    If the method completes successfully a NSDictionary is returned.
 	The key-value pairs of this NSDictionary are the following:
 		* KEY:"statement_list" VALUE:NSMutableArray object 
		  Contains the initialized TXLStatement objects. These objects are not yet stored in the database. 
  		* KEY:"moving_object" VALUE:TXLMovingObject object 
 		  Contains the initialized TXLMovingObject object. This object is not yet stored in the database. 
		* KEY:"context" VALUE:TXLContext object 
 		  Contains the TXLContext object. This object is already stored in the database. 
 */
+ (NSDictionary *)compileSpatialSituationWithExpression:(NSString *)expression
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
int		spatialsituation_lex_init(void **);
int		spatialsituation_lex_destroy(void *);
void	spatialsituation_set_extra(TXLSpatialSituationImporter *, void *);
int		spatialsituation_parse(TXLSpatialSituationImporter *, void *);
int     spatialsituation_YYINPUT(char* theBuffer, int maxSize, TXLSpatialSituationImporter *compiler);
void 	spatialsituation_error(TXLSpatialSituationImporter *, void *, const char* s);

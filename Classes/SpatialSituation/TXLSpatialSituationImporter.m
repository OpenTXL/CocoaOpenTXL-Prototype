//
//  SpatialSituationCompiler.m
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

#import "TXLSpatialSituationImporter.h"
#import "TXLContext.h"
#import "TXLMovingObject.h"
#import "TXLTerm.h"
#import "TXLStatement.h"
#import "TXLDatabase.h"
#import "TXLManager.h"

NSString * const TXLSpatialSituationImporterErrorDomain = @"org.opentxl.SpatialSituationCompilerErrorDomain";

int spatialsituation_YYINPUT(char* theBuffer, int maxSize, TXLSpatialSituationImporter *compiler) {
	return [compiler yyinputToBuffer:theBuffer
                            withSize:maxSize];
}


@interface TXLSpatialSituationImporter ()

@property (assign) void *yyscanner;
@property (retain) NSData *buf;
@property (assign) NSInteger pos;
@property (assign) NSUInteger length;

@end


@implementation TXLSpatialSituationImporter

@synthesize statementList, context, mo, snapshots, prefixes, compilerError;
@synthesize yyscanner, buf, pos, length;

#pragma mark -
#pragma mark Memory Management

- (id)init {
    if ((self = [super init])) {
        
        // TODO: Handle Errors
        spatialsituation_lex_init(&yyscanner);
        
		self.statementList = [NSMutableArray array];
	    self.prefixes = [NSMutableDictionary dictionary];
        self.snapshots = [NSMutableArray array];
        
        spatialsituation_set_extra(self, yyscanner);
    }
    return self;
}

- (void)dealloc {
	[buf release];
	[prefixes release];
	[snapshots release];
	[context release];
	[statementList release];
	[mo release];
	[compilerError release];
    
    spatialsituation_lex_destroy(yyscanner);
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
#pragma mark Compile Spatial Situation Expression

+ (NSDictionary *)compileSpatialSituationWithExpression:(NSString *)expression
								   parameters:(NSDictionary *)parameters
									  options:(NSDictionary *)options
										error:(NSError **)error {
    
	// The compiler should be reentrant. 
	// Therefore the FLEX scanner and the BISON parser are used in reentrant mode and
	// a new instance of the SpatialSituationCompiler class is used. That happens because the scanner and parser
	// use properties of this class. 
    TXLSpatialSituationImporter *compiler = [[[TXLSpatialSituationImporter alloc] init] autorelease];
    
    if (compiler == nil) {
        return nil;
    }
	
	// ----------------------------------------
	
	// Start the parsing of the spatial situation. 
	// The FLEX scanner and the BISON parser are used to parse the spatial situation.	
	// The spatial situation is parsed sequentially. 
	
	compiler.buf = [expression dataUsingEncoding:NSUTF8StringEncoding];
	compiler.length = [compiler.buf length];
	compiler.pos = 0;
	
	// The value returned by spatialsituation_parse is 0 if parsing was successful (return is due to end-of-input).
	// The value is 1 if parsing failed because of invalid input, i.e., input that contains a syntax error or that causes YYABORT to be invoked.
	// The value is 2 if parsing failed due to memory exhaustion. 
	int parsingResult = spatialsituation_parse(compiler, compiler.yyscanner);
	
	if(parsingResult == 0) {
		
		if(compiler.context && compiler.statementList && compiler.statementList ){
			
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:compiler.statementList, @"statement_list",
								  											compiler.mo, @"moving_object",
								  											compiler.context, @"context",
								  											nil];
			return dict;	
			
		} else {
			NSDictionary *error_dict = [NSDictionary dictionaryWithObject:NSLocalizedString(@"There was no context defined in the spatial situation expression!", nil) 
																   forKey:NSLocalizedDescriptionKey];
			if (error != nil) {
				*error = [NSError errorWithDomain:TXLSpatialSituationImporterErrorDomain
											 code:SPATIAL_SITUATION_COMPILER_ERROR_MISSING_INFO
										 userInfo:error_dict];
			}
			return nil;
		}

	} else if (parsingResult == 1) {
        
		// raise syntax error
		if(compiler.compilerError == nil){
			NSDictionary *error_dict = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Spatial situation parsing failed because of invalid input, i.e., input that contains a syntax error or that causes YYABORT to be invoked.", nil) 
																   forKey:NSLocalizedDescriptionKey];
			if (error != nil) {
				*error = [NSError errorWithDomain:TXLSpatialSituationImporterErrorDomain
											 code:SPATIAL_SITUATION_COMPILER_ERROR_SYNTAX_ERROR
										 userInfo:error_dict];
			}
		} else {
			if (error != nil) {
	             *error = compiler.compilerError;
			}
		}
		return nil;		
	
	} else if (parsingResult == 2) {
        
		// raise memory error
		if(compiler.compilerError == nil){
			NSDictionary *error_dict = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Spatial situation parsing failed due to memory exhaustion.", nil) 
																   forKey:NSLocalizedDescriptionKey];
            if (error != nil) {
				*error = [NSError errorWithDomain:TXLSpatialSituationImporterErrorDomain
											 code:SPATIAL_SITUATION_COMPILER_ERROR_MEMORY_EXHAUSTION
										 userInfo:error_dict];
			}
        } else {
			if(error != nil){
				*error = compiler.compilerError;
			}
		}		
		return nil;		
		
	} else {
		return nil;
	}
}


@end

//
//  TXLManager+Importer.m
//  OpenTXL-MacOSX
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

#import "TXLManager+Importer.h"

#import "TXLManager.h"
#import "TXLRevision.h"
#import "TXLContext.h"
#import "TXLMovingObject.h"
#import "TXLMovingObjectSequence.h"
#import "TXLSpatialSituationImporter.h"
#import "TXLManagerImportOperation.h"
#import "TXLManagerUpdateOperation.h"
#import "TXLSituation.h"


@implementation TXLManager (Importer)

#pragma mark -
#pragma mark Import Spatial Situation

- (BOOL)importSpatialSituationFromFileAtPath:(NSString *)path
                              inIntervalFrom:(NSDate *)from
                                          to:(NSDate *)to
                                       error:(NSError **)error
                             completionBlock:(void(^)(TXLRevision *, NSError *))block {
    
    TXLManagerImportOperation *op = [TXLManagerImportOperation operationWithPath:path
                                                                    intervalFrom:from
                                                                              to:to];
    
    [[TXLManager sharedManager] applyOperations:[NSArray arrayWithObject:op]
                            withCompletionBlock:block];
    return YES;
}

- (BOOL)importSpatialSituationFromString:(NSString *)string
                          inIntervalFrom:(NSDate *)from
                                      to:(NSDate *)to
                                   error:(NSError **)error
                         completionBlock:(void(^)(TXLRevision *, NSError *))block{
	
	NSDictionary *result = [TXLSpatialSituationImporter compileSpatialSituationWithExpression:string 
																				parameters:nil
																				   options:nil
																					 error:error]; 
	if(result){
		
		TXLContext *context = [result objectForKey:@"context"];
		TXLMovingObject *mo = [result objectForKey:@"moving_object"];
		NSArray *statements = [result objectForKey:@"statement_list"];
		
		// If there are no statements this is a clear operation.
		if([statements count] == 0) statements = nil;
		
		// Call the update function of the context.
		[context updateWithStatements:statements
						 movingObject:mo
					   inIntervalFrom:from
								   to:to
					  completionBlock:block];
		
		return YES;
		
	} else {
		NSLog(@"%@",[*error localizedDescription]);
		return NO;
	}
}

@end

//
//  TXLManager+Importer.h
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

#import "TXLManager.h"

@class TXLRevision;

@interface TXLManager (Importer)

#pragma mark -
#pragma mark Import Spatial Situation

/*!
 * Import Spatial Situation from file
 * 
 * This method reads the spatial situation from a file, compiles it with the Spatial Situation compiler
 * and then calls the update method of the TXLContext contained in the document for the for the compiled TXLStatements.
 * 
 * If an error occurs the method returns NO and the error is stored in the error input variable.
 * If the method completes successfully YES is returned.
 */
- (BOOL)importSpatialSituationFromFileAtPath:(NSString *)path
                              inIntervalFrom:(NSDate *)from
                                          to:(NSDate *)to
                                       error:(NSError **)error
                             completionBlock:(void(^)(TXLRevision *, NSError *))block __attribute__ ((deprecated));

/*!
 * Import Spatial Situation from string
 * 
 * This method reads the spatial situation from a string, compiles it with the Spatial Situation compiler
 * and then calls the update method of the TXLContext contained in the document for the for the compiled TXLStatements.
 * 
 * If an error occurs the method returns NO and the error is stored in the error input variable.
 * If the method completes successfully YES is returned.
 */
- (BOOL)importSpatialSituationFromString:(NSString *)string
                          inIntervalFrom:(NSDate *)from
                                      to:(NSDate *)to
                                   error:(NSError **)error
                         completionBlock:(void(^)(TXLRevision *, NSError *))block __attribute__ ((deprecated));

@end

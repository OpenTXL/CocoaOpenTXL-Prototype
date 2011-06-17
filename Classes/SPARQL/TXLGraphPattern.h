//
//  TXLGraphPattern.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 12.12.10.
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

@class TXLMovingObject;
@class TXLMovingObjectSequence;
@class TXLRevision;


@interface TXLGraphPattern : NSObject {
    
@private
    NSUInteger primaryKey; 
}

#pragma mark -
#pragma mark Evaluation


/*! Evaluate the pattern with the given environment.
 *
 *  A call of this method evaluate the pattern and calls the
 *  result handler for each match of the pattern with the information
 *  in the database.
 *
 *  vars - A dictionary with bound variables. The key is the
 *         primary key of the variable (as an TXLInteger), the value
 *         is the primary key of the term (as an TXLInteger).
 *
 *  ctxs - A list of TXLContext objects, which should be considered
 *         during the evaluation.
 *
 *  mos - A TXLMovingObjectSequence as a window restricting the temporal and
 *        spatial aspect of the evaluation. Only triple in the contexts
 *        which are valid in this moving object sequence can be used in the evaluation.
 *
 *  rev - The revision which should be used for the evaluation.
 *
 *  handler - The result handler is called for each match of the pattern.
 *  
 *  If the pattern in found at least once in the contexts, the method
 *  returns YES, otherwise NO.
 */

- (BOOL)evaluatePatternWithVariables:(NSDictionary *)vars
                          inContexts:(NSArray *)ctxs
                              window:(TXLMovingObjectSequence *)mos
                         forRevision:(TXLRevision *)rev
                       resultHandler:(void(^)(NSDictionary *vars, TXLMovingObjectSequence *mos))handler;

#pragma mark -
#pragma mark Database Management

+ (id)graphPatternWithPrimaryKey:(NSUInteger)pk;

@property (readonly) NSUInteger primaryKey; 


@end

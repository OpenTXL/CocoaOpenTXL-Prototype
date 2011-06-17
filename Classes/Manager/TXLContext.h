//
//  TXLContext.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 18.09.10.
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

@class TXLRevision;
@class TXLMovingObject;

@interface TXLContext : NSObject {

@protected
    NSUInteger primaryKey;
    NSString *name;
}

#pragma mark -
#pragma mark Name

@property (readonly) NSString *name;

#pragma mark -
#pragma mark Accessing the Context Hierarchy

- (NSSet *)subcontextsMatchingPattern:(NSString *)pattern;

- (BOOL)isDescendantOf:(TXLContext *)ctx;
- (BOOL)isAntecendentOf:(TXLContext *)ctx;

- (TXLContext *)childWithName:(NSString *)name;

#pragma mark -
#pragma mark Update Context

/*! Update context without temporal and spatial restrictions.
 *
 *  This methods updates the gioven context without a temporal
 *  or spatial restriction. If this operation completes, the given
 *  list of staements is valid in this context.
 *
 *  The context can only be updated, if it is bound to this manager.
 */
- (void)updateWithStatements:(NSArray *)statements
             completionBlock:(void(^)(TXLRevision *, NSError *))completionBlock;

/*! Update context.
 *
 *  This method updates the context in the interval indicated by the
 *  parameters inIntervalFrom and to with the list of statements, which
 *  are valid in the given moving object.
 *
 *  If this operation completes, the context is cleared in the given
 *  interval and the list of statement is valid in the given moving object
 *  which is restricted by the interval.
 *
 *  The context can only be updated, if it is bound to this manager.
 */
- (void)updateWithStatements:(NSArray *)statements
                movingObject:(TXLMovingObject *)mo
              inIntervalFrom:(NSDate *)from
                          to:(NSDate *)to
             completionBlock:(void(^)(TXLRevision *, NSError *))completionBlock;

#pragma mark -
#pragma mark Clear Context

/*! Clear context without temporal restriction
 *
 *  This method clears the given context without a temporal restriction.
 *  If the operation completes, no statements are valid in the context.
 *
 *  The context can only be updated, if it is bound to this manager.
 */
- (void)clear:(void(^)(TXLRevision *, NSError *))completionBlock;

/*! Clear context
 *
 *  This method clears the context in the given interval. If the
 *  operation completes, the context contains no valid statement in
 *  the given interval.
 *
 *  The context can only be updated, if it is bound to this manager.
 */
- (void)clearInIntervalFrom:(NSDate *)from
                         to:(NSDate *)to
            completionBlock:(void(^)(TXLRevision *, NSError *))completionBlock;

#pragma mark -
#pragma mark Situation Definition

/*! Set a Situation Definition
 *
 *  This method sets a SPARQL CONSTRUCT query as a situation definition
 *  for this context. This context is then populated with the resulting
 *  situations of that expression.
 *
 *  The results will be stored in sub contexts starting with the
 *  character '#'.
 */
- (BOOL)setSituationDefinition:(NSString *)expression
                   withOptions:(NSDictionary *)options
                         error:(NSError **)error;

/*! Remove a Situation Definition
 *
 *  This method removes a situation definition for this context. After a call
 *  of this method, this context will no longer be populated with results
 *  of the evaluation of the SPARQL query.
 *
 *  After the situation definition has been removed. All sub contexts (starting
 *  with the character '#'), which where created by this definition will be cleared.
 */
- (void)removeSituationDefinition;

/*! Situation Definition
 *
 *  This property contains the current situation definition or nil if no
 *  definition is set.
 */
@property (readonly) NSString *situationDefinition;

#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Autorelease Constructors

+ (id)contextWithPrimaryKey:(NSUInteger)pk;

+ (id)contextWithName:(NSString *)n;

#pragma mark -
#pragma mark Database Management

@property (readonly) NSUInteger primaryKey;

@end

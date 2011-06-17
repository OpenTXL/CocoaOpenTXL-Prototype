//
//  TXLManager.h
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
#import <dispatch/dispatch.h>

extern NSString * const TXLManagerErrorDomain;

#define TXL_MANAGER_ERROR_NOT_IMPLEMENTED 1
#define TXL_MANAGER_ERROR_LOCAL_BINDING 2
#define TXL_MANAGER_ERROR_REMOTE_BINDING 3
#define TXL_MANAGER_ERROR_EXISTS 4
#define TXL_MANAGER_ERROR_NOT_EXISTS 5

@class TXLManager;
@class TXLRevision;
@class TXLContext;
@class TXLMovingObject;
@class TXLQueryHandle;
@class TXLDatabase;


#pragma mark -
#pragma mark -
#pragma mark Manager

@interface TXLManager : NSObject {
    
@private
    id delegate;
    
    TXLDatabase *database;
    
    BOOL processing;
    int processing_counter;
    dispatch_queue_t manager_queue;
    dispatch_group_t manager_group;
}

#pragma mark -
#pragma mark Shared Manager

+ (TXLManager *)sharedManager;

#pragma mark -
#pragma mark Delegate

@property (assign) id delegate;

#pragma mark -
#pragma mark Processing

/*! Boolean flag indicating if the manager is processing
 *  information (either updating contexts or evaluating
 *  queries).
 */
@property (readonly, getter=isProcessing) BOOL processing;

#pragma mark -
#pragma mark -
#pragma mark Accessing Contexts

/*! Handle for Context.
 *
 *  This method retuns a handle for a context with the given
 *  options. A context consits of a root context defined via
 *  the protocol and host and a path defined by ist path components.
 *  <proto>://<host>/{path components}
 *
 *  A Path component must not start with the character '#'. Contexts
 *  starting with this character are reserverd for internal use.
 */
- (TXLContext *)contextForProtocol:(NSString *)proto
                              host:(NSString *)host
                              path:(NSArray *)path
                             error:(NSError **)error;

#pragma mark -
#pragma mark Bound Contexts

@property (readonly) NSArray *boundContexts;

#pragma mark -
#pragma mark -
#pragma mark Continuous Query

- (TXLQueryHandle *)registerQueryWithName:(NSString *)name
                               expression:(NSString *)expression
                               parameters:(NSDictionary *)parameters
                                  options:(NSDictionary *)options
                                    error:(NSError **)error;

- (void)unregisterQueryWithName:(NSString *)name;

- (TXLQueryHandle *)queryWithName:(NSString *)name
                            error:(NSError **)error;

@property (readonly) NSArray *registeredQueryNames;

#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Database Management

@property (readonly) TXLDatabase *database;

#pragma mark -
#pragma mark -
#pragma mark Update Context

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
- (void)updateContext:(TXLContext *)ctx
       withStatements:(NSArray *)statements
         movingObject:(TXLMovingObject *)mo
       inIntervalFrom:(NSDate *)from
                   to:(NSDate *)to
      completionBlock:(void(^)(TXLRevision *, NSError *))block;

- (void)applyOperations:(NSArray *)operations
    withCompletionBlock:(void(^)(TXLRevision *, NSError *))block;

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
                    forContext:(TXLContext *)ctx
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
- (void)removeSituationDefinitionFromContext:(TXLContext *)ctx;

/*! Situation Definition
 *
 *  This property contains the current situation definition or nil if no
 *  definition is set.
 */
- (NSString *)situationDefinitionForContext:(TXLContext *)ctx;

@end

#import "TXLManager+Revision.h"
#import "TXLManager+Importer.h"


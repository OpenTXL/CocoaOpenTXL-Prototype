//
//  TXLManager.m
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

#import "TXLManager.h"
#import "TXLRevision.h"
#import "TXLContext.h"

#import "TXLPropertiesReader.h"
#import "TXLDatabase.h"
#import "TXLInteger.h"

#import "TXLStatement.h"
#import "TXLTerm.h"
#import "TXLMovingObject.h"
#import "TXLMovingObjectSequence.h"
#import "TXLSituation.h"

#import "TXLManagerUpdateOperation.h"
#import "TXLManagerImportOperation.h"
#import "TXLSpatialSituationImporter.h"

#import "TXLSPARQLCompiler.h"
#import "TXLQuery.h"
#import "TXLQueryHandle.h"
#import "TXLResultSet.h"
#import "TXLGraphPattern.h"

#import "TXLManagerDelegateProtocol.h"
#import <spatialite/sqlite3.h>

#import <TargetConditionals.h>

#define SQL_ON_ERROR_RETURN(stmt) {if ([self.database executeSQL:stmt error:error] == nil) {return NO;}}
#define SQL_ON_ERROR_IGNORE(stmt) {NSError *error; [self.database executeSQL:stmt error:&error];}

NSString * const TXLManagerErrorDomain = @"org.opentxl.TXLManagerErrorDomain";

static TXLManager *sharedTXLManager = nil;

#pragma mark -
#pragma mark -

@interface TXLManager ()

#pragma mark -
#pragma mark Setup Database Tables

- (BOOL)setupDatabaseForTXLRevision:(NSError **)error;
- (BOOL)setupDatabaseForTXLContext:(NSError **)error;
- (BOOL)setupDatabaseForTXLMovingObject:(NSError **)error;
- (BOOL)setupDatabaseForTXLMovingObjectSequence:(NSError **)error;
- (BOOL)setupDatabaseForTXLTerm:(NSError **)error;
- (BOOL)setupDatabaseForTXLQuery:(NSError **)error;
- (BOOL)setupDatabaseForSituations:(NSError **)error;
- (BOOL)setupDatabase:(NSError **)error;

#pragma mark -
#pragma mark Processing

- (void)increaseProcessingCounter;
- (void)decreaseProcessingCounter;

#pragma mark -
#pragma mark Evaluate Queries

- (void)evaluateQuery:(TXLQuery *)query
           atRevision:(TXLRevision *)rev;

- (void)evaluateQueriesForContexts:(NSSet *)ctxs
                        atRevision:(TXLRevision *)rev;

- (void)evaluateQueriesForContext:(TXLContext *)ctx
                       atRevision:(TXLRevision *)rev;


#pragma mark -
#pragma mark Updating Context

- (void)forMovingObjectsInContext:(TXLContext *)ctx
                   inIntervalFrom:(NSDate *)from
                               to:(NSDate *)to
                       applyBlock:(void(^)(TXLMovingObject *mo))block;

- (void)forMovingObjectsInContext:(TXLContext *)ctx 
         intersectingIntervalFrom:(NSDate *)from 
                               to:(NSDate *)to
                       applyBlock:(void(^)(TXLMovingObject *mo))block;

- (void)forStatementsUsingMovingObject:(TXLMovingObject *)mo
                             inContext:(TXLContext *)ctx
                            applyBlock:(void(^)(TXLInteger *pk, TXLTerm *subject, TXLTerm *predicate, TXLTerm *object))block;

- (BOOL)statement:(TXLStatement *)stmnt
 withMovingObject:(TXLMovingObject *)mo
   isInStatements:(NSArray *)stmnts
withMovingObjects:(TXLMovingObjectSequence *)mos;

- (BOOL)statement:(TXLStatement *)stmnt1
 WithMovingObject:(TXLMovingObject *)mo1 
isEqualToStatement:(TXLStatement *)stmnt2
 withMovingObject:(TXLMovingObject *)mo2;	

- (TXLInteger *)setSubject:(TXLTerm *)subject
                 predicate:(TXLTerm *)predicate
                    object:(TXLTerm *)object
                 inContext:(TXLContext *)ctx
           forMovingObject:(TXLMovingObject *)mo;

@end

#pragma mark -
#pragma mark -

@implementation TXLManager

@synthesize delegate;
@synthesize database;
@synthesize processing;

#pragma mark -
#pragma mark Shared Manager

+ (id)sharedManager {
    @synchronized(self) {
        if (sharedTXLManager == nil) {
            [[TXLManager new] autorelease];
        }
    }
    return sharedTXLManager;
}


#pragma mark -
#pragma mark Sigleton Stuff

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedTXLManager == nil) {
            sharedTXLManager = [super allocWithZone:zone];
            return sharedTXLManager;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

#pragma mark -
#pragma mark Memory Management

- (id)init {
    if ((self = [super init])) {
        
        NSString *databasePath = nil;
        
#if TARGET_OS_IPHONE
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *tempDocumentsDirectory = [paths objectAtIndex:0];
        databasePath = [tempDocumentsDirectory stringByAppendingPathComponent:@"OpenTXL.db"];
#else
        databasePath = [TXLPropertiesReader propertyForKey:TXL_DATABASE_FILE_NAME_PROPERTY];
        if (databasePath == nil) {
            databasePath = @"/tmp/OpenTXL.db";
        }
#endif
        
        database = [[TXLDatabase alloc] initWithPath:databasePath];
        
        NSError *error;
        if ([self setupDatabase:&error] == NO) {
            NSLog(@"[TXLManager] Clould not setup database: %@", [error localizedDescription]);
            [database release];
            [[NSException exceptionWithName:@"TXLManagherException"
                                     reason:[error localizedDescription]
                                   userInfo:nil] raise];
        };
        
        manager_queue = dispatch_queue_create("org.opentxl.manager", NULL);
        manager_group = dispatch_group_create();
    }
    return self;
}

- (void)dealloc {
    dispatch_group_wait(manager_group, DISPATCH_TIME_FOREVER);
    dispatch_release(manager_queue);
    dispatch_release(manager_group);
    [database release];
    [super dealloc];
}



#pragma mark -
#pragma mark Accessing Contexts

- (TXLContext *)contextForProtocol:(NSString *)proto
                              host:(NSString *)host
                              path:(NSArray *)path
                             error:(NSError **)_error {
    
    NSError *error;
    
    NSUInteger pk = 0;
    
    
    NSMutableArray *components = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%@://%@", proto, host]];
    [components addObjectsFromArray:path];
    NSString *fullPath = [components componentsJoinedByString:@"/"];
    
    
    if ([self.database executeSQLWithParameters:@"INSERT INTO txl_context (name) VALUES(?)" error:&error,
         fullPath,
         nil] == nil) {
        if ([[error domain] isEqual:SQLiteErrorDomain]) {
            switch ([error code]) {
                case SQLITE_CONSTRAINT:
                {
                    NSArray *result = [database executeSQLWithParameters:@"SELECT id FROM txl_context WHERE name = ?"
                                                                   error:&error,
                                       fullPath,
                                       nil];
                    if (result == nil) {
                        if (_error != nil) {
                            *_error = error;
                        }
                        return nil;
                    } else {
                        pk = [[[result objectAtIndex:0] objectForKey:@"id"] integerValue];
                    }
                    break;
                }
                    
                default:
                    if (_error != nil) {
                        *_error = error;
                    }
                    return nil;
                    break;
            }
        } else {
            if (_error != nil) {
                *_error = error;
            }
            return nil;
        }
    } else {
        pk = database.lastInsertRowid;
    }
    
    return [TXLContext contextWithPrimaryKey:pk];
}

#pragma mark -
#pragma mark Bound Contexts

- (NSArray *)boundContexts {
    return nil;
}

#pragma mark -
#pragma mark Continuous Query

- (TXLQueryHandle *)registerQueryWithName:(NSString *)name
                               expression:(NSString *)expression
                               parameters:(NSDictionary *)parameters
                                  options:(NSDictionary *)options
                                    error:(NSError **)error {
    
    // Check if the name is not used and "acquire" it
    // --------------------------------------------------------------
    
    if (![self.database executeSQL:@"INSERT INTO txl_query_name (name) VALUES (?)"
                    withParameters:[NSArray arrayWithObject:name]
                             error:error
                     resultHandler:^(NSDictionary *row, BOOL *stop){}]) {
        
        if ([[*error domain] isEqual:SQLiteErrorDomain]) {
            switch ([*error code]) {
                case SQLITE_CONSTRAINT:
                {
                    if (error != nil) {
                        NSDictionary *error_dict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Query with name %@ already exists.", nil), name]
                                                                               forKey:NSLocalizedDescriptionKey];
                        
                        *error = [NSError errorWithDomain:TXLManagerErrorDomain
                                                     code:TXL_MANAGER_ERROR_EXISTS
                                                 userInfo:error_dict];
                    }
                    return nil;
                }
                    
                    
                default:
                    return nil;
            }
        } else {
            return nil;
        }
    }
    
    
    // Compile the query
    // --------------------------------------------------------------
    
    TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:expression
                                                         parameters:parameters
                                                            options:options
                                                              error:error];
    
    // TODO: check if the query is a SPARQL ASK or SELECT expression
    
    if (query == nil) {
        // compiling the query faild
        return nil;
    }
    
    
    // Save the compiled query with the given name
    // --------------------------------------------------------------
    
    if (![self.database executeSQL:@"INSERT OR REPLACE INTO txl_query_name (name, query_id) VALUES (?, ?)"
                    withParameters:[NSArray arrayWithObjects:name, [TXLInteger integerWithValue:query.primaryKey], nil]
                             error:error
                     resultHandler:^(NSDictionary *row, BOOL *stop){}]) {
        return nil;
    }
    
    
    // Trigger first evaluation for this query
    // --------------------------------------------------------------
    
    // Trigger first evaluation of the query, only if there is some content in the database. 
    TXLRevision *head = [self headRevision];
    if (head != nil) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self evaluateQuery:query
                     atRevision:head];
        }); 
    }
    
    
    // Register and return handle for this query
    // --------------------------------------------------------------
    
    TXLQueryHandle *qh = [TXLQueryHandle handleForQueryWithPrimaryKey:query.primaryKey];
    
    return qh;
}

- (void)unregisterQueryWithName:(NSString *)name {
    
    // Remove this query from the database as well as all
    // corresponding tables.
    
    // defer this operation until all handles for this query
    // (TXLQueryHandle) are released.
    
    NSError *error;
    
    [self.database executeSQL:@"DELETE FROM txl_query_name WHERE name = ?"
               withParameters:[NSArray arrayWithObject:name]
                        error:&error
                resultHandler:^(NSDictionary *row, BOOL *stop){}];
}

- (TXLQueryHandle *)queryWithName:(NSString *)name
                            error:(NSError **)error {
    
    // Create a handle (TXLQueryHandle) for a query with
    // this name and return it to the caller.
    
    // TXLContinuousQuery is not the query itself. It is just a
    // handler for this query.
    
    // Each call of this function leads to a new query handler.
    // Therefore, multiple query handlers could exist for the same query.
    
    __block NSUInteger pk = 0;
    
    BOOL success = [self.database executeSQL:@"SELECT query_id FROM txl_query_name WHERE name = ?"
                              withParameters:[NSArray arrayWithObject:name]
                                       error:error
                               resultHandler:^(NSDictionary *row, BOOL *stop){
                                   pk = [[row objectForKey:@"query_id"] integerValue];
                                   *stop = YES;
                               }];
    
    if (success && (pk == 0) && (error != nil)) {
        NSDictionary *error_dict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Query with name %@ does not exist.", nil), name]
                                                               forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:TXLManagerErrorDomain
                                     code:TXL_MANAGER_ERROR_NOT_EXISTS
                                 userInfo:error_dict];
    }
    
    if (pk == 0)
        return nil;
    
    // Register and return handle for this query
    // --------------------------------------------------------------
    
    TXLQueryHandle *qh = [TXLQueryHandle handleForQueryWithPrimaryKey:pk];
    
    return qh;
}

- (NSArray *)registeredQueryNames {
    NSError *error;
    NSMutableArray *result = [NSMutableArray array];
    BOOL success = [self.database executeSQL:@"SELECT name FROM txl_query_name"
                              withParameters:nil
                                       error:&error
                               resultHandler:^(NSDictionary *row, BOOL *stop){
                                   [result addObject:[row objectForKey:@"name"]];
                               }];
    
    if (!success) {
        [[NSException exceptionWithName:@"ManagerException"
                                 reason:[error localizedDescription]
                               userInfo:nil] raise];
    }
    
    return result;
}

#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Update Context

- (void)updateContext:(TXLContext *)ctx
       withStatements:(NSArray *)statements
         movingObject:(TXLMovingObject *)mo
       inIntervalFrom:(NSDate *)from
                   to:(NSDate *)to
      completionBlock:(void(^)(TXLRevision *, NSError *))block {
    
    
    TXLSituation *situation;
    if (mo) {
        situation = [TXLSituation situationWithStatements:statements
                                     movingObjectSequence:[TXLMovingObjectSequence sequenceWithMovingObject:mo]];
    } else {
        situation = [TXLSituation situationWithStatements:statements
                                     movingObjectSequence:[TXLMovingObjectSequence sequenceWithMovingObject:[TXLMovingObject omnipresentMovingObject]]];
    }
    
    
    TXLManagerUpdateOperation *op = [TXLManagerUpdateOperation operationForContext:ctx
                                                                     withSituation:situation
                                                                    inIntervalFrom:from
                                                                                to:to];
    
    [self applyOperations:[NSArray arrayWithObject:op] withCompletionBlock:block];
    
}

- (void)applyOperations:(NSArray *)operations
    withCompletionBlock:(void(^)(TXLRevision *, NSError *))block {
    // Dispatch the operation to update the context on the
    // global concurrent queue.
    //NSLog(@"Scheduling update for context: %@", ctx);
    
    // ------------------------------------------------
    // Notify the delegate that the processing starts
    
    [self increaseProcessingCounter];
    
    dispatch_group_async(manager_group, manager_queue, ^{
        
        NSError *error = nil;
        TXLRevision *revision = nil;
        
        NSMutableSet *createdStatements = [NSMutableSet set];
        NSMutableSet *removedStatements = [NSMutableSet set];
        NSMutableSet *updatedContexts = [NSMutableSet set];
        
        for (id _op in operations) {
            
            TXLManagerUpdateOperation *op = nil;
            
            if ([_op isKindOfClass:[TXLManagerUpdateOperation class]]) {
                op = _op;
            } else if ([_op isKindOfClass:[TXLManagerImportOperation class]]) {
                
                TXLManagerImportOperation *iop = _op;
                
                NSString *expression = [NSString stringWithContentsOfFile:iop.path 
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:&error];
                if (expression == nil) {
                    block(revision, error);
                    [self decreaseProcessingCounter];
                    return;
                }
                
                NSDictionary *result = [TXLSpatialSituationImporter compileSpatialSituationWithExpression:expression 
                                                                                               parameters:nil
                                                                                                  options:nil
                                                                                                    error:&error];
                
                if (result == nil) {
                    block(revision, error);
                    [self decreaseProcessingCounter];
                    return;
                } else {

                    TXLContext *context = [result objectForKey:@"context"];
                    TXLMovingObject *mo = [result objectForKey:@"moving_object"];
                    NSArray *statements = [result objectForKey:@"statement_list"];
                    
                    TXLSituation *situation = [[TXLSituation alloc] initWithStatements:statements movingObjectSequence:[TXLMovingObjectSequence sequenceWithMovingObject:mo]];
                    
                    op = [[TXLManagerUpdateOperation alloc] initWithContext:context
                                                                  situation:situation
                                                               intervalFrom:iop.from
                                                                         to:iop.to];
                    [op autorelease];
                    [situation release];
                    
                }
            }
            
            NSAutoreleasePool *pool = [NSAutoreleasePool new];
            
            NSMutableSet *_createdStatements = [NSMutableSet set];
            NSMutableSet *_removedStatements = [NSMutableSet set];
            
            // Check preconditions
            // ----------------------------------------
            
            // TODO: Replase assert with a better error handling (return an NSError).
            
            assert(op.context != nil);
            
            for (TXLStatement *st in op.situation.statements) {
                assert(st.subject != nil);
                assert(st.predicate != nil);
                assert(st.object != nil);
            }
            
            // ----------------------------------------
            // ----------------------------------------
            
            
            // Mask moving object with update interval
            // ----------------------------------------
            
            // Restrict the new moving object (mo) by the boundaries
            // of the interval (from, to).
            // (-> mo').
            
            TXLMovingObjectSequence *mos_;
            if (op.situation.mos == nil) {
                
                mos_ = [TXLMovingObjectSequence sequenceWithMovingObject:[TXLMovingObject movingObjectWithBegin:op.from
                                                                                                            end:op.to]];
            } else {
                mos_ = [op.situation.mos movingObjectSequenceInIntervalFrom:op.from
                                                                         to:op.to];
            }
            
            if ([mos_ save:&error] == nil) {
                block(nil, error);
                [pool drain];
                [self decreaseProcessingCounter];
                return;
            };
            
            // ----------------------------------------
            // ----------------------------------------
            
            // At first, all statements of this update
            // operation are considered as to be created.
            // ----------------------------------------
            NSMutableArray *statementsToCreate = [NSMutableArray arrayWithArray:op.situation.statements];
            
            // Find all already existing statements
            // in this context which are in the
            // interval [from, to].
            // ----------------------------------------
            
            [self forMovingObjectsInContext:op.context
                             inIntervalFrom:op.from
                                         to:op.to
                                 applyBlock:^(TXLMovingObject *mo) {
                                     
                                     [self forStatementsUsingMovingObject:mo
                                                                inContext:op.context
                                                               applyBlock:^(TXLInteger *pk, TXLTerm *subject, TXLTerm *predicate, TXLTerm *object) {
                                                                   
                                                                   // Check if the found statement is in the list
                                                                   // of statements of the update operation, 
                                                                   // that will be created.
                                                                   //
                                                                   // If the statement is in the list, then it
                                                                   // should neither be removed nor be created in
                                                                   // this update operation.
                                                                   //
                                                                   // Otherwise the found statement should be removed.
                                                                   // ----------------------------------------
                                                                   
                                                                   TXLStatement *stmnt = [TXLStatement statementWithSubject:subject
                                                                                                                  predicate:predicate
                                                                                                                     object:object];
                                                                   
                                                                   if ([self statement:stmnt
                                                                      withMovingObject:[mo movingObjectInIntervalFrom:op.from
                                                                                                                   to:op.to]
                                                                        isInStatements:op.situation.statements
                                                                     withMovingObjects:mos_]) {
                                                                       
                                                                       [statementsToCreate removeObject:stmnt];
                                                                       
                                                                   } else {
                                                                       
                                                                       [_removedStatements addObject:pk];
                                                                       
                                                                   }
                                                                   
                                                               }];                                      
                                 }];
            
            // Find all already existing statements in this context 
            // which intersect the interval [from, to].
            // These statements potentially have to be updated.
            // ----------------------------------------
            
            [self forMovingObjectsInContext:op.context
                   intersectingIntervalFrom:op.from
                                         to:op.to
                                 applyBlock:^(TXLMovingObject *mo){
                                     
                                     [self forStatementsUsingMovingObject:mo
                                                                inContext:op.context
                                                               applyBlock:^(TXLInteger *pk, TXLTerm *subject, TXLTerm *predicate, TXLTerm *object){
                                                                   
                                                                   // Check if the found statement is 
                                                                   // in the list of statements of the update  
                                                                   // operation, that will be created.
                                                                   //
                                                                   // If the statement is in the list, 
                                                                   // then it should neither be created nor 
                                                                   // be splitted in this update operation.
                                                                   //
                                                                   // Otherwise it should be splitted.
                                                                   // Therefore reinsert the masked statements (the parts of the
                                                                   // statements which are not in the interval [from, to]).
                                                                   // ----------------------------------------
                                                                   
                                                                   TXLStatement *stmnt = [TXLStatement statementWithSubject:subject
                                                                                                                  predicate:predicate
                                                                                                                     object:object];
                                                                   
                                                                   if ([self statement:stmnt
                                                                      withMovingObject:[mo movingObjectInIntervalFrom:op.from
                                                                                                                   to:op.to]
                                                                        isInStatements:op.situation.statements
                                                                     withMovingObjects:mos_]) {
                                                                       
                                                                       [statementsToCreate removeObject:stmnt];
                                                                       
                                                                   } else {
                                                                       
                                                                       [_removedStatements addObject:pk];
                                                                       
                                                                       for (TXLMovingObject *mo_ in [mo movingObjectNotInIntervalFrom:op.from
                                                                                                                                   to:op.to].movingObjects) {
                                                                           
                                                                           [_createdStatements addObject:[self setSubject:subject
                                                                                                                predicate:predicate
                                                                                                                   object:object
                                                                                                                inContext:op.context
                                                                                                          forMovingObject:mo_]];
                                                                           
                                                                       }
                                                                       
                                                                   }
                                                                   
                                                               }];
                                 }];
            
            // Iterate over the moving object sequence
            // and update the context for each moving object
            for (TXLMovingObject *mo in mos_.movingObjects) {
                
                for (TXLStatement *st in statementsToCreate) {
                    [_createdStatements addObject:[self setSubject:st.subject
                                                         predicate:st.predicate
                                                            object:st.object
                                                         inContext:op.context
                                                   forMovingObject:mo]];
                }
            }
            
            if ([_createdStatements count] > 0 ||
                [_removedStatements count] > 0) {
                [updatedContexts addObject:op.context];
            }
            
            [createdStatements unionSet:_createdStatements];
            [removedStatements unionSet:_removedStatements];
            
            // ----------------------------------------
            // ----------------------------------------
            
            [pool drain];
        }
        
        // Create a new transaction and write the changes in
        // to the list of created and removed statements.
        // ----------------------------------------
        
        // Do the actual modification of the contexts state, 
		// if there is a change to apply.
        if(([createdStatements count] > 0) || 
           ([removedStatements count] > 0) ){
            
			// Start a transaction.
			if ([self.database beginTransaction:&error] == NO) {
				block(nil, error);
                [self decreaseProcessingCounter];
				return;
			};
            
            // Create a new revision.
            if ([self.database executeSQL:@"INSERT INTO txl_revision (previous) SELECT revision FROM txl_revision_head WHERE id = 1"
                                    error:&error] == nil) {
                [self.database rollback:&error];
                block(nil, error);
                [self decreaseProcessingCounter];
                return;
            }
            
            TXLInteger *revPk = [TXLInteger integerWithValue:self.database.lastInsertRowid];
            revision = [TXLRevision revisionWithPrimaryKey:revPk.integerValue];
            
            // Mark all statements in the set 'removedStatements' as removed and
            // all statements in the set 'createdStatements' as created for
            // the new revision.
            
            for (TXLInteger *num in removedStatements) {
                if ([self.database executeSQLWithParameters:@"INSERT INTO txl_statement_removed (statement_id, revision_id) VALUES (?, ?)" error:&error,
                     num, revPk, nil] == nil) {
                    [self.database rollback:&error];
                    block(nil, error);
                    [self decreaseProcessingCounter];
                    return;                    
                }
            }
            
            for (TXLInteger *num in createdStatements) {
                if ([self.database executeSQLWithParameters:@"INSERT INTO txl_statement_created (statement_id, revision_id) VALUES (?, ?)" error:&error,
                     num, revPk, nil] == nil) {
                    [self.database rollback:&error];
                    block(nil, error);
                    [self decreaseProcessingCounter];
                    return;
                }
            }
            
			// Commit the transaction.
			if ([self.database commit:&error] == NO) {
				block(nil, error);
                [self decreaseProcessingCounter];
				return;
			};    
            
            
            // ----------------------------------------
			
			// Operations clear and update finalized.
			
			// ----------------------------------------
			
			// Notify the internal function who's responsible
			// for the evaluation of the continuous queries.
			
            //NSLog(@"Updated contexts (rev=%@): %@", revision, updatedContexts);
            
			[self evaluateQueriesForContexts:updatedContexts
								  atRevision:revision];
			
			// Call the delegate method to notify about the change.
			
			if ([self.delegate respondsToSelector:@selector(didChangeContexts:inRevision:)]) {
				[self.delegate didChangeContexts:updatedContexts inRevision:revision];
			}	
            
        } else {
            if(revision == nil){
				revision = [[TXLManager sharedManager] headRevision];
			}
        }
        
        // ----------------------------------------
        // ----------------------------------------
        
        block(revision, error);
        [self decreaseProcessingCounter];
    });
}

#pragma mark -
#pragma mark Situation Definition

- (BOOL)setSituationDefinition:(NSString *)expression
                    forContext:(TXLContext *)ctx
                   withOptions:(NSDictionary *)options
                         error:(NSError **)error {
    
    // Compile the new expression
    // ----------------------------------------------------
    
    TXLQuery *query = [TXLSPARQLCompiler compileQueryWithExpression:expression
                                                         parameters:nil
                                                            options:options
                                                              error:error];
    
    if (query == nil)
        return NO;
    
    // TODO: Check if the compiled query is a SPARQL CONSTRUCT expression
    // ---------------------------------------------------
    
    // Remove a previous set situation definition
    // ----------------------------------------------------
    [self removeSituationDefinitionFromContext:ctx];
    
    // Register the compiled query as a situation definition for this context
    // ----------------------------------------------------
    
    BOOL success = [self.database executeSQL:@"INSERT INTO txl_context_query (context_id, query_id) VALUES (?, ?)"
                              withParameters:[NSArray arrayWithObjects:[TXLInteger integerWithValue:ctx.primaryKey], [TXLInteger integerWithValue:query.primaryKey], nil]
                                       error:error
                               resultHandler:^(NSDictionary *row, BOOL *stop){}];
    if (!success)
        return NO;
    
    
    // Trigger the first evaluation of this query
    // ----------------------------------------------------
    
    TXLRevision *head = [[TXLManager sharedManager] headRevision];
    
    if (head != nil) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self evaluateQuery:query
                     atRevision:head];
        }); 
    }
    
    return YES;
}

- (void)removeSituationDefinitionFromContext:(TXLContext *)context {
    
    // Remove the association for the situation definition of this context
    // ----------------------------------------------------
    
    NSError *error;
    BOOL success = [self.database executeSQL:@"DELETE FROM txl_context_query WHERE context_id = ?"
                              withParameters:[NSArray arrayWithObject:[TXLInteger integerWithValue:context.primaryKey]]
                                       error:&error
                               resultHandler:^(NSDictionary *row, BOOL *stop){}];
    if (!success) {
        [[NSException exceptionWithName:@"TXLContextException"
                                 reason:[error localizedDescription]
                               userInfo:nil] raise];
    }  
    
    // Clear all sub contexts which are created via an evaluation
    // of the current situation definition
    // ----------------------------------------------------
    
    for (TXLContext *ctx in [context subcontextsMatchingPattern:@"#"]) {
        [ctx clear:^(TXLRevision *rev, NSError *error){
            if (rev == nil) {
                [[NSException exceptionWithName:@"TXLContextException"
                                         reason:[error localizedDescription]
                                       userInfo:nil] raise];
            }
        }];        
    }
}

- (NSString *)situationDefinitionForContext:(TXLContext *)ctx {
    
    // Return the current situation definition or nil, if not set.
    // ----------------------------------------------------
    
    __block NSUInteger pk = 0;
    
    NSError *error;
    BOOL success = [self.database executeSQL:@"SELECT query_id FROM txl_context_query WHERE context_id = ?"
                              withParameters:[NSArray arrayWithObject:[TXLInteger integerWithValue:ctx.primaryKey]]
                                       error:&error
                               resultHandler:^(NSDictionary *row, BOOL *stop){
                                   pk = [[row objectForKey:@"query_id"] integerValue];
                                   *stop = YES;
                               }];
    if (!success) {
        [[NSException exceptionWithName:@"TXLContextException"
                                 reason:[error localizedDescription]
                               userInfo:nil] raise];
    }
    
    if (pk == 0)
        return nil;
    
    TXLQuery *query = [TXLQuery queryWithPrimaryKey:pk];
    if (query) {
        return query.expression;
    } else {
        return nil;
    }
}

#pragma mark -
#pragma mark -
#pragma mark Private Methods

#pragma mark -
#pragma mark Setup Database Tables

- (BOOL)setupDatabaseForTXLRevision:(NSError **)error {
    
    NSLog(@"Setup database for TXLRevision.");
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_revision ( \
                        id integer NOT NULL PRIMARY KEY AUTOINCREMENT, \
                        previous integer REFERENCES txl_revision (id), \
                        timestamp NOT NULL DEFAULT ((julianday('now') - 2440587.5)*86400.0) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_revision_timestamp ON txl_revision (timestamp)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_revision_previous ON txl_revision (previous)");
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_revision_head (id integer NOT NULL PRIMARY KEY, revision integer REFERENCES txl_revision (id))");
    SQL_ON_ERROR_RETURN(@"CREATE TRIGGER IF NOT EXISTS txl_revision_after AFTER INSERT ON txl_revision BEGIN UPDATE txl_revision_head SET revision = new.id WHERE id = 1; END");
    
    SQL_ON_ERROR_IGNORE(@"INSERT INTO txl_revision_head (id, revision) VALUES (1, 0)");
    
    return YES;
}

- (BOOL)setupDatabaseForTXLContext:(NSError **)error {
    
    NSLog(@"Setup database for TXLContext.");
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_context ( \
                            id integer NOT NULL PRIMARY KEY, \
                            name NOT NULL UNIQUE)");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_context_name ON txl_context (name)");
    
    // Derived Contexts a.k.a. Situation Definition
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_context_query ( \
                        id INTEGER NOT NULL PRIMARY KEY, \
                        query_id INTEGER NOT NULL REFERENCES txl_query (id), \
                        context_id INTEGER NOT NULL REFERENCES txl_context (id), \
                        UNIQUE(context_id)\
                        )");
    
    return YES;
}

- (BOOL)setupDatabaseForTXLMovingObject:(NSError **)error {
    
    NSLog(@"Setup database for TXLMovingObject.");
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_geometry (id integer NOT NULL PRIMARY KEY)");
    SQL_ON_ERROR_RETURN(@"SELECT AddGeometryColumn('txl_geometry', 'geometry', 4326, 'GEOMETRYCOLLECTION', 2)");
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_movingobject ( \
                        id INTEGER NOT NULL PRIMARY KEY,\
                        \"begin\", \
                        \"end\", \
                        bounds INTEGER REFERENCES txl_geometry (id) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_snapshot ( \
                        id INTEGER NOT NULL PRIMARY KEY, \
                        count INTEGER NOT NULL, \
                        movingobject_id INTEGER NOT NULL REFERENCES txl_movingobject (id), \
                        geometry_id INTEGER NOT NULL REFERENCES txl_geometry (id), \
                        timestamp \
                        )");
    
    SQL_ON_ERROR_RETURN(@"SELECT CreateSpatialIndex('txl_geometry', 'geometry')");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_movingobject_begin ON txl_movingobject (\"begin\")");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_movingobject_end ON txl_movingobject (\"end\")");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_snapshot_movingobject_id ON txl_snapshot (movingobject_id)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_snapshot_timestamp ON txl_snapshot (timestamp)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_snapshot_geometry_id ON txl_snapshot (geometry_id)");
    
    return YES;
}

- (BOOL)setupDatabaseForTXLMovingObjectSequence:(NSError **)error {
    
    NSLog(@"Setup database for TXLMovingObjectSequence.");
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_movingobjectsequence (sequence_id integer NOT NULL PRIMARY KEY)");
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_movingobjectsequence_movingobject ( \
                        count INTEGER NOT NULL, \
                        sequence_id integer NOT NULL REFERENCES txl_movingobjectsequence (sequence_id), \
                        movingobject_id integer NOT NULL REFERENCES txl_movingobject (id), \
                        UNIQUE(sequence_id, movingobject_id), \
                        UNIQUE(sequence_id, count))");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_movingobjectsequence_sequence_id ON txl_movingobjectsequence (sequence_id)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_movingobjectsequence_movingobject_sequence_id ON txl_movingobjectsequence_movingobject (sequence_id)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_movingobjectsequence_movingobject_movingobject_id ON txl_movingobjectsequence_movingobject (movingobject_id)");
    
    return YES;
}

- (BOOL)setupDatabaseForTXLTerm:(NSError **)error {
    
    NSLog(@"Setup database for TXLTerm.");
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_term (id integer NOT NULL PRIMARY KEY, type NOT NULL, value, meta, UNIQUE(type, value, meta))");
    
    return YES;
}

- (BOOL)setupDatabaseForSituations:(NSError **)error {
    
    NSLog(@"Setup database for situations.");
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_statement ( \
                        id integer NOT NULL PRIMARY KEY, \
                        subject_id integer NOT NULL REFERENCES txl_term (id), \
                        predicate_id integer NOT NULL REFERENCES txl_term (id), \
                        object_id integer NOT NULL REFERENCES txl_term (id), \
                        mo_id integer REFERENCES txl_movingobject (id), \
                        context_id integer NOT NULL REFERENCES txl_context (id) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_statement_subject_id ON txl_statement (subject_id)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_statement_predicate_id ON txl_statement (predicate_id)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_statement_object_id ON txl_statement (object_id)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_statement_mo_id ON txl_statement (mo_id)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_statement_context_id ON txl_statement (context_id)");
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_statement_created ( id integer NOT NULL PRIMARY KEY, statement_id integer NOT NULL UNIQUE REFERENCES txl_statement (id), revision_id integer NOT NULL REFERENCES txl_revision (id) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_statement_created_statement_id ON txl_statement_created (statement_id)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_statement_created_revision_id ON txl_statement_created (revision_id)");
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_statement_removed ( id integer NOT NULL PRIMARY KEY, statement_id integer NOT NULL UNIQUE REFERENCES txl_statement (id), revision_id integer NOT NULL REFERENCES txl_revision (id))");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_statement_removed_statement_id ON txl_statement_removed (statement_id)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_statement_removed_revision_id ON txl_statement_removed (revision_id)");
    
    return YES;
}

- (BOOL)setupDatabaseForTXLQuery:(NSError **)error {
    
    NSLog(@"Setup database for TXLQuery.");
    
    // Query "Header"
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query ( \
                        id INTEGER NOT NULL PRIMARY KEY, \
                        sparql TEXT NOT NULL, \
                        first_evaluation INTEGER REFERENCES txl_revision (id), \
                        last_evaluation INTEGER REFERENCES txl_revision (id), \
                        pattern_id INTEGER NOT NULL REFERENCES txl_query_pattern (id), \
						construct_template_pattern_id INTEGER REFERENCES txl_query_pattern (id) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_first_evaluation ON txl_query (first_evaluation)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_last_evaluation ON txl_query (last_evaluation)");
    
    // Contexts
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query_context ( \
                        id integer NOT NULL PRIMARY KEY, \
                        query_id integer NOT NULL REFERENCES txl_query (id), \
                        context_id integer NOT NULL REFERENCES txl_context (id), \
                        UNIQUE(query_id, context_id) \
                        )");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_context_query_id ON txl_query_context (query_id)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_context_context_id ON txl_query_context (context_id)");
    
    // Pattern Variables
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query_variable ( \
                        id integer NOT NULL PRIMARY KEY, \
                        query_id integer NOT NULL REFERENCES txl_query (id), \
                        name varchar(1024), \
                        in_resultset BOOL DEFAULT FALSE, \
                        is_blanknode BOOL DEFAULT FALSE, \
                        UNIQUE(query_id, name, is_blanknode) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_variable_query_id ON txl_query_variable (query_id)");
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_variable_name ON txl_query_variable (name)");
    
    // Graph Pattern
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query_pattern (id integer NOT NULL PRIMARY KEY)");
    
    // Basic Graph Pattern
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query_pattern_triple ( \
                        id integer NOT NULL PRIMARY KEY, \
                        in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id), \
                        \
                        subject_id integer REFERENCES txl_term (id), \
                        subject_var_id integer REFERENCES txl_query_variable (id), \
                        \
                        predicate_id integer REFERENCES txl_term (id), \
                        predicate_var_id integer REFERENCES txl_query_variable (id), \
                        \
                        object_id integer REFERENCES txl_term (id), \
                        object_var_id integer REFERENCES txl_query_variable (id) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_pattern_triple_in_pattern_id ON txl_query_pattern_triple (in_pattern_id)");
    
    // Group Graph Pattern
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query_pattern_group ( \
                        id integer NOT NULL PRIMARY KEY, \
                        in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id), \
                        pattern_id integer NOT NULL REFERENCES txl_query_pattern (id) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_pattern_group_in_pattern_id ON txl_query_pattern_group (in_pattern_id)");
    
    // Optional Graph Pattern
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query_pattern_optional ( \
                        id integer NOT NULL PRIMARY KEY, \
                        in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id), \
                        pattern_id integer NOT NULL REFERENCES txl_query_pattern (id) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_pattern_optional_in_pattern_id ON txl_query_pattern_optional (in_pattern_id)");
    
    // Alternative Graph Pattern
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query_pattern_union ( \
                        id integer NOT NULL PRIMARY KEY, \
                        in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_pattern_union_in_pattern_id ON txl_query_pattern_union (in_pattern_id)");
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query_pattern_union_pattern ( \
                        id integer NOT NULL PRIMARY KEY, \
                        union_id integer NOT NULL REFERENCES txl_query_pattern_union (id), \
                        pattern_id integer NOT NULL REFERENCES txl_query_pattern (id) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_pattern_union_pattern_union_id ON txl_query_pattern_union_pattern (union_id)");
    
    // Named Graph Pattern
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query_pattern_named ( \
                        id integer NOT NULL PRIMARY KEY, \
                        in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id), \
                        \
                        context_id integer REFERENCES txl_context (id), \
                        context_var_id integer REFERENCES txl_query_variable (id), \
                        \
                        pattern_id integer NOT NULL REFERENCES txl_query_pattern (id) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_pattern_named_in_pattern_id ON txl_query_pattern_named (in_pattern_id)");
    
    // Not Exists Graph Pattern
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query_pattern_not_exists ( \
                        id integer NOT NULL PRIMARY KEY, \
                        in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id), \
                        pattern_id integer NOT NULL REFERENCES txl_query_pattern (id) \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_pattern_not_exists_in_pattern_id ON txl_query_pattern_not_exists (in_pattern_id)");
    
    // Filter
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query_pattern_filter ( \
                        id integer NOT NULL PRIMARY KEY, \
                        in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id), \
                        expression TEXT NOT NULL \
                        )");
    
    SQL_ON_ERROR_RETURN(@"CREATE INDEX IF NOT EXISTS txl_query_pattern_filter_in_pattern_id ON txl_query_pattern_filter (in_pattern_id)");
    
	
    // Query Name
    // ----------------------------
    
    SQL_ON_ERROR_RETURN(@"CREATE TABLE IF NOT EXISTS txl_query_name ( \
                        id INTEGER NOT NULL PRIMARY KEY, \
                        query_id integer REFERENCES txl_query (id), \
                        name TEXT NOT NULL UNIQUE \
                        )");
    
    return YES;
}

- (BOOL)setupDatabaSpatialMetadata:(NSError **)error {
    
    // spatial metadata
    if (![self.database.tableNames containsObject:@"spatial_ref_sys"] ||
        ![self.database.tableNames containsObject:@"geometry_columns"]) {
        NSLog(@"Init spatial metadata.");
        SQL_ON_ERROR_RETURN(@"SELECT InitSpatialMetaData()");
    }
    
    return YES;
}

- (BOOL)setupDatabase:(NSError **)error {
    
    NSLog(@"Setup database ...");
    
    if ([self setupDatabaSpatialMetadata:error] == NO) {
        return NO;
    }
    
    // Create the database tables for OpenTXL
    if ([self.database beginTransaction:error] == NO)
        return NO;
    
    if ([self setupDatabaseForTXLRevision:error] == NO) {
        [self.database rollback:error];
        return NO;
    }
    
    if ([self setupDatabaseForTXLContext:error] == NO) {
        [self.database rollback:error];
        return NO;
    }
    
    if ([self setupDatabaseForTXLMovingObject:error] == NO) {
        [self.database rollback:error];
        return NO;
    }
    
    if ([self setupDatabaseForTXLMovingObjectSequence:error] == NO) {
        [self.database rollback:error];
        return NO;
    }
    
    if ([self setupDatabaseForTXLTerm:error] == NO) {
        [self.database rollback:error];
        return NO;
    }
    
    if ([self setupDatabaseForSituations:error] == NO) {
        [self.database rollback:error];
        return NO;
    }
    
    if ([self setupDatabaseForTXLQuery:error] == NO) {
        [self.database rollback:error];
        return NO;
    }
    
    if ([self.database commit:error] == NO) {
        return NO;
    };
    
    NSLog(@"... database setup completed.");
    
    return YES;
}

#pragma mark -
#pragma mark Processing

- (void)increaseProcessingCounter {
    @synchronized (self) {
        if (processing_counter == 0) {
            processing = YES;
            if ([self.delegate respondsToSelector:@selector(didStartProcessing)]) {
                [self.delegate didStartProcessing];
            }
        }
        processing_counter++;
    }
}

- (void)decreaseProcessingCounter {
    @synchronized (self) {
        processing_counter--;
        if (processing_counter == 0) {
            processing = NO;
            
            if ([self.delegate respondsToSelector:@selector(didEndProcessing)]) {
                [self.delegate didEndProcessing];
            }
            
        }
    }
}

#pragma mark -
#pragma mark Evaluate Queries

- (void)evaluateQuery:(TXLQuery *)query
           atRevision:(TXLRevision *)rev {
    
    // ------------------------------------------------
    // Notify the delegate that the processing starts
    
    [self increaseProcessingCounter];
    
    dispatch_group_async(manager_group, manager_queue, ^{
		
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
		// This function updates the resultset of a query
		// after checking if the update leads into a change. It
		// compares the current state of the resultset with the update
		// and only modifies the state if needed.
        
        __block NSError *error;
        BOOL success;
        
        // ------------------------------------------------
        // get contexts <ctxs> that are defined in the from clause
        // of this query
        
        NSArray *ctxs = query.contexts;
        
        // ------------------------------------------------
        // get all variables of this query,
        // that should be contained in the
        // resultset
        
        NSArray *varsOfResultset = [query variablesOfResultset];
        
        // ------------------------------------------------
        // evaluate query pattern of this query in revision <rev>
        // in contexts <ctxs>
        
        __block NSMutableDictionary *resultSet = [NSMutableDictionary dictionary];
        
        [[query queryPattern] evaluatePatternWithVariables:[NSDictionary dictionary]
                                                inContexts:ctxs 
                                                    window:nil
                                               forRevision:rev 
                                             resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                                 
                                                 // collect the results, so that each result
                                                 // will be contained only once in the resulting
                                                 // resultset
                                                 
                                                 NSMutableDictionary *reducedVars = [NSMutableDictionary dictionary];
                                                 for (NSString *varName in [vars allKeys]) {
                                                     if ([varsOfResultset containsObject:varName]) {
                                                         [reducedVars setObject:[vars objectForKey:varName]
                                                                         forKey:varName];
                                                     }
                                                 }
												 
												 TXLMovingObjectSequence *sequence = [resultSet objectForKey:reducedVars];
                                                 if (sequence == nil) {
                                                     if (mos == nil) {
                                                         [resultSet setObject:[NSNull null]
                                                                       forKey:reducedVars];
                                                     } else {
                                                         [resultSet setObject:mos
                                                                       forKey:reducedVars];
                                                     }
                                                 } else {
                                                     if ([sequence isKindOfClass:[TXLMovingObjectSequence class]]) {
                                                         if (mos == nil) {
                                                             [resultSet setObject:[NSNull null]
                                                                           forKey:reducedVars];
                                                             
                                                         } else {
                                                             [resultSet setObject:[sequence unionWithMovingObjectSequence:mos]
                                                                           forKey:reducedVars];
                                                         }
                                                     }
                                                 }
                                             }];
        
		// TODO: here it must be checked whether all the results
		// in the resultset contain values for all variables 
		// which should be in the resultset. 
		// Given that the interpreter does not support the OPTIONAL
		// pattern all variables (which should appear in the resultset) 
		// should have a value in the results.
		// This should not be the case if the OPTIONAL pattern
		// is supported. In this case the code of filling the resultset table
		// needs changes because it crashes if there is no value for a variable
		// that should be in the resultset.
		
        NSMutableSet *removedRows = [NSMutableSet set];
        NSMutableSet *createdRows = [NSMutableSet set];
        
		// Initially the whole evaluated resultset is set to be actually new.
	    NSMutableDictionary *resultSetToUpdate = resultSet;
        
        //NSLog(@"New Result Set: %@", resultSetToUpdate);
        
        NSString *resultsetTableName = [NSString stringWithFormat:@"txl_resultset_%d", query.primaryKey];
        NSString *createdTableName = [NSString stringWithFormat:@"txl_resultset_%d_created", query.primaryKey];
        NSString *removedTableName = [NSString stringWithFormat:@"txl_resultset_%d_removed", query.primaryKey];
        
        // ------------------------------------------------
        // Find all rows in the result set which should be removed.
        // Only the rows which have changed are replaced.
		// Simultaneously, the results which are new are found
		// so that only these results are afterwards updated.
		
        success = [self.database executeSQL:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE NOT id IN (SELECT resultset_id FROM %@)", 
                                             resultsetTableName, removedTableName]
                             withParameters:[NSArray array]
                                      error:&error
                              resultHandler:^(NSDictionary *row, BOOL *stop){
								  
								  NSMutableDictionary *varsInOldResult = [NSMutableDictionary dictionary];
                                  
								  for (NSString *column in [row allKeys]) {
									  if ([column hasPrefix:@"var_"]) {
										  [varsInOldResult setObject:[row objectForKey:column] forKey:[TXLInteger integerWithValue:[[column substringFromIndex:4] integerValue]]];
									  }
								  }
								  TXLMovingObjectSequence *oldSequence = [TXLMovingObjectSequence sequenceWithPrimaryKey:[[row objectForKey:@"mos_id"] unsignedIntegerValue]];
								  
                                  //NSLog(@"Checking if new result set contains row: %@ with moving object: %@", varsInOldResult, oldSequence);
                                  
								  // Check if this combination of variables values is contained in the old resultset.
								  TXLMovingObjectSequence *sequence = [resultSet objectForKey:varsInOldResult];
								  
  								  // If this combination of variables values is contained in the old resultset
								  // then compare the moving object sequence attached to the old result set with the new one.
								  
								  if((sequence != nil) && [sequence isEqual:oldSequence]) {
                                      //NSLog(@"Row already in result set: %@, %@", varsInOldResult, sequence);
									  [resultSetToUpdate removeObjectForKey:varsInOldResult];							  
                                  } else {
									  [removedRows addObject:[row objectForKey:@"id"]];								  
								  }
                              }];
        if (!success) {
            [[NSException exceptionWithName:@"TXLManagerException"
                                     reason:[error localizedDescription]
                                   userInfo:nil] raise];
        }
        
        // ------------------------------------------------
        // Create the new rows based on this evaluation
        // Collect all new rows.
        
        // Create the SQL statement
        NSMutableString *sqlExpr = [NSMutableString stringWithFormat:@"INSERT INTO %@ (mos_id", resultsetTableName];
        for (NSString *v in varsOfResultset) {
            [sqlExpr appendFormat:@", var_%d", [v integerValue]];
        }
        [sqlExpr appendString:@") VALUES (?"];
        for (int i = 0; i < [varsOfResultset count]; i++) {
            [sqlExpr appendString:@", ?"];
        }
        [sqlExpr appendString:@")"];
        
        
		// If there are actual new results then the resultset should be updated.
		for (NSDictionary *vars in resultSetToUpdate) {
            
            NSMutableArray *sqlParams = [NSMutableArray array];
            
            // save the moving object sequence
            
            TXLMovingObjectSequence *mos = [resultSetToUpdate objectForKey:vars];
            if ([mos isKindOfClass:[TXLMovingObjectSequence class]]) {
                mos = [mos save:&error];
                if (mos == nil) {
                    [[NSException exceptionWithName:@"TXLManagerException"
                                             reason:[error localizedDescription]
                                           userInfo:nil] raise];
                }
                [sqlParams addObject:[TXLInteger integerWithValue:mos.primaryKey]];
            } else {
                [sqlParams addObject:[TXLInteger integerWithValue:0]];
            }
            
            for (NSString *v in varsOfResultset) {
                [sqlParams addObject:[vars objectForKey:v]];
            }
            
            if ([self.database executeSQL:sqlExpr
                           withParameters:sqlParams
                                    error:&error] == nil) {
                [[NSException exceptionWithName:@"TXLManagerException"
                                         reason:[error localizedDescription]
                                       userInfo:nil] raise];
            }
            [createdRows addObject:[TXLInteger integerWithValue:self.database.lastInsertRowid]];
        }
        
        // ------------------------------------------------
        
		// Apply the changes by inserting the removed and created rows in
		// the corresponding tables (txl_resultset_<id>_removed,
		// txl_resultset_<id>_created). 
		// This happens only if there are any removed or created rows.
		
		if( ([createdRows count] > 0) || 
		   ([removedRows count] > 0) ){
            
			// begin transaction
			if ([self.database beginTransaction:&error] == NO) {
				[[NSException exceptionWithName:@"TXLManagerException"
										 reason:[error localizedDescription]
									   userInfo:nil] raise];
				NSLog(@"Could not begin transaction: %@", [error localizedDescription]);
			}
			
			NSString *sqlExpressionRemovedRows = [NSString stringWithFormat:@"INSERT INTO %@ (resultset_id, revision_id) VALUES(?, ?)", removedTableName];
			for (TXLInteger *pk in removedRows) {
				if ([self.database executeSQLWithParameters:sqlExpressionRemovedRows
													  error:&error, pk, [TXLInteger integerWithValue:[rev primaryKey]],
					 nil] == nil) {
					[self.database rollback:&error];
					[[NSException exceptionWithName:@"TXLManagerException"
											 reason:[error localizedDescription]
										   userInfo:nil] raise];
				}
			}
			
			NSString *sqlExpressionCreatedRows = [NSString stringWithFormat:@"INSERT INTO %@ (resultset_id, revision_id) VALUES(?, ?)", createdTableName];
			for (TXLInteger *pk in createdRows) {
				if ([self.database executeSQLWithParameters:sqlExpressionCreatedRows
													  error:&error, pk, [TXLInteger integerWithValue:[rev primaryKey]],
					 nil] == nil) {
					[self.database rollback:&error];
					[[NSException exceptionWithName:@"TXLManagerException"
											 reason:[error localizedDescription]
										   userInfo:nil] raise];
				}
			}
			
			// commit transaction
			if ([self.database commit:&error] == NO) {
				[[NSException exceptionWithName:@"TXLManagerException"
										 reason:[error localizedDescription]
									   userInfo:nil] raise];
			}
			
			// ------------------------------------------------
			// Check if the query is of type construct and create
			// new situations based on the result set.
			// The update of the statements of a construct query
			// is done only if there was an update in the resultset of the query.
            
			if (query.constructQuery) {
				// query is of type construct.
				// update context with the results.
				
				
				// get the context this query is associated to
				__block TXLContext *queryContext = nil;
				success = [self.database executeSQL:@"SELECT context_id FROM txl_context_query WHERE query_id = ?"
									 withParameters:[NSArray arrayWithObject:[TXLInteger integerWithValue:query.primaryKey]]
											  error:&error
									  resultHandler:^(NSDictionary *row, BOOL *stop){
										  NSUInteger pk = [[row objectForKey:@"context_id"] unsignedIntegerValue];
										  if (pk > 0) {
											  queryContext = [[TXLContext contextWithPrimaryKey:pk] retain];
										  }
									  }];
				
				if (!success) {
					[[NSException exceptionWithName:@"TXLManagerException"
											 reason:[error localizedDescription]
										   userInfo:nil] raise];
				}
				
				if (queryContext == nil) {
					//NSLog(@"Query not associated with a context.");
					
				} else {
					//NSLog(@"CONSTRUCT QUERY -> update context: %@", queryContext);
					
                    
                    NSMutableArray *operations = [NSMutableArray array];
                    
					NSString *tableName = [NSString stringWithFormat:@"txl_resultset_%d", query.primaryKey]; 
					NSString *tableName_created = [NSString stringWithFormat:@"txl_resultset_%d_created", query.primaryKey]; 
					NSString *tableName_removed = [NSString stringWithFormat:@"txl_resultset_%d_removed", query.primaryKey]; 
					
					// clear context for rows which have been removed
					// ----------------------------------------------
					
					if (![self.database executeSQL:[NSString stringWithFormat:@"SELECT resultset_id FROM %@ WHERE revision_id = ?", tableName_removed]
									withParameters:[NSArray arrayWithObject:[TXLInteger integerWithValue:rev.primaryKey]]
											 error:&error
									 resultHandler:^(NSDictionary *row, BOOL *stop){
										 TXLContext *ctx = [queryContext childWithName:[NSString stringWithFormat:@"#%d", [[row objectForKey:@"resultset_id"] integerValue]]];
										 //NSLog(@"Clearing context: %@", ctx);
                                         
                                         TXLManagerUpdateOperation *op = [[TXLManagerUpdateOperation alloc] initWithContext:ctx
                                                                                                                  situation:nil
                                                                                                               intervalFrom:nil
                                                                                                                         to:nil];
                                         [operations addObject:op];
                                         [op release];
                                         
									 }]) {
										 [[NSException exceptionWithName:@"TXLManagerException"
																  reason:[error localizedDescription]
																userInfo:nil] raise];
									 }
					
					// create new context for rows which have been added
					// -------------------------------------------------
					
					NSArray *pattern = [self.database executeSQL:@"SELECT txl_query_pattern_triple.* FROM txl_query_pattern_triple, txl_query WHERE txl_query_pattern_triple.in_pattern_id = txl_query.construct_template_pattern_id AND txl_query.id = ?"
												  withParameters:[NSArray arrayWithObject:[TXLInteger integerWithValue:query.primaryKey]]
														   error:&error];
					if (pattern == nil) {
						[[NSException exceptionWithName:@"TXLManagerException"
												 reason:[error localizedDescription]
											   userInfo:nil] raise];
					}
					
					NSString *sql = [NSString stringWithFormat:@"SELECT %@.* FROM %@, %@ WHERE %@.revision_id = ? AND %@.resultset_id = %@.id",
									 tableName,
									 tableName,
									 tableName_created,
									 tableName_created,
									 tableName_created,
									 tableName];
					
					success = [self.database executeSQL:sql
										 withParameters:[NSArray arrayWithObject:[TXLInteger integerWithValue:rev.primaryKey]]
												  error:&error
										  resultHandler:^(NSDictionary *row, BOOL *stop){
											  TXLContext *ctx = [queryContext childWithName:[NSString stringWithFormat:@"#%d", [[row objectForKey:@"id"] integerValue]]];
											  //NSLog(@"Creating context: %@", ctx);
											  
											  NSMutableArray *statements = [NSMutableArray array];
											  NSMutableDictionary *blankNodes = [NSMutableDictionary dictionary];
											  
											  for (NSDictionary *triple in pattern) {
												  
												  TXLTerm *subject;
												  TXLTerm *predicate;
												  TXLTerm *object;
												  
												  TXLInteger *subject_id = [triple objectForKey:@"subject_id"];
												  TXLInteger *subject_var_id = [triple objectForKey:@"subject_var_id"];
												  if ([subject_id isKindOfClass:[TXLInteger class]] && [subject_id integerValue] > 0) {
													  subject = [TXLTerm termWithPrimaryKey:[subject_id integerValue]];
												  } else {
													  
													  NSArray *subject_var = [self.database executeSQL:@"SELECT * FROM txl_query_variable WHERE id = ?"
																						withParameters:[NSArray arrayWithObject:subject_var_id]
																								 error:&error];
													  if (!subject_var) {
														  [[NSException exceptionWithName:@"TXLManagerException"
																				   reason:[error localizedDescription]
																				 userInfo:nil] raise];
													  }
													  
													  if ([subject_var count] != 1) {
														  [[NSException exceptionWithName:@"TXLManagerException"
																				   reason:[NSString stringWithFormat:@"Expecting values for var with id %@", subject_var_id]
																				 userInfo:nil] raise];
													  }
													  
													  if ([[[subject_var objectAtIndex:0] objectForKey:@"is_blanknode"] integerValue]) {
														  NSString *bnName = [[subject_var objectAtIndex:0] objectForKey:@"name"];
														  TXLTerm *bn = [blankNodes objectForKey:bnName];
														  if (bn) {
															  subject = bn;
														  } else {
															  subject = [TXLTerm termWithBlankNode:nil];
															  [blankNodes setObject:subject forKey:bnName];
														  }
													  } else {
														  subject = [TXLTerm termWithPrimaryKey:
																	 [
																	  [row objectForKey:
																	   [NSString stringWithFormat:@"var_%d", subject_var_id.integerValue]
																	   ]
																	  integerValue
																	  ]
																	 ];
													  }
												  }
												  
												  TXLInteger *predicate_id = [triple objectForKey:@"predicate_id"];
												  TXLInteger *predicate_var_id = [triple objectForKey:@"predicate_var_id"];
												  if ([predicate_id isKindOfClass:[TXLInteger class]] && [predicate_id integerValue] > 0) {
													  predicate = [TXLTerm termWithPrimaryKey:[predicate_id integerValue]];
												  } else {
													  predicate = [TXLTerm termWithPrimaryKey:
																   [
																	[row objectForKey:
																	 [NSString stringWithFormat:@"var_%d", predicate_var_id.integerValue]
																	 ]
																	integerValue
																	]
																   ];
												  }
												  
												  TXLInteger *object_id = [triple objectForKey:@"object_id"];
												  TXLInteger *object_var_id = [triple objectForKey:@"object_var_id"];
												  if ([object_id isKindOfClass:[TXLInteger class]] && [object_id integerValue] > 0) {
													  object = [TXLTerm termWithPrimaryKey:[object_id integerValue]];
												  } else {
													  
													  NSArray *object_var = [self.database executeSQL:@"SELECT * FROM txl_query_variable WHERE id = ?"
																					   withParameters:[NSArray arrayWithObject:object_var_id]
																								error:&error];
													  if (!object_var) {
														  [[NSException exceptionWithName:@"TXLManagerException"
																				   reason:[error localizedDescription]
																				 userInfo:nil] raise];
													  }
													  
													  if ([object_var count] != 1) {
														  [[NSException exceptionWithName:@"TXLManagerException"
																				   reason:[NSString stringWithFormat:@"Expecting values for var with id %@", object_var_id]
																				 userInfo:nil] raise];
													  }
													  
													  if ([[[object_var objectAtIndex:0] objectForKey:@"is_blanknode"] integerValue]) {
														  NSString *bnName = [[object_var objectAtIndex:0] objectForKey:@"name"];
														  TXLTerm *bn = [blankNodes objectForKey:bnName];
														  if (bn) {
															  object = bn;
														  } else {
															  object = [TXLTerm termWithBlankNode:nil];
															  [blankNodes setObject:object forKey:bnName];
														  }
													  } else {
														  object = [TXLTerm termWithPrimaryKey:
																	[
																	 [row objectForKey:
																	  [NSString stringWithFormat:@"var_%d", object_var_id.integerValue]
																	  ]
																	 integerValue
																	 ]
																	];
													  }
												  }
												  
												  
												  TXLStatement *st = [TXLStatement statementWithSubject:subject
																							  predicate:predicate
																								 object:object];
												  [statements addObject:st];
											  }
                                              
                                              TXLMovingObjectSequence *mos = [TXLMovingObjectSequence sequenceWithPrimaryKey:[[row objectForKey:@"mos_id"] integerValue]];
                                              
                                              TXLSituation *situation = [[TXLSituation alloc] initWithStatements:statements
                                                                                            movingObjectSequence:mos];
                                              
                                              TXLManagerUpdateOperation *op = [[TXLManagerUpdateOperation alloc] initWithContext:ctx
                                                                                                                       situation:situation
                                                                                                                    intervalFrom:nil
                                                                                                                              to:nil];
                                              
                                              [operations addObject:op];
                                              
                                              [op release];
                                              [situation release];
										  }];
					
                    if (!success) {
                        [[NSException exceptionWithName:@"TXLManagerException"
                                                 reason:[error localizedDescription]
                                               userInfo:nil] raise];
                    }
                    
                    [self applyOperations:operations
                      withCompletionBlock:^(TXLRevision *rev, NSError *error){
                          if (rev) {
                              //NSLog(@"Context '%@' updated by construct expression.", queryContext);
                          } else {
                              //NSLog(@"Error updating context '%@' by construct expression: %@", queryContext, [error localizedDescription]);
                          }
                          [queryContext release];
                      }];
				}
			}
			
			
			// ------------------------------------------------
			// Send notification, that the result set has changed.
			// This notification is sent only if there was an update in the resultset of the query.
			
			NSNotification *notification = [NSNotification notificationWithName:[NSString stringWithFormat:@"org.opentxl.manager.resultset.%d", query.primaryKey]
																		 object:self
																	   userInfo:[NSDictionary dictionaryWithObject:rev forKey:@"revision"]];
			
			[[NSNotificationQueue defaultQueue] enqueueNotification:notification
													   postingStyle:NSPostNow
													   coalesceMask:NSNotificationNoCoalescing
														   forModes:nil];        
		}		
        
		// Change the last_evaluation parameter of the query 
		// and set the first_evaluation parameter if it has not already been set.
		// This change in the last_evaluation parameter is made either 
		// if there was a change in the resultset or not, because in 
		// both cases the query was evaluated and updated (if necessary) for this revision.
		
		// Set first_evaluation property of the query if it has not been already set.
		
		NSArray *result = [self.database executeSQLWithParameters:@"SELECT first_evaluation FROM txl_query WHERE id = ?" 
                                                            error:&error, 
                           [TXLInteger integerWithValue:[query primaryKey]],
                           nil];
		
		if ( result != nil) {
			if ( ([result count] == 0) || ([[[result objectAtIndex:0] objectForKey:@"first_evaluation"] intValue] == 0) ){
				if ([self.database executeSQLWithParameters:@"UPDATE txl_query SET first_evaluation = ? WHERE id = ?" 
													  error:&error, 
					 [TXLInteger integerWithValue:[rev primaryKey]],
					 [TXLInteger integerWithValue:[query primaryKey]],
					 nil] == nil){
					@throw [NSException exceptionWithName:@"TXLManagerException"
												   reason:[error localizedDescription]
												 userInfo:nil];
				}
			}
		} else {
			@throw [NSException exceptionWithName:@"TXLManagerException"
										   reason:[error localizedDescription]
										 userInfo:nil];
		}
		
		if ([self.database executeSQLWithParameters:@"UPDATE txl_query SET last_evaluation = ? WHERE id = ?" 
											  error:&error, 
			 [TXLInteger integerWithValue:[rev primaryKey]],
			 [TXLInteger integerWithValue:[query primaryKey]],
			 nil] == nil){
			@throw [NSException exceptionWithName:@"TXLManagerException"
										   reason:[error localizedDescription]
										 userInfo:nil];
		}
        
        [pool drain];
        [self decreaseProcessingCounter];
    });
}

- (void)evaluateQueriesForContexts:(NSSet *)ctxs
                        atRevision:(TXLRevision *)rev {
    
    // TODO: this function has to be synchronized for every query, since
    // one can call the updateContext function twice in parallel
    // and it must be ensured that the smaller revision id
    // has to be evaluated before the newer resp. higher revision
    // id will be evaluated, because the resultset of the
    // newer revision id depends on the resultset of the previous
    // revision id. Since there is only a conflict between resultsets,
    // the synchronization per query is sufficient, since a resultset
    // is directly related to a query.
    
    // TODO: maybe better error handling, since the evaluation would
    // be called async, currently there are only exceptions
    // that would be thrown, when an error occurs.
    
    NSError *error;
    
    // Only this function should modify the tables holding
    // the result sets for the continuous queries.
    
    // Find all queries containing a context in the FROM clause
    // which is equal to ctx or where ctx is a child context.
    
    NSArray *queries = [[TXLQuery queriesForContexts:ctxs
                                               error:&error] retain];
    
    if (queries == nil) {
        [[NSException exceptionWithName:@"TXLManagerException"
                                 reason:[error localizedDescription]
                               userInfo:nil] raise];
    }
    
    // Trigger the evaluation of all found queries
    // at revision rev
    
    for (TXLQuery *query in queries) {
        [self evaluateQuery:query atRevision:rev];
    }
    
    [queries release];
}

- (void)evaluateQueriesForContext:(TXLContext *)ctx
                       atRevision:(TXLRevision *)rev {
    
    // TODO: this function has to be synchronized for every query, since
    // one can call the updateContext function twice in parallel
    // and it must be ensured that the smaller revision id
    // has to be evaluated before the newer resp. higher revision
    // id will be evaluated, because the resultset of the
    // newer revision id depends on the resultset of the previous
    // revision id. Since there is only a conflict between resultsets,
    // the synchronization per query is sufficient, since a resultset
    // is directly related to a query.
    
    // TODO: maybe better error handling, since the evaluation would
    // be called async, currently there are only exceptions
    // that would be thrown, when an error occurs.
    
    NSError *error;
    
    // Only this function should modify the tables holding
    // the result sets for the continuous queries.
    
    // Find all queries containing a context in the FROM clause
    // which is equal to ctx or where ctx is a child context.
    
    NSArray *queries = [TXLQuery queriesForContext:ctx
                                             error:&error];
    
    if (queries == nil) {
        @throw [NSException exceptionWithName:@"TXLManagerException"
                                       reason:[error localizedDescription]
                                     userInfo:nil];
        NSLog(@"Could not load queries for context (%lu): %@", ctx.primaryKey, [error localizedDescription]);
    }
    
    // Trigger the evaluation of all found queries
    // at revision rev
    
    for (TXLQuery *query in queries) {
        //NSLog(@"Query () evaluated ");
        [self evaluateQuery:query
                 atRevision:rev];
    }
}

#pragma mark -
#pragma mark Updating Context

- (void)forMovingObjectsInContext:(TXLContext *)ctx 
                   inIntervalFrom:(NSDate *)from 
                               to:(NSDate *)to
                       applyBlock:(void(^)(TXLMovingObject *mo))block {
    
    NSError *error = nil;
    NSString *sqlStatement = nil;
    NSArray *sqlParameters = nil;
    
    if (from == nil && to == nil) {
        
        sqlStatement = @"\
        SELECT DISTINCT txl_movingobject.id as id \
        FROM txl_movingobject, txl_statement \
        WHERE \
            txl_statement.context_id = ? \
            AND txl_statement.mo_id = txl_movingobject.id \
            AND NOT txl_statement.id IN (SELECT statement_id FROM txl_statement_removed)";
        
        sqlParameters = [NSArray arrayWithObject:[TXLInteger integerWithValue:ctx.primaryKey]];
        
    } else if (from == nil) {
        
        sqlStatement = @"\
        SELECT DISTINCT txl_movingobject.id AS id \
        FROM txl_movingobject, txl_statement \
        WHERE \
            txl_statement.context_id = ? \
            AND txl_movingobject.id = txl_statement.mo_id \
            AND txl_movingobject.end <= ? \
            AND NOT txl_statement.id IN (SELECT statement_id FROM txl_statement_removed)";
        
        sqlParameters = [NSArray arrayWithObjects:[TXLInteger integerWithValue:ctx.primaryKey],
                         [NSNumber numberWithDouble:[to timeIntervalSince1970]],
                         nil];
        
    } else if (to == nil) {
        
        sqlStatement = @"\
        SELECT DISTINCT txl_movingobject.id AS id \
        FROM txl_movingobject, txl_statement \
        WHERE \
            txl_statement.context_id = ? \
            AND txl_movingobject.id = txl_statement.mo_id \
            AND txl_movingobject.begin >= ? \
            AND NOT txl_statement.id IN (SELECT statement_id FROM txl_statement_removed)";
        
        sqlParameters = [NSArray arrayWithObjects:[TXLInteger integerWithValue:ctx.primaryKey],
                         [NSNumber numberWithDouble:[from timeIntervalSince1970]],
                         nil];
        
    } else {
        
        sqlStatement = @"\
        SELECT DISTINCT txl_movingobject.id AS id \
        FROM txl_movingobject, txl_statement \
        WHERE \
            txl_statement.context_id = ? \
            AND txl_movingobject.id = txl_statement.mo_id \
            AND txl_movingobject.begin >= ? \
            AND txl_movingobject.end <= ? \
            AND NOT txl_statement.id IN (SELECT statement_id FROM txl_statement_removed)";
        
        sqlParameters = [NSArray arrayWithObjects:[TXLInteger integerWithValue:ctx.primaryKey],
                         [NSNumber numberWithDouble:[from timeIntervalSince1970]],
                         [NSNumber numberWithDouble:[to timeIntervalSince1970]],
                         nil];
        
    }
    
    
    if (![self.database executeSQL:sqlStatement              
                    withParameters:sqlParameters
                             error:&error
                     resultHandler:^(NSDictionary *row, BOOL *stop){
                         
                         block([TXLMovingObject movingObjectWithPrimaryKey:[[row objectForKey:@"id"] integerValue]]);
                         
                     }]) {
                         [[NSException exceptionWithName:@"TXLManagerException"
                                                  reason:[error localizedDescription]
                                                userInfo:nil] raise];
                     };
    
}

- (void)forMovingObjectsInContext:(TXLContext *)ctx 
         intersectingIntervalFrom:(NSDate *)from 
                               to:(NSDate *)to
                       applyBlock:(void(^)(TXLMovingObject *mo))block {
    
    NSError *error = nil;
    NSString *sqlStatement = nil;
    NSArray *sqlParameters = nil;
    
    if (from == nil && to == nil) {
        return;
    } else if (from == nil) {
        
        sqlStatement = @"\
            SELECT DISTINCT txl_movingobject.id as id \
            FROM txl_movingobject, txl_statement \
            WHERE \
                txl_statement.context_id = ? \
                AND txl_statement.mo_id = txl_movingobject.id \
                AND ( \
                        ( txl_movingobject.begin IS NULL AND txl_movingobject.end IS NULL ) \
                        OR \
                        ( txl_movingobject.begin < ? AND txl_movingobject.end IS NULL) \
                        OR \
                        ( txl_movingobject.begin < ? AND txl_movingobject.end > ? ) \
                    ) \
                AND NOT txl_statement.id IN (SELECT statement_id FROM txl_statement_removed)";
        
        sqlParameters = [NSArray arrayWithObjects:[TXLInteger integerWithValue:ctx.primaryKey],
                         [NSNumber numberWithDouble:[to timeIntervalSince1970]],
                         [NSNumber numberWithDouble:[to timeIntervalSince1970]],
                         [NSNumber numberWithDouble:[to timeIntervalSince1970]],
                         nil];
		
    } else if (to == nil) {
        
        sqlStatement = @"\
            SELECT DISTINCT txl_movingobject.id as id \
            FROM txl_movingobject, txl_statement \
            WHERE \
                txl_statement.context_id = ? \
                AND txl_statement.mo_id = txl_movingobject.id \
                AND ( \
                        ( txl_movingobject.begin IS NULL AND txl_movingobject.end IS NULL ) \
                        OR \
                        ( txl_movingobject.begin IS NULL AND txl_movingobject.end > ? ) \
                        OR \
                        ( txl_movingobject.begin < ? AND txl_movingobject.end > ? ) \
                ) \
                AND NOT txl_statement.id IN (SELECT statement_id FROM txl_statement_removed)";
        
        sqlParameters = [NSArray arrayWithObjects:[TXLInteger integerWithValue:ctx.primaryKey],
                         [NSNumber numberWithDouble:[from timeIntervalSince1970]],
                         [NSNumber numberWithDouble:[from timeIntervalSince1970]],
                         [NSNumber numberWithDouble:[from timeIntervalSince1970]],
                         nil];           
    } else {
        
        sqlStatement = @"\
            SELECT DISTINCT txl_movingobject.id as id \
            FROM txl_movingobject, txl_statement \
            WHERE \
                txl_statement.context_id = ? \
                AND txl_statement.mo_id = txl_movingobject.id \
                AND ( \
                        ( \
                            ( txl_movingobject.begin IS NULL OR txl_movingobject.begin < ? ) \
                            AND \
                            ( txl_movingobject.end IS NULL OR txl_movingobject.end > ? ) \
                        ) \
                        OR \
                        ( \
                            ( txl_movingobject.begin >= ? AND txl_movingobject.begin < ? ) \
                            AND \
                            ( txl_movingobject.end IS NULL OR txl_movingobject.end > ? ) \
                        ) \
                        OR \
                        ( \
                            ( txl_movingobject.begin IS NULL OR txl_movingobject.begin < ? ) \
                            AND \
                            ( txl_movingobject.begin > ? AND txl_movingobject.end <= ? ) \
                        ) \
                    ) \
            AND NOT txl_statement.id IN (SELECT statement_id FROM txl_statement_removed)";
        
        sqlParameters = [NSArray arrayWithObjects:[TXLInteger integerWithValue:ctx.primaryKey],
                         [NSNumber numberWithDouble:[from timeIntervalSince1970]],
                         [NSNumber numberWithDouble:[to timeIntervalSince1970]],
                         [NSNumber numberWithDouble:[from timeIntervalSince1970]],
                         [NSNumber numberWithDouble:[to timeIntervalSince1970]],
                         [NSNumber numberWithDouble:[to timeIntervalSince1970]],
                         [NSNumber numberWithDouble:[from timeIntervalSince1970]],
                         [NSNumber numberWithDouble:[from timeIntervalSince1970]],
                         [NSNumber numberWithDouble:[to timeIntervalSince1970]],
                         nil];
    }
    
    if (![self.database executeSQL:sqlStatement              
                    withParameters:sqlParameters
                             error:&error
                     resultHandler:^(NSDictionary *row, BOOL *stop){
                         
                         block([TXLMovingObject movingObjectWithPrimaryKey:[[row objectForKey:@"id"] integerValue]]);
                         
                     }]) {
                         [[NSException exceptionWithName:@"TXLManagerException"
                                                  reason:[error localizedDescription]
                                                userInfo:nil] raise];
                     };
}

- (void)forStatementsUsingMovingObject:(TXLMovingObject *)mo
                             inContext:(TXLContext *)ctx
                            applyBlock:(void(^)(TXLInteger *pk, TXLTerm *subject, TXLTerm *predicate, TXLTerm *object))block {
    
    NSError *error;
    
    NSString *sqlStatement = @"\
        SELECT id, subject_id, predicate_id, object_id \
        FROM txl_statement \
        WHERE \
            mo_id = ? \
            AND context_id = ? \
            AND NOT id IN (SELECT statement_id FROM txl_statement_removed)";
    
    NSArray *sqlParameters = [NSArray arrayWithObjects:
                              [TXLInteger integerWithValue:mo.primaryKey],
                              [TXLInteger integerWithValue:ctx.primaryKey],
                              nil];
    
    if (![self.database executeSQL:sqlStatement
                    withParameters:sqlParameters
                             error:&error
                     resultHandler:^(NSDictionary *row, BOOL *stop){
                         
                         block([row objectForKey:@"id"],
                               [TXLTerm termWithPrimaryKey:[[row objectForKey:@"subject_id"] integerValue]],
                               [TXLTerm termWithPrimaryKey:[[row objectForKey:@"predicate_id"] integerValue]],
                               [TXLTerm termWithPrimaryKey:[[row objectForKey:@"object_id"] integerValue]]);
                         
                     }]) {
                         [[NSException exceptionWithName:@"TXLManagerException"
                                                  reason:[error localizedDescription]
                                                userInfo:nil] raise];
                     };
    
}

- (BOOL)statement:(TXLStatement *)stmnt
 withMovingObject:(TXLMovingObject *)mo
   isInStatements:(NSArray *)stmnts
withMovingObjects:(TXLMovingObjectSequence *)mos {
    
    for (TXLMovingObject *mo_ in mos.movingObjects) {
        
        for (TXLStatement *stmnt_ in stmnts) {
            
            if([self statement:stmnt_
              WithMovingObject:mo_
            isEqualToStatement:stmnt
              withMovingObject:mo]){
                
                return YES;
                
            }
            
        }
        
    }
    
    return NO;
    
}

- (BOOL)statement:(TXLStatement *)stmnt1
 WithMovingObject:(TXLMovingObject *)mo1 
isEqualToStatement:(TXLStatement *)stmnt2
 withMovingObject:(TXLMovingObject *)mo2 {
    
    if(![stmnt1.subject isEqual:stmnt2.subject]){
        return NO;
    }
    if(![stmnt1.predicate isEqual:stmnt2.predicate]){
        return NO;
    }
    if(![stmnt1.object isEqual:stmnt2.object]){
        return NO;
    }
    if(![mo1 isEqual:mo2]){
        return NO;
    }
    
    return YES;
    
}

- (TXLInteger *)setSubject:(TXLTerm *)subject
                 predicate:(TXLTerm *)predicate
                    object:(TXLTerm *)object
                 inContext:(TXLContext *)ctx
           forMovingObject:(TXLMovingObject *)mo {
    NSError *error;
    
    [subject save:&error];
    [predicate save:&error];
    [object save:&error];
    
    [mo save:&error];
    
    NSString *sqlStatement = @"INSERT INTO txl_statement (subject_id, predicate_id, object_id, context_id, mo_id) VALUES (?, ?, ?, ?, ?)";
    NSArray *sqlParameters = [NSArray arrayWithObjects:
                              [TXLInteger integerWithValue:subject.primaryKey],
                              [TXLInteger integerWithValue:predicate.primaryKey],
                              [TXLInteger integerWithValue:object.primaryKey],
                              [TXLInteger integerWithValue:ctx.primaryKey],
                              [TXLInteger integerWithValue:mo.primaryKey],
                              nil];
    
    if ([self.database executeSQL:sqlStatement withParameters:sqlParameters error:&error] == nil) {
        [[NSException exceptionWithName:@"TXLManagerException"
                                 reason:[error localizedDescription]
                               userInfo:nil] raise];
    };
    
    return [TXLInteger integerWithValue:self.database.lastInsertRowid];
}

@end

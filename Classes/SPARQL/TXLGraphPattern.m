//
//  TXLGraphPattern.m
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

#import "TXLGraphPattern.h"

#import "TXLDatabase.h"
#import "TXLManager.h"
#import "TXLRevision.h"
#import "TXLContext.h"
#import "TXLMovingObject.h"
#import "TXLMovingObjectSequence.h"
#import "TXLInteger.h"

@interface TXLGraphPattern ()
- (id)initWithPrimaryKey:(NSUInteger)pk;

- (void)evaluateBasicGraphPatternWithVariables:(NSDictionary *)vars
                                    inContexts:(NSArray *)ctxs
                                       windows:(TXLMovingObjectSequence *)mos
                                   forRevision:(TXLRevision *)rev
                                 rootPatternId:(NSUInteger)rootPatternId
                                 resultHandler:(void (^)(NSDictionary *, TXLMovingObjectSequence *))handler;

- (void)evaluateNotExistsGraphPatternWithVariables:(NSDictionary *)vars
                                        inContexts:(NSArray *)ctxs
                                           windows:(TXLMovingObjectSequence *)mos
                                       forRevision:(TXLRevision *)rev
                                     rootPatternId:(NSUInteger)rootPatternId
                                     resultHandler:(void (^)(NSDictionary *, TXLMovingObjectSequence *))handler;

- (BOOL)evaluateFilterWithVariables:(NSDictionary *)vars
                      rootPatternId:(NSUInteger)rootPatternId;

- (BOOL)_evaluatePatternWithVariables:(NSDictionary *)vars
                           inContexts:(NSArray *)ctxs
                               window:(TXLMovingObjectSequence *)mos
                          forRevision:(TXLRevision *)rev
                        rootPatternId:(NSUInteger)rootPatternId
                        resultHandler:(void(^)(NSDictionary *vars, TXLMovingObjectSequence *mos))handler;
@end


@implementation TXLGraphPattern

@synthesize primaryKey;

#pragma mark - 
#pragma mark Internal Non-Autorelease Constructor 

- (id)initWithPrimaryKey:(NSUInteger)pk { 
    if ((self = [super init])) { 
        primaryKey = pk; 
    } 
    return self; 
}

#pragma mark -
#pragma mark Database Management

+ (id)graphPatternWithPrimaryKey:(NSUInteger)pk {
    return [[[TXLGraphPattern alloc] initWithPrimaryKey:pk] autorelease];
}

- (BOOL)evaluatePatternWithVariables:(NSDictionary *)vars
                          inContexts:(NSArray *)ctxs
                              window:(TXLMovingObjectSequence *)mos
                         forRevision:(TXLRevision *)rev
                       resultHandler:(void(^)(NSDictionary *vars, TXLMovingObjectSequence *mos))handler {
     
    return [self _evaluatePatternWithVariables:vars
                                    inContexts:ctxs
                                        window:mos
                                   forRevision:rev
                                 rootPatternId:self.primaryKey
                                 resultHandler:handler];
    
}

- (BOOL)_evaluatePatternWithVariables:(NSDictionary *)vars
                           inContexts:(NSArray *)ctxs
                               window:(TXLMovingObjectSequence *)mos
                          forRevision:(TXLRevision *)rev
                        rootPatternId:(NSUInteger)rootPatternId
                        resultHandler:(void(^)(NSDictionary *vars, TXLMovingObjectSequence *mos))handler {
    
    __block BOOL success = NO;
    
    [self evaluateBasicGraphPatternWithVariables:vars
                                      inContexts:ctxs
                                         windows:mos
                                     forRevision:rev
                                   rootPatternId:rootPatternId
                                   resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                       
                                       [self evaluateNotExistsGraphPatternWithVariables:vars
                                                                             inContexts:ctxs
                                                                                windows:mos
                                                                            forRevision:rev
                                                                          rootPatternId:rootPatternId
                                                                          resultHandler:^(NSDictionary *vars, TXLMovingObjectSequence *mos) {
                                                                              
                                                                              if ([self evaluateFilterWithVariables:vars
                                                                                                      rootPatternId:rootPatternId]) {
                                                                                  success = YES;
                                                                                  handler(vars, mos);
                                                                              }
                                                                              
                                                                          }];
                                   }];
    
    return success;
}

#pragma mark -
#pragma mark Internal Evaluation

- (void)evaluateBasicGraphPatternWithVariables:(NSDictionary *)vars
                                    inContexts:(NSArray *)ctxs
                                       windows:(TXLMovingObjectSequence *)mos
                                   forRevision:(TXLRevision *)rev
                                 rootPatternId:(NSUInteger)rootPatternId
                                 resultHandler:(void(^)(NSDictionary *vars, TXLMovingObjectSequence *mos))handler {
    
    // evaluate basic graph pattern (a set of sequential triple patterns) contained in this query graph pattern
    // stepwise in sequence. For every composing variable match, where
    // all variables contained in these basic graph pattern are bound,
    // call the result handler with the match.
    
    // --------------------------------------------------------------------
    // retrieve all basic graph pattern
    // --------------------------------------------------------------------
    
    NSError *error;
    
    TXLDatabase *database = [[TXLManager sharedManager] database];   
    NSArray *result = [database executeSQLWithParameters:@"\
                       SELECT \
                       id, \
                       subject_id, \
                       subject_var_id, \
                       predicate_id, \
                       predicate_var_id, \
                       object_id, \
                       object_var_id \
                       FROM \
                       txl_query_pattern_triple \
                       WHERE \
                       in_pattern_id = ?"
                                                   error:&error,
                       [TXLInteger integerWithValue:[self primaryKey]], nil];
    
    if (result == nil) {
        
        [NSException raise:@"TXLGraphPatternException" format:@"Could not retrieve basic graph patterns of pattern (%d): %@", primaryKey, [error localizedDescription]];
        
    } else {
        
        // --------------------------------------------------------------------
        // function for evaluating pattern <i>
        // of a sequence (pattern 1.pattern 2.pattern 3. ... .pattern n.)
        // of basic graph patterns dependent on there predecessors 
        // --------------------------------------------------------------------
        
        __block void (^evaluateBasicGraphPattern)(NSUInteger, 
                                                  NSDictionary*, 
                                                  TXLMovingObjectSequence*);
        evaluateBasicGraphPattern = ^(NSUInteger i, 
                                      NSDictionary *variables,
                                      TXLMovingObjectSequence *windows) {
            
            NSAutoreleasePool *pool = [NSAutoreleasePool new];
            
            NSDictionary *pattern = [result objectAtIndex:i];
            
            // start building the SQL expression consisting of a sql string
            // and the corresponding parameters for evaluating
            // the pattern by querying the database
            
            // OPTIMIZE: Try to build a resusable SQL expression (Compilation of SQL expressions is expensive).
            
            NSMutableString *sql = [NSMutableString stringWithString:@"SELECT st.id, st.mo_id"];
            NSMutableArray *sqlParams = [NSMutableArray array];
            
            // --------------------------------------------------------------------        
            // consider variables if set 
            //
            // The current implementation treats blank nodes equal to variables
            // in any sense
            // --------------------------------------------------------------------
            
            TXLInteger *subjectVarId = [pattern objectForKey:@"subject_var_id"];
            if ([subjectVarId integerValue] != 0) {
                
                if (![[variables allKeys] containsObject:subjectVarId]) {
                    // currently the variable is not bound to a value
                    // so there is still a free choice of finding
                    // an appropriate match
                    [sql appendString:@",st.subject_id"];
                }
            }
            
            TXLInteger *predicateVarId = [pattern objectForKey:@"predicate_var_id"];
            if ([predicateVarId integerValue] != 0) {
                
                if (![[variables allKeys] containsObject:predicateVarId]) {
                    // currently the variable is not bound to a value
                    // so there is still a free choice of finding
                    // an appropriate match
                    [sql appendString:@",st.predicate_id"];
                }
            }
            
            TXLInteger *objectVarId = [pattern objectForKey:@"object_var_id"];
            if ([objectVarId integerValue] != 0) {
                
                if (![[variables allKeys] containsObject:objectVarId]) {
                    // currently the variable is not bound to a value
                    // so there is still a free choice of finding
                    // an appropriate match
                    [sql appendString:@",st.object_id"];
                }
            }
            
            // --------------------------------------------------------------------
            // consider revision
            // --------------------------------------------------------------------
            
            [sql appendString:@" \
             FROM txl_statement as st \
             INNER JOIN txl_statement_created as cr ON (st.id = cr.statement_id AND cr.revision_id <= ?) \
             LEFT JOIN txl_statement_removed as rm ON (st.id = rm.statement_id) "];
            [sqlParams addObject:[TXLInteger integerWithValue:[rev primaryKey]]];
            
            
            [sql appendString:@"INNER JOIN txl_context as ctx ON (st.context_id = ctx.id) "];
            
            [sql appendString:@" \
             WHERE (rm.revision_id ISNULL OR rm.revision_id > ?)"];
            [sqlParams addObject:[TXLInteger integerWithValue:[rev primaryKey]]];
            
            // --------------------------------------------------------------------
            // consider contexts
            // --------------------------------------------------------------------
            
            [sql appendString:@" AND ("];
            
            BOOL first = YES;
            for (TXLContext *ctx in ctxs) {
                
                if (!first) {
                    [sql appendString:@" OR"];
                } else {
                    first = NO;
                }
                
                [sql appendFormat:@" (ctx.name glob '%@*')", [ctx description]];
            }
            
            [sql appendString:@")"];
            
            
            // --------------------------------------------------------------------
            // consider terms if the corresponding
            // variables are not set or are bound
            // --------------------------------------------------------------------
            
            subjectVarId = [pattern objectForKey:@"subject_var_id"];
            if ([subjectVarId integerValue] != 0) {
                
                TXLInteger *value = [variables objectForKey:subjectVarId];
                
                if (value != nil) {
                    // currently the variable is bound to a value
                    [sql appendString:@" AND st.subject_id=?"];
                    [sqlParams addObject:value];
                }
            } else {
                // variable is not set so use the term
                [sql appendString:@" AND st.subject_id=?"];
                [sqlParams addObject:[pattern objectForKey:@"subject_id"]];
            }
            
            predicateVarId = [pattern objectForKey:@"predicate_var_id"];
            if ([predicateVarId integerValue] != 0) {
                
                TXLInteger *value = [variables objectForKey:predicateVarId];
                
                if (value != nil) {
                    // currently the variable is bound to a value
                    [sql appendString:@" AND st.predicate_id=?"];
                    [sqlParams addObject:value];
                }
            } else {
                // variable is not set so use the term
                [sql appendString:@" AND st.predicate_id=?"];
                [sqlParams addObject:[pattern objectForKey:@"predicate_id"]];
            }
            
            objectVarId = [pattern objectForKey:@"object_var_id"];
            if ([objectVarId integerValue] != 0) {
                
                TXLInteger *value = [variables objectForKey:objectVarId];
                
                if (value != nil) {
                    // currently the variable is bound to a value
                    [sql appendString:@" AND st.object_id=?"];
                    [sqlParams addObject:value];
                }
            } else {
                // variable is not set so use the term
                [sql appendString:@" AND st.object_id=?"];
                [sqlParams addObject:[pattern objectForKey:@"object_id"]];
            }
            
            // --------------------------------------------------------------------
            // evaluate basic graph pattern by querying the database
            // using the formerly created SQL expression
            // --------------------------------------------------------------------
            
            NSError *error;
            
            TXLDatabase *database = [[TXLManager sharedManager] database];   
            BOOL success = [database executeSQL:sql
                                 withParameters:sqlParams
                                          error:&error
                                  resultHandler:^(NSDictionary *row, BOOL *stop) {
                                      
                                      // --------------------------------------------------------------------
                                      // consider window constraint
                                      // --------------------------------------------------------------------
                                      
                                      TXLMovingObjectSequence *newWindows = nil;
                                      
                                      NSUInteger movingObjectPk = [[row objectForKey:@"mo_id"] intValue];
                                      
                                      if (movingObjectPk != 0) {
                                          // moving object for this statement is defined.
                                          // take the moving object defined for this statement
                                          TXLMovingObject *movingObject = [TXLMovingObject movingObjectWithPrimaryKey:movingObjectPk];
                                          
                                          if (windows != nil) {
                                              // given windows are defined, so intersect the given
                                              // windows with the moving object defined for this
                                              // statement
                                              newWindows = [windows intersectionWithMovingObject:movingObject];
                                              
                                              if ([newWindows isEmpty]) {
                                                  
                                                  // no intersections where found,
                                                  // so the result obtained is not valid
                                                  // so track back one step
                                                  
                                                  return;
                                              }
                                          } else {
                                              // given windows are not defined, so we assume validity
                                              // always everywhere.
                                              // the intersection of a moving object A, that is valid
                                              // always everywhere and a moving object B is moving
                                              // object B, so form a sequence with one moving object B
                                              // as element, since moving object B is defined
                                              newWindows = [TXLMovingObjectSequence sequenceWithMovingObject:movingObject];                                              
                                          }
                                          
                                      } else {
                                          // no moving object defined for this statement, so
                                          // the statement is valid always everywhere.
                                          // take the given windows, since the intersection of
                                          // something that is valid always everywhere and something
                                          // else is something else.
                                          newWindows = windows;
                                      }
                                      
                                      // --------------------------------------------------------------------
                                      // copy vars
                                      // --------------------------------------------------------------------
                                      
                                      // copy var dictionary so there is
                                      // no confusion in the backtracking
                                      // process
                                      NSMutableDictionary *tmpVars = [NSMutableDictionary dictionaryWithDictionary:variables];
                                      
                                      // fill vars
                                      for (NSString *key in [row allKeys]) {
                                          if ([key isEqual:@"subject_id"]) {
                                              [tmpVars setObject:[row objectForKey:@"subject_id"]
                                                          forKey:[pattern objectForKey:@"subject_var_id"]];
                                          }
                                          if ([key isEqual:@"predicate_id"]) {
                                              [tmpVars setObject:[row objectForKey:@"predicate_id"]
                                                          forKey:[pattern objectForKey:@"predicate_var_id"]];
                                          }
                                          if ([key isEqual:@"object_id"]) {
                                              [tmpVars setObject:[row objectForKey:@"object_id"]
                                                          forKey:[pattern objectForKey:@"object_var_id"]];
                                          }
                                      }
                                      
                                      if (i == [result count] - 1) {
                                          // the mapping is complete -
                                          // all basic graph pattern
                                          // are evaluated so all corresponding
                                          // variables are bound -
                                          // so call the result handler
                                          handler(tmpVars, newWindows);
                                      } else {
                                          // evaluate the next basic graph pattern
                                          evaluateBasicGraphPattern(i + 1, 
                                                                    tmpVars, 
                                                                    newWindows);
                                      }
                                  }];
            
            if (!success) {
                
                [NSException raise:@"TXLGraphPatternException" format:@"Could not evaluate basic graph pattern (%d) in graph pattern (%d): %@", [[pattern objectForKey:@"id"] intValue], [self primaryKey], [error localizedDescription]];
                
            }
            
            [pool drain];
        };
        
        // --------------------------------------------------------------------
        
        if ([result count] > 0) {
            // min. one basic graph pattern exists,
            // so try to evaluate all available
            // basic graph pattern stepwise by forming the
            // stepwise conjunction of them to find
            // suitable matches for the variables contained
            // beginning with the first basic graph pattern
            evaluateBasicGraphPattern(0, 
                                      vars, 
                                      mos);
        } else {
            // no basic graph pattern defined, this
            // will be interpreted as always TRUE resp.
            // that there is no constraint defined, so
            // retrieve all available results
            
            // OPTIMIZE: Try to build a resusable SQL expression (Compilation of SQL expressions is expensive).
            
            NSMutableString *sql = [NSMutableString stringWithString:@"SELECT st.id, st.mo_id"];
            NSMutableArray *sqlParams = [NSMutableArray array];
            
            
            
            // --------------------------------------------------------------------
            // consider revision
            // --------------------------------------------------------------------
            
            [sql appendString:@" \
             FROM txl_statement as st \
             INNER JOIN txl_statement_created as cr ON (st.id = cr.statement_id AND cr.revision_id <= ?) \
             LEFT JOIN txl_statement_removed as rm ON (st.id = rm.statement_id) "];
            [sqlParams addObject:[TXLInteger integerWithValue:[rev primaryKey]]];
            
            
            [sql appendString:@"INNER JOIN txl_context as ctx ON (st.context_id = ctx.id) "];
            
            [sql appendString:@" \
             WHERE (rm.revision_id ISNULL OR rm.revision_id > ?)"];
            [sqlParams addObject:[TXLInteger integerWithValue:[rev primaryKey]]];
            
            // --------------------------------------------------------------------
            // consider contexts
            // --------------------------------------------------------------------
            
            [sql appendString:@" AND ("];
            
            BOOL first = YES;
            for (TXLContext *ctx in ctxs) {
                
                if (!first) {
                    [sql appendString:@" OR"];
                } else {
                    first = NO;
                }
                
                [sql appendFormat:@" (ctx.name glob '%@*')", [ctx description]];
            }
            
            [sql appendString:@")"];
            
            TXLDatabase *database = [[TXLManager sharedManager] database];   
            BOOL success = [database executeSQL:sql
                                 withParameters:sqlParams
                                          error:&error
                                  resultHandler:^(NSDictionary *row, BOOL *stop) {
                                      
                                      // --------------------------------------------------------------------
                                      // consider window constraint
                                      // --------------------------------------------------------------------
                                      
                                      TXLMovingObjectSequence *newWindows = nil;
                                      
                                      NSUInteger movingObjectPk = [[row objectForKey:@"mo_id"] intValue];
                                      
                                      if (movingObjectPk != 0) {
                                          // moving object for this statement is defined.
                                          // take the moving object defined for this statement
                                          TXLMovingObject *movingObject = [TXLMovingObject movingObjectWithPrimaryKey:movingObjectPk];
                                          
                                          if (mos != nil) {
                                              // given windows are defined, so intersect the given
                                              // windows with the moving object defined for this
                                              // statement
                                              newWindows = [mos intersectionWithMovingObject:movingObject];
                                              
                                              if ([newWindows isEmpty]) {
                                                  
                                                  // no intersections where found,
                                                  // so the result obtained is not valid
                                                  // so track back one step
                                                  
                                                  return;
                                              }
                                          } else {
                                              // given windows are not defined, so we assume validity
                                              // always everywhere.
                                              // the intersection of a moving object A, that is valid
                                              // always everywhere and a moving object B is moving
                                              // object B, so form a sequence with one moving object B
                                              // as element, and for moving object B it is guarenteed that
                                              // it is defined, since moving object B is the moving object
                                              // of this statement
                                              newWindows = [TXLMovingObjectSequence sequenceWithMovingObject:movingObject];                                              
                                          }
                                          
                                      } else {
                                          // no moving object defined for this statement, so
                                          // the statement is valid always everywhere.
                                          // take the given windows, since the intersection of
                                          // something that is valid always everywhere and something
                                          // else is something else.
                                          newWindows = mos;
                                      }
                                      
                                      handler(vars, newWindows);
                                      
                                  }];
            
            if (!success) {
                
                [NSException raise:@"TXLGraphPatternException" format:@"Could not evaluate graph pattern (%d): %@", [self primaryKey], [error localizedDescription]];
                
            }
            
        }            
        
    }
    
}

- (void)evaluateNotExistsGraphPatternWithVariables:(NSDictionary *)vars
                                        inContexts:(NSArray *)ctxs
                                           windows:(TXLMovingObjectSequence *)mos
                                       forRevision:(TXLRevision *)rev
                                     rootPatternId:(NSUInteger)rootPatternId
                                     resultHandler:(void(^)(NSDictionary *vars, TXLMovingObjectSequence *mos))handler {
    // evaluate all not exists graph patterns contained in this query graph pattern
    // stepwise in sequence. If there is a match found then track back
    
    // --------------------------------------------------------------------
    // retrieve all not exists graph pattern
    // --------------------------------------------------------------------
    
    NSError *error;
    
    TXLDatabase *database = [[TXLManager sharedManager] database];   
    NSArray *result = [database executeSQLWithParameters:@"\
                       SELECT \
                       pattern_id \
                       FROM \
                       txl_query_pattern_not_exists \
                       WHERE \
                       in_pattern_id = ?"
                                                   error:&error, 
                       [TXLInteger integerWithValue:[self primaryKey]], nil];
    
    if (result == nil) {
        
        [NSException raise:@"TXLGraphPatternException" format:@"Could not retrieve not exists graph patterns of pattern (%d): %@", primaryKey, [error localizedDescription]];
        
    } else {
        
        
        
        // --------------------------------------------------------------------
        // function for evaluating pattern <i>
        // of a sequence ({...} {...} {...} ... {...})
        // of not exists graph patterns independent on there predecessors 
        // --------------------------------------------------------------------
//        
//        __block void (^evaluateNotExistsGraphPattern)(NSUInteger);
//        evaluateNotExistsGraphPattern = ^(NSUInteger i) {
//            
//            TXLGraphPattern *pattern = [TXLGraphPattern graphPatternWithPrimaryKey:[[[result objectAtIndex:i] objectForKey:@"pattern_id"] intValue]];
//            
//            [pattern evaluatePatternWithVariables:vars inContexts:ctxs window:windows forRevision:rev resultHandler:^(NSDictionary *varsEval, TXLMovingObjectSequence *mosEval) {
//                
//                // --------------------------------------------------------------------
//                // consider window constraint
//                //
//                // form the difference between the given moving object sequence and
//                // moving object sequence retrieved by the result, since the retrieved
//                // result represents the result of the not exists pattern, which we want
//                // to have withdrawed from the final result
//                // --------------------------------------------------------------------
//                
//                if (mosEval == nil) {
//                    
//                    // since mosEval is nil, the match for the not exists pattern
//                    // is valid always everywhere, so the difference is always empty
//                    windows = [TXLMovingObjectSequence emptySequence];
//                    
//                } else {
//                    
//                    if (windows != nil) {
//                        
//                        // form the difference of the given windows
//                        // and the windows obtained for the match of the
//                        // not exists pattern
//                        windows = [windows complementWithMovingObjectSequnece:mosEval];
//                        
//                    } else {
//                        
//                        // since windows is nil, they are valid always everywhere.
//                        // so form the difference of something that is valid always
//                        // everywhere and the windows that are defined by the
//                        // match of the not exists pattern
//                        
//                        windows = [[TXLMovingObjectSequence sequenceWithMovingObject:
//                                    [TXLMovingObject movingObjectWithBegin:nil end:nil]]
//                                   complementWithMovingObjectSequnece:mosEval];
//                    }
//                }
//                //[windows retain];
//            }];
//            //[windows autorelease];
//        };
//        
        // --------------------------------------------------------------------
        
        __block TXLMovingObjectSequence *windows = mos;
        if (mos == nil) {
            windows = [TXLMovingObjectSequence sequenceWithMovingObject:[TXLMovingObject omnipresentMovingObject]];
        }
        [windows retain];
        
        for (NSUInteger i = 0; i < [result count]; i++) {
            // min. one not exists graph pattern exists,
            // so try to evaluate all available
            // not exists graph pattern stepwise
            //
            // if one not exists graph pattern find
            // a match then track back
            
            
            TXLGraphPattern *pattern = [TXLGraphPattern graphPatternWithPrimaryKey:[[[result objectAtIndex:i] objectForKey:@"pattern_id"] intValue]];
            
            [pattern _evaluatePatternWithVariables:vars
                                        inContexts:ctxs
                                            window:windows
                                       forRevision:rev
                                     rootPatternId:rootPatternId
                                     resultHandler:^(NSDictionary *varsEval, TXLMovingObjectSequence *mosEval) {
                
                                        // --------------------------------------------------------------------
                                        // consider window constraint
                                        //
                                        // form the difference between the given moving object sequence and
                                        // moving object sequence retrieved by the result, since the retrieved
                                        // result represents the result of the not exists pattern, which we want
                                        // to have withdrawed from the final result
                                        // --------------------------------------------------------------------
                                        if (mosEval != nil) {
                                            if (windows) {
                                                TXLMovingObjectSequence *w = [windows complementWithMovingObjectSequnece:mosEval];
                                                [windows release];
                                                windows = [w retain];
                                            } else {
                                                TXLMovingObjectSequence *w = [windows complementWithMovingObjectSequnece:mosEval];
                                                [windows release];
                                                windows = [w retain];
                                            }
                                        }
            }];
            
            if ([windows isEmpty]) {
                [windows release];
                return;
            }
        }
        
        handler(vars, windows);
        [windows release];
    }
}

- (BOOL)evaluateFilterWithVariables:(NSDictionary *)vars 
                      rootPatternId:(NSUInteger)rootPatternId{
    return YES;
}

@end


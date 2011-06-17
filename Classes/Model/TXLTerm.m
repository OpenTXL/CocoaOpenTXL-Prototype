//
//  TXLTerm.m
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

#import "TXLTerm.h"
#import "TXLManager.h"
#import "TXLDatabase.h"
#import "TXLInteger.h"
#import "NSString+UUID.h"
#import <spatialite/sqlite3.h>

@interface TXLTerm ()
- (id)initWithString:(NSString *)value;
- (id)initWithPrimaryKey:(NSUInteger)pk;
- (id)initWithType:(kTXLTermType)t
             value:(id)v
              meta:(id)m;

@property (readonly) kTXLTermType termType;
@property (readonly) id termValue;
@property (readonly) id termMeta;

- (void)load;

@end


@implementation TXLTerm

@synthesize primaryKey;

#pragma mark -
#pragma mark Public Constructors

+ (TXLTerm *)termWithString:(NSString *)value {
    NSAssert(nil, @"Not Implemented!");
    return nil;
}

+ (TXLTerm *)termWithIRI:(NSString *)iri {
    return [[[self alloc] initWithType:kTXLTermTypeIRI
                                 value:iri
                                  meta:nil] autorelease];
}

+ (TXLTerm *)termWithBlankNode:(NSString *)blankNode {
    if (blankNode == nil) {
        return [[[self alloc] initWithType:kTXLTermTypeBlankNode
                                     value:[NSString stringWithUUID]
                                      meta:nil] autorelease];
    } else {
        return [[[self alloc] initWithType:kTXLTermTypeBlankNode
                                     value:blankNode
                                      meta:nil] autorelease];
    }
}

+ (TXLTerm *)termWithLiteral:(NSString *)lit {
    return [[[self alloc] initWithType:kTXLTermTypePlainLiteral
                                 value:lit
                                  meta:nil] autorelease];
}

+ (TXLTerm *)termWithLiteral:(NSString *)lit
             language:(NSString *)lang {
    return [[[self alloc] initWithType:kTXLTermTypePlainLiteral
                                 value:lit
                                  meta:lang] autorelease];
}

+ (TXLTerm *)termWithLiteral:(NSString *)lit
             dataType:(TXLTerm *)dt {
    
    if ([dt isEqual:[TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#integer"]]) {
        NSInteger i = [lit integerValue];
        return [self termWithInteger:i];
    } else if ([dt isEqual:[TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#double"]]) {
        return [self termWithDouble:[lit doubleValue]];
    } else if ([dt isEqual:[TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#boolean"]]) {
        if ([[lit lowercaseString] isEqual:@"true"]) {
            return [self termWithBool:YES];
        } else if ([[lit lowercaseString] isEqual:@"false"]) {
            return [self termWithBool:NO];
        } else {
            return nil;
        }
    } else if ([dt isEqual:[TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#dateTime"]]) {
        // TODO: Write a parser for ISO 8601 date time formats.
        NSLog(@"Not Implemented: Initialize a TXLTerm of type date time is not possible with the general constructor.");
        return nil;
    } else {
        return [[[self alloc] initWithType:kTXLTermTypeTypedLiteral
                                     value:lit
                                      meta:dt] autorelease];
    }
}

+ (TXLTerm *)termWithBool:(BOOL)val {
    return [[[self alloc] initWithType:kTXLTermTypeBooleanLiteral
                                 value:[NSNumber numberWithBool:val]
                                  meta:nil] autorelease];
}

+ (TXLTerm *)termWithInteger:(NSInteger)integer {
    return [[[self alloc] initWithType:kTXLTermTypeIntegerLiteral
                                 value:[NSNumber numberWithInteger:integer]
                                  meta:nil] autorelease];
}

+ (TXLTerm *)termWithDouble:(double)dbl {
    return [[[self alloc] initWithType:kTXLTermTypeDoubleLiteral
                                 value:[NSNumber numberWithDouble:dbl]
                                  meta:nil] autorelease];
}

+ (TXLTerm *)termWithDate:(NSDate *)dt {
    return [[[self alloc] initWithType:kTXLTermTypeDateTimeLiteral
                                 value:dt
                                  meta:nil] autorelease];
}

#pragma mark -
#pragma mark Comparison

- (BOOL)isEqual:(id)object {
    
    // OPTIMIZE
    
    if ([object isKindOfClass:[TXLTerm class]]) {
        
        TXLTerm *other = object;
        
        if (self.savedInDatabase && other.savedInDatabase) {
            return self.primaryKey == other.primaryKey;
        }
        
        if (self.termType != other.termType)
            return NO;
        
        switch (self.termType) {
            case kTXLTermTypeDateTimeLiteral:
                if ([self.termValue compare:other.termValue] == NSOrderedSame)
                    return YES; 
                
            default:
                if (![self.termValue isEqual:other.termValue])
                    return NO;
        }
        
        if (!((self.termMeta == nil && other.termMeta == nil) || [self.termMeta isEqual:other.termMeta]))
            return NO;
        
        return YES;
        
    } else {
        return NO;
    }
}

#pragma mark -
#pragma mark Accessors

- (NSString *)description {
    switch (self.termType) {
        case kTXLTermTypeBlankNode:
            return [NSString stringWithFormat:@"_:%@", self.termValue];
            
        case kTXLTermTypeIRI:
            return [NSString stringWithFormat:@"<%@>", self.termValue];
            
        case kTXLTermTypePlainLiteral:
            if (self.termMeta == nil) {
                return [NSString stringWithFormat:@"\"%@\"", self.termValue];
            } else {
                return [NSString stringWithFormat:@"\"%@\"@%@", self.termValue, self.termMeta];
            }
        
        case kTXLTermTypeTypedLiteral:
            return [NSString stringWithFormat:@"\"%@\"^^%@", self.termValue, self.termMeta];
            
        case kTXLTermTypeIntegerLiteral:
            return [self.termValue stringValue];
            
        case kTXLTermTypeDoubleLiteral:
            return [NSString stringWithFormat:@"%e", [self.termValue doubleValue]];
            
        case kTXLTermTypeBooleanLiteral:
            if ([self.termValue boolValue]) {
                return @"true";
            } else {
                return @"false";
            }
            
        case kTXLTermTypeDateTimeLiteral:
            // TODO: Create a string representing the date time in ISO 8601.
            return [self.termValue description];
            
        default:
            return nil;
    }
}

- (BOOL)isType:(kTXLTermType)t {
    return t == self.termType;
}

- (kTXLTermType)type {
    return self.termType;
}

- (NSString *)iriValue {
    if (self.termType == kTXLTermTypeIRI) {
        return self.termValue;
    } else {
        return nil;
    }
}

- (NSString *)blankNodeValue {
    if (self.termType == kTXLTermTypeBlankNode) {
        return self.termValue;
    } else {
        return nil;
    }
}

- (NSString *)literalValue {
    switch (self.termType) {
            
        case kTXLTermTypePlainLiteral:
            return self.termValue;
            
        case kTXLTermTypeTypedLiteral:
            return self.termValue;
            
        case kTXLTermTypeIntegerLiteral:
            return [self.termValue stringValue];
            
        case kTXLTermTypeDoubleLiteral:
            return [NSString stringWithFormat:@"%e", [self.termValue doubleValue]];
            
        case kTXLTermTypeBooleanLiteral:
            if ([self.termValue boolValue]) {
                return @"true";
            } else {
                return @"false";
            }
            
        case kTXLTermTypeDateTimeLiteral:
            // TODO: Create a string representing the date time in ISO 8601.
            return [self.termValue description];
            
        default:
            return nil;
    }
}

- (BOOL)booleanValue {
    if (self.termType == kTXLTermTypeBooleanLiteral) {
        return [self.termValue boolValue];
    } else {
        return NO;
    }
}

- (NSNumber *)numberValue {
    switch (self.termType) {
        case kTXLTermTypeIntegerLiteral:
        case kTXLTermTypeDoubleLiteral:
            return self.termValue;
            
        default:
            return nil;
    }
}

- (NSDate *)dateValue {
    if (self.termType == kTXLTermTypeDateTimeLiteral) {
        return self.termValue;
    } else {
        return nil;
    }
}

- (NSString *)language {
    if (self.termType == kTXLTermTypePlainLiteral) {
        return self.termMeta;
    } else {
        return nil;
    }
}

- (TXLTerm *)dataType {
    switch (self.termType) {
        case kTXLTermTypeTypedLiteral:
            return self.termMeta;
            
        case kTXLTermTypeIntegerLiteral:
            return [TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#integer"];
            
        case kTXLTermTypeDoubleLiteral:
            return [TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#double"];
            
        case kTXLTermTypeBooleanLiteral:
            return [TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#boolean"];
            
        case kTXLTermTypeDateTimeLiteral:
            return [TXLTerm termWithIRI:@"http://www.w3.org/2001/XMLSchema#dateTime"];
            
        default:
            return nil;
    }
}

#pragma mark -
#pragma mark Internal Constructor & Destructor

- (id)initWithType:(kTXLTermType)t
             value:(id)v
              meta:(id)m {
    if ((self = [super init])) {
        primaryKey = 0;
        termType = t;
        termValue = [v retain];
        termMeta = [m retain];
    }
    return self;
}

- (id)initWithString:(NSString *)v {
    if ((self = [super init])) {
        termType = kTXLTermTypeTerm;
        termValue = [v retain];
        primaryKey = 0;
    }
    return self;
}

- (void)dealloc { 
    [termValue release];
    [termMeta release];
    [super dealloc];
}

#pragma mark -
#pragma mark Internal Accessors

- (kTXLTermType)termType {
    [self load];
    return termType;
}

- (id)termValue {
    [self load];
    return termValue;
}

- (id)termMeta {
    [self load];
    return termMeta;
}

#pragma mark -
#pragma mark Database Management

+ (id)termWithPrimaryKey:(NSUInteger)pk {
    return [[[self alloc] initWithPrimaryKey:pk] autorelease];
}

- (id)initWithPrimaryKey:(NSUInteger)pk {
    if ((self = [super init])) {
        primaryKey = pk;
    }
    return self;
}

- (BOOL)isSavedInDatabase {
    return primaryKey;
}

- (TXLTerm *)save:(NSError **)error {
    
    @synchronized (self) {
        if (self.primaryKey == 0) {
            
            TXLDatabase *database = [[TXLManager sharedManager] database];
            
            NSArray *parameters = nil;
            
            switch (termType) {
                    
                case kTXLTermTypeBlankNode:
                case kTXLTermTypeIRI:
                case kTXLTermTypeDoubleLiteral:
                    parameters = [NSArray arrayWithObjects:[TXLInteger integerWithValue:termType], termValue, [TXLInteger integerWithValue:0], nil];
                    break;
                    
                case kTXLTermTypePlainLiteral:
                    if (termMeta == nil) {
                        parameters = [NSArray arrayWithObjects:[TXLInteger integerWithValue:termType], termValue, [TXLInteger integerWithValue:0], nil];
                    } else {
                        parameters = [NSArray arrayWithObjects:[TXLInteger integerWithValue:termType], termValue, termMeta, nil];
                    }
                    break;
                    
                case kTXLTermTypeTypedLiteral:
                {
                    TXLTerm *dt = termMeta;
                    if ([dt save:error] == nil) {
                        return nil;
                    }
                    parameters = [NSArray arrayWithObjects:[TXLInteger integerWithValue:termType], termValue, [TXLInteger integerWithValue:dt.primaryKey], nil];
                    break;
                }
                    
                case kTXLTermTypeIntegerLiteral:
                case kTXLTermTypeBooleanLiteral:
                    parameters = [NSArray arrayWithObjects:[TXLInteger integerWithValue:termType], [TXLInteger integerWithValue:[termValue integerValue]], [TXLInteger integerWithValue:0], nil];
                    break;
                    
                case kTXLTermTypeDateTimeLiteral:
                {
                    NSDate *date = termValue;
                    parameters = [NSArray arrayWithObjects:[TXLInteger integerWithValue:termType], [NSNumber numberWithDouble:[date timeIntervalSinceReferenceDate]], [TXLInteger integerWithValue:0], nil];
                    break;
                }
                                    
                default:
                    break;
            }
            
            NSArray *result = [database executeSQL:@"INSERT INTO txl_term (type, value, meta) VALUES (?, ?, ?)"
                                    withParameters:parameters
                                             error:error];
            
            if (result == nil) {
                if ([[*error domain] isEqual:SQLiteErrorDomain]) {
                    switch ([*error code]) {
                        case SQLITE_CONSTRAINT:
                        {
                            // Term is already stored in the database; fetch the primary key of that term
                            result = [database executeSQL:@"SELECT id FROM txl_term WHERE type = ? AND value = ? AND meta = ?"
                                           withParameters:parameters
                                                    error:error];
                            if (result == nil) {
                                NSLog(@"Could not get primary key for existing term (%@): %@", self, [*error localizedDescription]);
                                return nil;
                            } else {
                                primaryKey = [[[result objectAtIndex:0] objectForKey:@"id"] integerValue];
                            }
                        }
                            break;
                            
                        default:
                            NSLog(@"Could not save term (%@): %@", self, [*error localizedDescription]);
                            return nil;
                            break;
                    }
                } else {
                    NSLog(@"Could not save term (%@): %@", self, [*error localizedDescription]);
                    return nil;
                }
            } else {
                primaryKey = database.lastInsertRowid;
            }
        }
    }
    
    return self;
}

- (void)load {
    @synchronized (self) {
        if (primaryKey != 0 && termType == 0) {
            TXLDatabase *database = [[TXLManager sharedManager] database];
            
            NSError *error;
            NSArray *result;
            
            result = [database executeSQLWithParameters:@"SELECT type, value, meta FROM txl_term WHERE id = ?"
                                                  error:&error, [TXLInteger integerWithValue:primaryKey], nil];
            
            if (result == nil) {
                [NSException exceptionWithName:@"TXLTermException"
                                        reason:[error localizedDescription]
                                      userInfo:nil];
                    NSLog(@"Could not values of term (%lu): %@", primaryKey, [error localizedDescription]);
            } else {
                
                termType = [[[result objectAtIndex:0] objectForKey:@"type"] integerValue];
                id _v = [[result objectAtIndex:0] objectForKey:@"value"];
                id _m = [[result objectAtIndex:0] objectForKey:@"meta"];
                
                switch (termType) {
                    case kTXLTermTypeBlankNode:
                    case kTXLTermTypeIRI:
                    case kTXLTermTypeDoubleLiteral:
                        termValue = [_v retain];
                        termMeta = nil;
                        break;
                        
                    case kTXLTermTypePlainLiteral:
                        termValue = [_v retain];
                        if ([_m isKindOfClass:[NSString class]]) {
                            termMeta = [_m retain];
                        } else {
                            termMeta = nil;
                        }
                        break;
                        
                    case kTXLTermTypeTypedLiteral:
                        termValue = [_v retain]; 
                        termMeta = [[TXLTerm termWithPrimaryKey:[_m integerValue]] retain];
                        break;
                        
                    case kTXLTermTypeIntegerLiteral:
                    case kTXLTermTypeBooleanLiteral:
                        termValue = [[NSNumber numberWithInteger:[_v integerValue]] retain];
                        termMeta = nil;
                        break;
                        
                    case kTXLTermTypeDateTimeLiteral:
                        termValue = [[NSDate dateWithTimeIntervalSinceReferenceDate:[_v doubleValue]] retain];
                        termMeta = nil;
                        break;
                        
                    default:
                        break;
                }
            }
        }
    }
}

@end

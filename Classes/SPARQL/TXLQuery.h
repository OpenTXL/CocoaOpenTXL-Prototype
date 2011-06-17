//
//  TXLQuery.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 18.10.10.
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


@class TXLGraphPattern;
@class TXLContext;

@interface TXLQuery : NSObject {
	
@private
    NSUInteger primaryKey;
}

@property (readonly, getter=isConstructQuery) BOOL constructQuery;

#pragma mark -
#pragma mark Query Pattern

@property (readonly) TXLGraphPattern *queryPattern;

#pragma mark -
#pragma mark Variables

@property (readonly) NSArray *variablesOfResultset;

#pragma mark -
#pragma mark Blank Nodes Variables (applies to contruct queries)

@property (readonly) NSArray *blankNodeVariablesOfResultset;

#pragma mark -
#pragma mark Expression

@property (readonly) NSString *expression;

#pragma mark -
#pragma mark Context

+ (NSArray *)queriesForContexts:(NSSet *)ctx error:(NSError **)error;
+ (NSArray *)queriesForContext:(TXLContext *)ctx error:(NSError **)error;

@property (readonly) NSArray *contexts;

#pragma mark -
#pragma mark Database Management

+ (id)queryWithPrimaryKey:(NSUInteger)pk;

@property (readonly) NSUInteger primaryKey;

@end


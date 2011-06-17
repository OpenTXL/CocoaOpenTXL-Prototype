//
//  TXLQueryHandle.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 08.10.10.
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

@class TXLResultSet;
@class TXLRevision;
@class TXLQueryHandle;

@class TXLQuery;

@protocol TXLContinuousQueryDelegateProtocol
- (void)continuousQuery:(TXLQueryHandle *)query
        hasNewResultSet:(TXLResultSet *)result
            forRevision:(TXLRevision *)revision;
@end


@interface TXLQueryHandle : NSObject {
    
@private 
    id delegate; 
    NSUInteger queryPrimaryKey;
    
    id observer;
}

#pragma mark -
#pragma mark Delegate

@property (assign) id delegate;

#pragma mark -
#pragma mark Query Expression & Parameters

@property (readonly) NSString *expression;
@property (readonly) NSDictionary *parameters;
@property (readonly) NSDictionary *options;

#pragma mark -
#pragma mark Evaluation Revisions

@property (readonly) TXLRevision *firstEvaluation;
@property (readonly) TXLRevision *lastEvaluation;

#pragma mark -
#pragma mark Result Set

- (TXLResultSet *)resultSetForRevision:(TXLRevision *)revision;

#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Database Management

@property (readonly) NSUInteger queryPrimaryKey;

#pragma mark -
#pragma mark Autorelease Constructors

+ (TXLQueryHandle *)handleForQueryWithPrimaryKey:(NSUInteger)pk;



@end

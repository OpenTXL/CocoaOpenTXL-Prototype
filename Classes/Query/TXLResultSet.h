//
//  TXLResultSet.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 11.10.10.
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
@class TXLMovingObjectSequence;
@class TXLQueryHandle;

@interface TXLResultSet : NSObject {

@private
    TXLQueryHandle *queryHandle;
    TXLRevision *revision;
}

#pragma mark -
#pragma mark Revision & Query Handler

@property (readonly) TXLRevision *revision;
@property (readonly) TXLQueryHandle *queryHandle;

#pragma mark -
#pragma mark Result

@property (readonly) NSUInteger count;
- (NSDictionary *)valuesAtIndex:(NSUInteger)idx;
- (TXLMovingObjectSequence *)movingObjectSequenceAtIndex:(NSUInteger)idx;

#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Autorelease Constructor

+ (TXLResultSet *)resultSetForQueryHandle:(TXLQueryHandle *)qh
                             withRevision:(TXLRevision *)rev;

@end

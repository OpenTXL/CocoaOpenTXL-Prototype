//
//  TXLRevision.h
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

@class TXLCoreDatabase;

@interface TXLRevision : NSObject {
    
@private
    NSDate *timestamp;
    NSUInteger primaryKey;
    NSUInteger previousPrimaryKey;
}

#pragma mark -
#pragma mark Revision Details

@property (readonly) NSDate *timestamp;

#pragma mark -
#pragma mark Transaction Timeline

@property (readonly) TXLRevision *precursor;
@property (readonly) TXLRevision *successor;

#pragma mark -
#pragma mark -
#pragma mark Private Framework Methods

#pragma mark -
#pragma mark Autorelease Constructors

+ (TXLRevision *)revisionWithPrimaryKey:(NSUInteger)pk;
+ (TXLRevision *)revisionWithPrimaryKey:(NSUInteger)pk
                              timestamp:(NSDate *)ts
                     previousPrimaryKey:(NSUInteger)ppk;

#pragma mark -
#pragma mark Database Management

@property (readonly) NSUInteger primaryKey;

@end

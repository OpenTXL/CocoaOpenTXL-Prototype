//
//  TXLDBHandle.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 13.10.10.
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
#import <spatialite/sqlite3.h>

@interface TXLDBHandle : NSObject {

@private
    sqlite3 *handle;
    NSMutableDictionary *preparedStatements;
}

- (id)initWithPath:(NSString *)path;

@property (readonly) sqlite3 *handle;

#pragma mark -
#pragma mark Prepared Statement

- (sqlite3_stmt *)dequeueReusableStatementForSQL:(NSString *)sql;
- (void)enqueueReusableStatement:(sqlite3_stmt *)st forSQL:(NSString *)sql;

@end

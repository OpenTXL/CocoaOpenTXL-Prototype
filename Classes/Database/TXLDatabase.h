//
//  TXLDatabase.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 17.09.10.
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

extern NSString * const TXLDatabaseErrorDomain;
extern NSString * const SQLiteErrorDomain;

#define TXL_DATABASE_ERROR_PARAMETER_MISSMATCH 1
#define TXL_DATABASE_ERROR_UNRECOGNIZED_OBJECT_TYPE 2


/*!
    @class TXLDatabase
 
    The class TXLDatabase is a wrapper for the library spatialite.
 
    The Type of a value in the result set of a query to the database
    is calculated as follows:
 
        - If the type for a column is specified, the value is converted
          to that type. The rules of conversion are in the documentation of
          SQLite. http://www.sqlite.org/datatype3.html
 
        - If no type is specified for the column, the actual stored
        value is returned.
 
    Supported classes as Parameters in an query are:
    
        - TXLInteger (stored as INTEGER)
        - NSString (stored as TEXT)
        - NSNumber (stored as REAL)
        - NSData (stored as BLOB)
        - NSNull (stored as NULL)
 
    @abstract A wrapper for libspatialite
*/
@interface TXLDatabase : NSObject {

@private
    NSString *databasePath;
}

- (id)initWithPath:(NSString *)path;

#pragma mark -
#pragma mark Raw SQL

- (NSArray *)executeSQL:(NSString *)sql error:(NSError **)error;
- (NSArray *)executeSQL:(NSString *)sql withParameters:(NSArray *)parameters error:(NSError **)error;
- (NSArray *)executeSQLWithParameters:(NSString *)sql error:(NSError **)error, ...;

- (BOOL)executeSQL:(NSString *)sql
    withParameters:(NSArray *)parameters
             error:(NSError **)error
     resultHandler:(void(^)(NSDictionary *row, BOOL *stop))block;

#pragma mark -
#pragma mark Transactions

- (BOOL)beginTransaction:(NSError **)error;
- (BOOL)commit:(NSError **)error;
- (BOOL)rollback:(NSError **)error;

#pragma mark -
#pragma mark Tables

@property (readonly) NSArray *tables;
@property (readonly) NSArray *tableNames;

#pragma mark -
#pragma mark Misc

@property (readonly) NSUInteger lastInsertRowid;

@end

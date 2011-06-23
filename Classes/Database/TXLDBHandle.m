//
//  TXLDBHandle.m
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

#import "TXLDBHandle.h"

@interface TXLDBHandle ()
- (void)open:(NSString *)path;
- (void)finalizeStatements;
- (void)close;
- (void)raiseSQLiteException:(NSString *)errorMessage;
@end

@implementation TXLDBHandle

@synthesize handle;

- (id)initWithPath:(NSString *)path {
    if (self = [self init]) {
        [self open:path];
        preparedStatements = [NSMutableDictionary new];
        // TODO: Add an observer for memory warnings (on iOS) and release all cached statements of a warning occurs.
    }
    return self;
}

- (void)dealloc {
    [self finalizeStatements];
    [preparedStatements release];
    [self close];
    [super dealloc]; 
}

#pragma mark -
#pragma mark Prepared Statement

- (sqlite3_stmt *)dequeueReusableStatementForSQL:(NSString *)sql {
	@synchronized (preparedStatements) {

		// from prepared statements get array for
        // key (sql) and get last entry's pointer
        
		sqlite3_stmt * st = [[[preparedStatements objectForKey:sql] lastObject] pointerValue];
        
        if (st) {
            // remove last object from array for key (sql) in prepared statements disctionary, 
            // because statement will be in use
            [[preparedStatements objectForKey:sql] removeLastObject];
        }
		
		// may return nil (from lastobject) if array was empty
		return st;
	}
}

- (void)enqueueReusableStatement:(sqlite3_stmt *)st forSQL:(NSString *)sql {
    
    // reset the prepared statement object back to its
    // initial state, ready to be re-executed
    sqlite3_reset(st);
    
	@synchronized (preparedStatements) {
		if ([preparedStatements objectForKey:sql] == nil) {
			// if no array exists for this sql statement,
            // create it and add it to dictionary
			[preparedStatements setObject:[NSMutableArray array] forKey:sql];
		} 
		
		// an array within the prepared statements dictionary now exists
		// (it was either just created or existed already)
        
		// and the pointer to the statement can be added
		[[preparedStatements objectForKey:sql] addObject:[NSValue valueWithPointer:st]];
	}	
}

- (void)finalizeStatements {
    @synchronized (preparedStatements) {
        // iterate over arrays in dictionary
        for (NSMutableArray * array in [preparedStatements objectEnumerator]) {
            // iterate over statements in array
            for (NSValue * stmt in array) {
                // delete prepared statement
                sqlite3_finalize([stmt pointerValue]);
            }
        }
    }
}

#pragma mark -
#pragma mark Database Management

- (void)open:(NSString *)path {
    NSLog(@"Opening TXLDBHandle.");
    if (sqlite3_open([path UTF8String], &handle) != SQLITE_OK) {
        sqlite3_close(handle);
        [self raiseSQLiteException:@"Failed to open database with message '%'."];
    }
    sqlite3_busy_timeout(handle, 60 * 1000);
}

- (void)close {
    NSLog(@"Closing TXLDBHandle.");
    
    // release 
    
	if (sqlite3_close(handle) != SQLITE_OK) {
        [self raiseSQLiteException:@"Failed to close database with message '%'."];
    }
}

#pragma mark -
#pragma mark Exception Handling

- (void)raiseSQLiteException:(NSString *)errorMessage {
    [NSException raise:@"TXLDBHandle"
                format:errorMessage, sqlite3_errmsg(handle)];
}

@end

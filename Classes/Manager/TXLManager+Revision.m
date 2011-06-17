//
//  TXLManager+Revision.m
//  OpenTXL
//
//  Created by Tobias Kräntzer on 26.01.11.
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

#import "TXLManager+Revision.h"

#import "TXLDatabase.h"
#import "TXLInteger.h"
#import "TXLRevision.h"

@implementation TXLManager (Revision)

#pragma mark -
#pragma mark Revision

- (TXLRevision *)headRevision {
    
    NSError *error;
    NSArray *result = [self.database executeSQL:@"SELECT txl_revision.id as id, txl_revision.timestamp as timestamp, txl_revision.previous as previous FROM txl_revision, txl_revision_head WHERE txl_revision_head.id = 1 AND txl_revision_head.revision = txl_revision.id" error:&error];
    
    if (result == nil) {
        [[NSException exceptionWithName:@"TXLRevisionException"
                                 reason:[error localizedDescription]
                               userInfo:nil] raise];
    }
    
    if ([result count] == 0) {
        return nil;
    } else {
        NSUInteger pk = [[[result objectAtIndex:0] objectForKey:@"id"] integerValue];
        NSUInteger ppk = [[[result objectAtIndex:0] objectForKey:@"previous"] integerValue];
        NSDate *timestamp = [NSDate  dateWithTimeIntervalSince1970:[[[result objectAtIndex:0] objectForKey:@"timestamp"] doubleValue]];
        return [TXLRevision revisionWithPrimaryKey:pk
                                         timestamp:timestamp
                                previousPrimaryKey:ppk];
    }
}

- (TXLRevision *)revisionBefore:(NSDate *)timestamp {
    
    NSError *error;
    NSArray *result = [self.database executeSQL:@"SELECT id, timestamp, previous FROM txl_revision WHERE timestamp >= ? ORDER BY timestamp LIMIT 1"
                                 withParameters:[NSArray arrayWithObject:[NSNumber numberWithDouble:[timestamp timeIntervalSince1970]]]
                                          error:&error];
    
    if (result == nil) {
        [[NSException exceptionWithName:@"TXLRevisionException"
                                 reason:[error localizedDescription]
                               userInfo:nil] raise];
    }
    
    if ([result count] == 0) {
        return nil;
    } else {
        NSUInteger pk = [[[result objectAtIndex:0] objectForKey:@"id"] integerValue];
        NSUInteger ppk = [[[result objectAtIndex:0] objectForKey:@"previous"] integerValue];
        NSDate *timestamp = [NSDate  dateWithTimeIntervalSince1970:[[[result objectAtIndex:0] objectForKey:@"timestamp"] doubleValue]];
        return [[TXLRevision revisionWithPrimaryKey:pk
                                          timestamp:timestamp
                                 previousPrimaryKey:ppk] precursor];
    }
}

- (TXLRevision *)revisionAfter:(NSDate *)timestamp {
    
    NSError *error;
    NSArray *result = [self.database executeSQL:@"SELECT id, timestamp, previous FROM txl_revision WHERE timestamp > ? ORDER BY timestamp LIMIT 1"
                                 withParameters:[NSArray arrayWithObject:[NSNumber numberWithDouble:[timestamp timeIntervalSince1970]]]
                                          error:&error];
    
    if (result == nil) {
        [[NSException exceptionWithName:@"TXLRevisionException"
                                 reason:[error localizedDescription]
                               userInfo:nil] raise];
    }
    
    if ([result count] == 0) {
        return nil;
    } else {
        NSUInteger pk = [[[result objectAtIndex:0] objectForKey:@"id"] integerValue];
        NSUInteger ppk = [[[result objectAtIndex:0] objectForKey:@"previous"] integerValue];
        NSDate *timestamp = [NSDate  dateWithTimeIntervalSince1970:[[[result objectAtIndex:0] objectForKey:@"timestamp"] doubleValue]];
        return [TXLRevision revisionWithPrimaryKey:pk
                                         timestamp:timestamp
                                previousPrimaryKey:ppk];
    }
}

@end

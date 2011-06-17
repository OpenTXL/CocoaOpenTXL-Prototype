//
//  TXLManagerDelegateProtocol.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 19.01.11.
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

@class TXLContext;
@class TXLRevision;

@protocol TXLManagerDelegateProtocol

#pragma mark -
#pragma mark Processing

/*
 *  This delegate method is called, if the manager starts processing
 *  scheduled operations. These operations can be either an update of
 *  an context or the evaluation of a query.
 */
- (void)didStartProcessing;

/*
 *  This delegate method is called, if the manager finished all scheduled
 *  operations. These operations can be either an update of an context the
 *  or the evaluation of a query.
 */
- (void)didEndProcessing;

#pragma mark -
#pragma mark Handling Errors

- (void)didFailWithError:(NSError *)error;

#pragma mark -
#pragma mark Change Notification

- (void)didChangeContexts:(NSSet *)ctxs
               inRevision:(TXLRevision *)rev;

@end

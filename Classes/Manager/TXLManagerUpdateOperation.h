//
//  TXLManagerUpdateOperation.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 04.04.11.
//  Copyright 2011 Fraunhofer ISST. All rights reserved.
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

@class TXLSituation;
@class TXLContext;

@interface TXLManagerUpdateOperation : NSObject {

@private
    TXLSituation *situation_;
    TXLContext *context_;
    NSDate *from_;
    NSDate *to_;
}

@property (readonly) TXLSituation *situation;
@property (readonly) TXLContext *context;
@property (readonly) NSDate *from;
@property (readonly) NSDate *to;

+ (TXLManagerUpdateOperation *)operationForContext:(TXLContext *)ctx
                                     withSituation:(TXLSituation *)situation     
                                    inIntervalFrom:(NSDate *)from
                                                to:(NSDate *)to;

- (id)initWithContext:(TXLContext *)ctx
            situation:(TXLSituation *)situation
         intervalFrom:(NSDate *)from
                   to:(NSDate *)to;

@end

//
//  TXLSituation.h
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

@class TXLStatement;
@class TXLMovingObjectSequence;

@interface TXLSituation : NSObject {
    
@private
    NSArray *statements;
    TXLMovingObjectSequence *mos;
}

@property (readonly) NSArray *statements;
@property (readonly) TXLMovingObjectSequence *mos;

+ (TXLSituation *)situationWithStatements:(NSArray *)statements
                     movingObjectSequence:(TXLMovingObjectSequence *)mos;

- (id)initWithStatements:(NSArray *)statements
    movingObjectSequence:(TXLMovingObjectSequence *)mos;

@end

//
//  NSDate+Interval.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 02.02.11.
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


@interface NSDate (Interval)

/*! Return YES if the receiver is in the right open interval from, to.
 *
 *  If any of the to dates is nil, the interval is
 *  treated as an unbound interval (left or right).
 */
- (BOOL)inIntervalFrom:(NSDate *)from
                    to:(NSDate *)to;
@end

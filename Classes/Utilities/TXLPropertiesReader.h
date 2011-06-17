//
//  TXLPropertiesReader.h
//  OpenTXL
//
//  Created by Eleni Tsigka on 01.11.10.
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

#define TXL_CONFIG_FILE_NAME @"OpenTXLConfig"
#define TXL_DATABASE_FILE_NAME_PROPERTY @"TXL Database Path"


@interface TXLPropertiesReader : NSObject {

}

+ (NSString *)propertyForKey:(NSString *)theKey;

@end

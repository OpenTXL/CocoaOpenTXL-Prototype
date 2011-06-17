//
//  TXLPropertiesReader.m
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


#import "TXLPropertiesReader.h"


@implementation TXLPropertiesReader


+ (NSString *)propertyForKey:(NSString *)theKey{
	
	NSDictionary *propertiesDictionary;
	NSString *errorDesc = nil;
	NSPropertyListFormat format;
	NSString *configFilePath = [[NSBundle mainBundle] pathForResource:TXL_CONFIG_FILE_NAME ofType:@"plist"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:configFilePath]) {
		propertiesDictionary = (NSDictionary *)[NSPropertyListSerialization propertyListFromData:[[NSFileManager defaultManager] contentsAtPath:configFilePath]
																					mutabilityOption:NSPropertyListMutableContainersAndLeaves
																							  format:&format
																					errorDescription:&errorDesc];
	} else {
        NSLog(@"No config file found at path: %@", configFilePath);
		return nil;
	}
	
	NSString *result = [[propertiesDictionary objectForKey:theKey] retain];
	
	return [result autorelease];
}



@end

//
//  TXLTerm.h
//  OpenTXL
//
//  Created by Tobias Kräntzer on 18.09.10.
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

typedef enum {
    kTXLTermTypeTerm            = 0,
    kTXLTermTypeResource        = 1,
    kTXLTermTypeBlankNode       = 2,
    kTXLTermTypeIRI             = 3,
    kTXLTermTypeLiteral         = 4,
    kTXLTermTypePlainLiteral    = 5,
    kTXLTermTypeTypedLiteral    = 6,
    kTXLTermTypeStringLiteral   = 7,
    kTXLTermTypeNumericLiteral  = 8,
    kTXLTermTypeIntegerLiteral  = 9,
    kTXLTermTypeDoubleLiteral   = 10,
    kTXLTermTypeBooleanLiteral  = 11,
    kTXLTermTypeDateTimeLiteral = 12
} kTXLTermType;

@interface TXLTerm : NSObject {

@private
    NSUInteger primaryKey;
    kTXLTermType termType;
    id termValue;
    id termMeta;
}


/*! Create a TXLTerm from a string in the general representation of a term.
 *
 *  This Method creates a term by parsing the given string. The string must
 *  contain the representation of a term as defined in the SPARQL specification.
 *
 *  Examples:
 *      true
 *      false
 *      "foo bar"
 *      "foo"@de
 *      "baz"^^<http://example.com>
 *      8462
 *      <http://example.com/foo/bar/>
 *
 *  [TXLTerm termWithString:@"true"];
 *  [TXLTerm termWithString:@"\"foo bar\""];
 */
+ (TXLTerm *)termWithString:(NSString *)value;


/*! Create a TXLTerm representing an IRI.
 *
 *  This method creates a term form the given string. The string
 *  must be a valid representation of an IRI.
 *
 *  [TXLTerm termWithIRI:@"http://example.com/"];
 */
+ (TXLTerm *)termWithIRI:(NSString *)iri;


/*! Create a TXLTerm with a blank node identifier.
 *  
 *  This method creates a term with the blank node
 *  identifier given in the string.
 *
 *  [TXLTerm termWithBlankNode:@"bn1"]; // for _:bn1
 */
+ (TXLTerm *)termWithBlankNode:(NSString *)blankNode;


/*! Create a TXLTerm with a literal.
 *
 *  This method creates a term representing a
 *  plain literal with the given string.
 */
+ (TXLTerm *)termWithLiteral:(NSString *)lit;


/*! Create a TXLTerm with a literal and a language tag.
 *
 *  This method creates a term representing a plain literal
 *  with a value in a certain language. 
 */
+ (TXLTerm *)termWithLiteral:(NSString *)lit
             language:(NSString *)lang;


/*! Create a TXLTerm with a literal and a datatype.
 *
 *  This method creates a term representing a typed literal.
 *  If the typed literal can be represented directly (e.g.,
 *  boolen, datetime, integer), the value will be pared and
 *  the corresponding term will be created.
 */
+ (TXLTerm *)termWithLiteral:(NSString *)lit
             dataType:(TXLTerm *)dt;


/*! Create a TXLTerm from a BOOL.
 *
 *  This method creates term representing a typed literal of
 *  type boolean.
 */
+ (TXLTerm *)termWithBool:(BOOL)boolean;


/*! Create a TXLTerm from a NSInteger.
 *
 *  This method create a term representing a typed literal of
 *  type integer.
 */
+ (TXLTerm *)termWithInteger:(NSInteger)integer;


/*! Create a TXLTerm from a double.
 *
 *  This method creates a term representing a typed literal of
 *  type double.
 */
+ (TXLTerm *)termWithDouble:(double)dbl;


/*! Create a TXLTerm from a NSDate.
 *
 *  This method creates a term representing a typed literal of
 *  type datetime.
 */
+ (TXLTerm *)termWithDate:(NSDate *)dt;


#pragma mark -
#pragma mark Term Type

/*! Type of term
 * 
 *  Returns the type of the TXLTerm (e.g., blank node,
 *  iri, typed literal).
 */
@property (readonly) kTXLTermType type;
- (BOOL)isType:(kTXLTermType)type;

#pragma mark -
#pragma mark Accessing Term Value

/*! The IRI value of the term if it is a IRI, otherwise nil.
 */
@property (readonly) NSString *iriValue;

/*! The blank node identifier of the term if it
 *  is a blank node, otherwise nil.
 */
@property (readonly) NSString *blankNodeValue;

/*! The literal value of the term if it is a literal or
 *  a suptype (e.g., typed literal, boolean liateral), otherwise nil.
 */
@property (readonly) NSString *literalValue;

/*! The boolean value of the term if it is a boolean
 *  literal, otherwise undefined.
 */
@property (readonly) BOOL booleanValue;

/*! The numeric value of a term if it is a numeric literal or a
 *  suptype, otherwise nil.
 */
@property (readonly) NSNumber *numberValue;

/*! The date value of a term if it is a datetime literal,
 *  otherwise nil.
 */
@property (readonly) NSDate *dateValue;

#pragma mark -
#pragma mark Accessing Term Meta Values (datatype, language)

/*! The language tag (e.g., 'de_DE', 'en_US', nil) of the term if it
 *  is a plain literal otherwise nil.
 */
@property (readonly) NSString *language;

/*! The datatype of a term if it is a typed literal as a
 *  TXLTerm representing a IRI, otherwise nil.
 */
@property (readonly) TXLTerm *dataType;

#pragma mark -
#pragma mark Database Management

+ (id)termWithPrimaryKey:(NSUInteger)pk;

@property (readonly) NSUInteger primaryKey;
@property (readonly, getter=isSavedInDatabase) BOOL savedInDatabase;

- (TXLTerm *)save:(NSError **)error;

@end

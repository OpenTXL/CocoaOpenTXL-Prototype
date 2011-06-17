# OpenTXL Operations

## Update & Clear

The data model described in the "OpenTXL Datamodel" section can be modified by the function `update`. There are certain cases, when this function is equivalent to a `clear` call. This function updates statements and their valid space, stated in a certain context.

### Update 

The function `update` is called using the following parameters:
- `c` - Context in which the update of the statements will take place.
- `s` - List of subject-predicate-object statements. These statements are the new valid ones.
- `mo` - Spatio-temporal interval (moving object), in which the statements should be valid.
- `i` - Temporal interval, in which the update shall be applied.
- `completion block` - some code to be executed when the update finishes.

First `i` is used to restrict the moving object `mo`. This means, only spatio-temporal intervals will be further processed, which are valid within this temporal interval. This operation computed the valid spatio-temporal interval (moving object) for the update.

Next, all statements defined in context `c`, which are valid within the previous spatio-temporal interval, and are not included in the `s` list, are marked as deleted. The statements contained in the list `s`, which are already defined in context `c` for the correct spatio-temporal interval are neither changed nor reinserted. It may occur that a situation's spatio-temporal interval intersects the spatio-temporal interval where the update is valid. There may be also no statements of the context `c` defined within the interval the previous spatio-temporal interval.

Finally, the spatial situations included in the list `s`, which are not already defined in the context `c`, are saved in the valid spatio-temporal interval and in association with `c`.


### Clear

Using the function `clear` all statements within a certain context and temporal interval can be deleted or marked as deleted. To do so, `update` is called without statements (`s == nil`) and without valid space (`mo == nil`)


## Import Spatial Situations

New information can be inserted in the database in the form of spatial situations which are assigned to a specific context. This can be done either by importing situations one by one, or by batch importing lots of situations.

The spatial situation is provided in a file, in the format presented later in this section. The framework parses the file and uses a spatial situation compiler to interprete the semantics of the situation. Finally, the appropriate context (defined in the spatial situation file) is updated with the resulted statements in the resulted moving objects.
 
### Human Readable Exchange Format for Spatial Situations

This document defines the human readable exchange format used by the OpenTXL framework for importing spatial situations. The format is an extension of [Notation 3](http://www.w3.org/DesignIssues/Notation3) and introduces the directives `@context`, `@begin`, `@end` and, `@snapshot`.

Example:
	@context <txl://example.com/foo/bar/baz> .
    
    @snapshot 2011-01-23T13:45Z: POINT(...) .
   
    @snapshot 2011-01-23T13:45Z : POINT(...) .
    @snapshot 2011-01-23T13:45Z : GEOMETRYCOLLECTION(...) .
    @snapshot 2011-01-23T13:45Z: POLYGON(...) .
    @snapshot 2011-01-23T13:45Z: POINT(...) .
    @snapshot 2011-01-23T13:45Z: POINT(...) .
    @snapshot 2011-01-23T13:45Z: POLYGON((10 10, 20 10, 20 20, 10 20, 10 10)) .
    @snapshot 2011-01-23T13:45Z: GEOMETRYCOLLECTION(POINT(4 6),LINESTRING(4 6,7 10)) .
    @snapshot 2011-01-23T13:45Z: POLYGON((10 10, 20 10, 20 20, 10 20, 10 10)) .
    @snapshot 2011-01-23T16:12Z: POLYGON((10 10, 20 10, 20 20, 10 20, 10 10)) .
    
    @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
    @prefix dc: <http://purl.org/dc/elements/1.1/> .
    @prefix ex: <http://example.org/stuff/1.0/> .
    
    <http://www.w3.org/TR/rdf-syntax-grammar>
      dc:title "RDF/XML Syntax Specification (Revised)" ;
      ex:editor [
        ex:fullname "Dave Beckett";
        ex:homePage <http://purl.org/net/dajobe/>
      ] .

#### Directives

    declaration
        "@base" explicituri
        "@keywords" barename_csl
        "@prefix" prefix explicituri
        "@context" explicituri
        "@snapshot" timestamp? ":" geometry
    
    timestamp
        ... ISO 8601 ...
    
    geometry
        ... WKT ...

### @context

Set the context for which this document defines a spatial situation. This property has to be set.

### @snapshot

A snapshot defines the geometry of the moving object at a given time. The timestamp of the first snapshot defines the `begin` property of the moving object and the timestamp of the last snapshot its `end` property. If there is no snapshot defined then the moving object represents an "omnipresent" moving object. If there is one snapshot defined without any timestamp, then its geometry is always valid. If there is one snapshot defined without any geometry then this corresponds to an "everywhere" moving object.

The geometry uses the well known text [WKT](http://en.wikipedia.org/wiki/Well-known_text). 
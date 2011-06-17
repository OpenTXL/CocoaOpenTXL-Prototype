# OpenTXL

OpenTXL is a framework for event-driven processing of spatial situations.

Detailed documentation can be found in the folder Documentation.

## Concepts

### Background Material

OpenTXL uses the following concepts and languages:

- Resource Description Framework [RDF][RDF]
- RDF Vocabulary Description Language [RDF Schema][RDFS]
- SPARQL Query Language for RDF [SPARQL][SPARQL]
- Notation3 [N3][N3]


## Installation

### Requirements

The OpenTXL framework requires [SpatiaLite][SPATIALITE] Version 2.4 (or higher). You can use [Homebrew][HOMEBREW] to install this library:

    ~$ brew install libspatialite
    
A later version of OpenTXL will be self contained.


[RDF]: http://www.w3.org/TR/rdf-concepts/ "Resource Description Framework"
[RDFS]: http://www.w3.org/TR/rdf-schema/ "RDF Vocabulary Description Language"
[SPARQL]: http://www.w3.org/TR/rdf-sparql-query/ "SPARQL Query Language for RDF"
[N3]: http://www.w3.org/DesignIssues/Notation3 "Notation 3"
[SPATIALITE]: http://www.gaia-gis.it/spatialite-2.4.0-3/index.html "SpatiaLite 2.4.0"
[HOMEBREW]: http://mxcl.github.com/homebrew/ "Homebrew"

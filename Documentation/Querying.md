# Accessing Data stored in OpenTXL

In OpenTXL, information (situations) is made accessible by [SPARQL][SPARQL]. The application can utilize a `SELECT` query to create a *continuous query* and gain access through a table (list of key-value-pairs for each line together with the valid space for each line).

Access to information is enabled by continuous queries. I.e. when creating a query a handle representing the query is returned instead of the actual result. A delegate can be assigned to this handle. When there is a change in the database that would lead to a modification of the result, the application is notified by a function provided by the delegate.

Additionally, all results are persistently kept in the database. Utilizing the revision number results from other transaction times can be accessed. 

    PREFIX venue: <http://schema.example.com/venue#>.
    PREFIX meteo: <http://schema.situmet.org/meteo#>.
    
    SELECT ?venue
    FROM <txl://example.com/venues>
    FROM <txl://situmet.org/prognosis>
    WHERE {
        ?venue venue:category "outdoor".
        [meteo:temp_category "warm"].
    }

A `SELECT` statement consists of three parts. The `SELECT` clause provides a list of variables corresponding to the columns in the result set. The statements, which the result shall rely on, are defined in the `FROM` clause. In other words, the source of information is defined here. Each `FROM` clause defines the context. During the evaluation all triples within and underneath this context are used. The `WHERE` clause defines a pattern for which matches are searched in the set of triples. A more detailed description can be found in the specification of [SPARQL][SPARQL].

In contrast to other SPARQL interpreters the valid space is explicitly evaluated. Within this evaluation each step that evaluates a new triple pattern, runs a backtracking procedure that restricts the valid space.  

The interpreter initializes an *infinite* valid space as a search **WINDOW**. Once the first triple is found its valid space is intersected with the **WINDOW**. For the next step the current **WINDOW** is the intersection of the previous **WINDOW** and the valid space of the triple found. This procedure is repeated until all triple patterns are satisfied and a common valid space is found.

Once a match with the `WHERE` clause is found, the variables of the `SELECT` clause are replaced by the values found. The same set of values may occur multiple times. If the key-value-pairs match a previously found key-value-pair, the valid space of the current result is extended by (i.e. unioned with) the valid space of the previous result.
    
[SPARQL]: http://www.w3.org/TR/rdf-sparql-query/ "SPARQL Query Language for RDF"
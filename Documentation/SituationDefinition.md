# Situation Definition

New information can be inserted in the OpenTXL framework by inserting spatial situations. New information can also be created, however, from the data already stored in the repository used by OpenTXL. This is realized by the use of `CONSTRUCT` [SPARQL][SPARQL] queries. The application can utilize a `CONSTRUCT` query to create a *situation definition*, which results in the creation of new statements valid in a specific moving object sequnce.

These `CONSTRUCT` queries work similar to the `SELECT` queries, described in the "Accessing Data stored in OpenTXL" section. The only difference is that the user does not acquire a handle to a `CONSTRUCT` query, as its results are meaningless to the user. The implementation of the SPARQL interpreter takes care of the results of `CONSTRUCT` SPARQL queries, by creating and storing the spatial situations which correspond to these results. Nevertheless, a  `CONSTRUCT` SPARQL query is similar to a `SELECT` query, in that it is a continuous query. Each time there is a change in the contexts on which the  `CONSTRUCT` query depends, there is a reinterpretation of its results and an update of the resulting situations.  

Additionally, all results are persistently kept in the database. Utilizing the revision number results from other transaction times can be accessed. 

	PREFIX weather: <http://schema.opentxl.org/weather#>
	PREFIX suitabilities: <http://schema.opentxl.org/suitabilities#>

	CONSTRUCT {
		[suitabilities:suitability_category suitabilities:NiceWeather] .
	}

	FROM <txl://opentxl.org/weather> 

	WHERE {
		NOT EXISTS {[weather:rain []].}
	}

A `CONSTRUCT` statement consists, similar to a `SELECT` query, of three parts. The `CONSTRUCT` clause provides the template, which will be used for the creation of the situations. The statements, which the result shall rely on, are defined in the `FROM` clause. In other words, the source of information is defined here. Each `FROM` clause defines the context. During the evaluation all triples within and underneath this context are used. The `WHERE` clause defines a pattern for which matches are searched in the set of triples. A more detailed description can be found in the specification of [SPARQL][SPARQL].

The interpreter works, in this case, as described in section "Accessing Data stored in OpenTXL", with some additional functionality. The results of a `CONSTRUCT` query are used to substitute the variables contained in the template, in order to produce the new statements. The new statements are valid in the moving objects of the results.

[SPARQL]: http://www.w3.org/TR/rdf-sparql-query/ "SPARQL Query Language for RDF"
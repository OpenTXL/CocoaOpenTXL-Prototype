TODO: In the documentation we distinguish the general statements from the technical `statements`. The same holds for a sentence in a natural language in comparison with a `statement` with Subject, Predicate and Object. 

# OpenTXL Datamodel

## Statements

Information (statements) is formulated utilizing the Resource Description Framework ([RDF][RDF]). These expressions are constructed by a set of subject-predicate-object-tuples. Therefore statements as for example

	Lisa is a person who is interested in music and architecture.
	
and

	The exhibit "Visions" is about architecture by van der Rohe.
	
can be made.

Subject, predicate, and object of a statement are referred to as terms. These terms are either character strings, numbers, certain typed values, or resources. Resources can either be anonymous nodes or [IRIs][IRI]. IRIs are used to retrieve unique identifiers in order to describe a predicate, a type, or an "thing".

Utilizing [Notation3][N3], the statements made above would be:

    @prefix schema: <http://example.com/schema#>.
    
    [a schema:person;
     schema:name "Lisa";
     schema:interest "music",
                     "architecture"].
    
    [a schema:exhibition;
     schema:title "Visions";
     schema:category "architecture"].

This example uses a fictitious scheme (`http://example.com/schema#`) to describe types (person, exhibition) and properties (name, interests, title, category).

Above statements were made in a short form using N3. The statement about Lisa's interests would create the following set of triples:

    subject | predicate                                         | object
    ========|===================================================|====================================
    _:x     | <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> | <http://example.com/schema#Person>
    _:x     | <http://example.com/schema#name>                  | "Lisa"
    _:x     | <http://example.com/schema#interest>              | "music"
    _:x     | <http://example.com/schema#interest>              | "architecture"

To shorten this representation of triples IRIs will be abbreviated by a prefix.

    subject | predicate         | object
    ========|===================|===============
    _:x     | a                 | schema:Person
    _:x     | schema:name       | "Lisa"
    _:x     | schema:interest   | "music"
    _:x     | schema:interest   | "architecture"

The term `_:x`, which was used as the subject in the previous examples, represents an anonymous resource. Using natural language this would read to: there is an **thing**, which is of type person and has name "Lisa", etc. See http://en.wikipedia.org/wiki/Blank_node for details on the interpretation of anonymous nodes.

## RDF Schema

Certain meanings can be assigned to the resources mentioned above by the use of schemas ([RDF Schema][RDFS]). The schemas are formulated in RDF themselves as well. They can for example describe, that a certain type (subclass) is inherited or that a certain predicate may be transitive. For resource `<http://example.com/schema#person>` we can define that this is a type and which properties it has.

In the current version of the framework there is no evaluation of schemas.

## Contexts

OpenTXL is a framework for a distributed system with different contributors of information. Therefore a differentiation of the context in which a statement is made is necessary. The context can be the background information of a statement, the intention, or similar.

For the processing of information within the framework the exact meaning of the context makes no difference. On a higher level (where situation definitions are verbalized) a differentiation becomes relevant in order to define the context of the derived statements. For this reason an assertion of a context is crucial.

In the example above, the context *Lisa* infers, that Lisa herself stated her interest in music and architecture. The second statement about the content of the exhibition would be assigned to the context *events*. If a new statement should be made based on the two previous statements, for example that Lisa may like the exhibition "Visions", this statement is then verbalized in the context, which is based on the context *Lisa* and *events* and the *intension of our question*. This new statement would be interpreted as follows:

    Based on the statement in context "Lisa", that Lisa has an interest in architecture,
	and the statement in context "event", that the exhibition belongs to the category "architecture",
	Lisa may have an interest in the exhibition "Visions".

The unique assignment of a statement to a context makes a difference about the source only. The following statement could also be made:

    Based on Peter's statement (context *Peter*), saying that Lisa may have an interest in
    architecture, and the statement in context "event", that the exhibition belongs to the
    category "architecture", Lisa may have an interest in the exhibition "Visions".

Both statements would use the same triples in RDF. There would be a difference in context only.

    subject | predicate         | object            | context
    ========|===================|===================|=========
    _:x     | a                 | schema:Person     | </a>
    _:x     | schema:name       | "Lisa"            | </a>
    _:x     | schema:interest   | _:y               | </a>
    _:y     | a                 | schema:Exhibition | </a>
    _:y     | schema:title      | "Visons"          | </a>
    ----------------------------------------------------------
    _:u     | a                 | schema:Person     | </b>
    _:u     | schema:name       | "Lisa"            | </b>
    _:u     | schema:interest   | _:v               | </b>
    _:v     | a                 | schema:Exhibition | </b>
    _:v     | schema:title      | "Visons"          | </b>


On a higher level the description of contexts `/a` and `/b` could be:

<dl>
    <dt>/a</dt>
    <dd>Statements in this context are based on the statements within the contexts <strong>"Lisa"</strong> and "event" and are composed by comparison of interests of persons with categories of <em>things</em>.</dd>
    <dt>/b</dt>
    <dd>Statements in this context are based on the statements within the contexts <strong>"Peter"</strong> and "event" and are composed by comparison of interests of persons with categories of <em>things</em>.</dd>
</dl>

To enable referencing of contexts each context has a globally unique identifier, an IRI. Additionally contexts are arranged in a hierarchy by decomposing its IRI into components (scheme, domain, path).

If an evaluation is based on the context `<txl://example.com/>` also statements of contexts `<txl://example.com/foo/>` and `<txl://example.com/bar/>` are considered, since they are hierarchically underneath `<txl://example.com/>`.

Due to the use of IRIs as identifier for contexts. A context itself could be described by RDF also. Such a description of contexts and their interpretation is dependent on the application and will not be handled here.

## Situations

A situation is an interval for which certain properties are constant. Applied to the information model in OpenTXL a situation is an interval for which a certain *statement* is valid.

For the above statement, that Lisa is a person with a interest in music and architecture, the interval (1998, 2010) can be assigned as an example.

    subject | predicate         | object            | context  | begin  | end
    ========|===================|===================|==========|========|=======
    _:x     | a                 | schema:Person     | </lisa>  | 1998   | 2010
    _:x     | schema:name       | "Lisa"            | </lisa>  | 1998   | 2010 
    _:x     | schema:interest   | "music"           | </lisa>  | 1998   | 2010
    _:x     | schema:interest   | "architecture"    | </lisa>  | 1998   | 2010

Now we have a set of triples within the context `</lisa>` and being valid in the interval from 1998 until 2010. Assuming, Lisa was interested in music and Lego prior to 1998, the following statement can be made.

    subject | predicate         | object            | context  | begin  | end
    ========|===================|===================|==========|========|=======
    _:y     | a                 | schema:Person     | </lisa>  | 1985   | 1998
    _:y     | schema:name       | "Lisa"            | </lisa>  | 1985   | 1998 
    _:y     | schema:interest   | "music"           | </lisa>  | 1985   | 1998
    _:y     | schema:interest   | "Lego"            | </lisa>  | 1985   | 1998

This example also shows, how different statements can be interpreted within the same context for different time intervals. Assuming that the literal "Lisa" we use is a globally unique identifier for a person, we can imply, that there is a person Lisa (with an interest in music) at minimum within the interval 1985 to 2010.

## Moving Objects

Movings objects or regions are geometric objects which change their location or extend over time. This could be, for example, a rain cloud that moves or a travel route.

For these moving regions different representations exist. We use a representation that uses snapshots of the spatial extend for different time points. The valid space (volume) is computed by interpolating these snapshots.

...

## Spatial Situation

As an extension spatial situations are introduced. In contrast to situations a moving region is used instead of time intervals to define spatial situations. With this in mind statements can not only be made in a temporal manner, but also in a spatio-temporal manner. For example, the statement "warm temperature" of a forecasting system can be stated as follows:

    [moving objects]
    id    | begin  | end    | ...
    ======|========|========|==
    86732 | 10:00  | 14:00  | 
    
    [statements]
    subject | predicate           | object   | context      | mo_id
    ========|=====================|==========|==============|========
    _:z     | meteo:temp_category | "warm"   | </prognosis> | 86732 
    
    mo_id = (moving object id)

Without the spatial components, this statement would be useless. Only if location and time are defined the information about when and where it is warm can be further processed.

![Moving Region](../Images/moving-region.png)

## Revisions

...


[RDF]: http://www.w3.org/TR/rdf-concepts/ "Resource Description Framework"
[RDFS]: http://www.w3.org/TR/rdf-schema/ "RDF Vocabulary Description Language"
[SPARQL]: http://www.w3.org/TR/rdf-sparql-query/ "SPARQL Query Language for RDF"
[RDF-TERMS]: http://www.w3.org/TR/rdf-sparql-query/#syntaxTerms "RDF Term Syntax"
[IRI]: http://tools.ietf.org/html/rfc3987 "Internationalized Resource Identifiers"
[N3]: http://www.w3.org/DesignIssues/Notation3 "Notation 3"
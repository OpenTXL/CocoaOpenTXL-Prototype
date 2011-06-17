# OpenTXL Database Schema

All data in the OpenTXL framework is stored in a [SpatiaLite][SPATIALITE] database.

Each modification of the situation database results only in INSERT statements.
This leads to a consistent model at each time. 

The rule is that table rows are not updated or deleted. Exceptions include:
 * the *marker* table `txl_revision_head` for the head revision. 
 * the name and properties of SPARQL queries. This can happen during the registration, interpretation, storage, unregistration, and invalidation of select and construct SPARQL queries. In all of these cases only the properties and associations of the corresponding query entities are updated or deleted. The resulting statements of these queries are not deleted from the database, but are marked as removed.

If the size of the database gets to big, an optional *clean* operation could browse through the database and remove all unused information up to a certain revision. At the moment, this operation is not supported.

## Revision

The table `txl_revision` contains all revisions. Each revision except the first has a previous revision. The table `txl_revision_head` stores the last revision in the row with the id 1. To get the head revision, you just have to execute the statement `SELECT revision FROM txl_revision_head WHERE id = 1`.

A trigger on the table `txl_revision` ensures, that after creating a new revision, `txl_revision_head` is updated.

SQL statements to setup the tables, indexes and triggers for storing revisions:

    CREATE TABLE IF NOT EXISTS txl_revision (
    	id integer NOT NULL PRIMARY KEY AUTOINCREMENT,
        previous integer REFERENCES txl_revision (id),
        timestamp NOT NULL DEFAULT ((julianday('now') - 2440587.5)*86400.0)
    );
    
    CREATE INDEX IF NOT EXISTS txl_revision_timestamp ON txl_revision (timestamp);
	CREATE INDEX IF NOT EXISTS txl_revision_previous ON txl_revision (previous);

	CREATE TABLE IF NOT EXISTS txl_revision_head (
		id integer NOT NULL PRIMARY KEY, 
		revision integer REFERENCES txl_revision (id)
	);
	
	CREATE TRIGGER IF NOT EXISTS txl_revision_after AFTER INSERT ON txl_revision
		BEGIN 
			UPDATE txl_revision_head SET revision = new.id WHERE id = 1; 
		END;
		
	INSERT INTO txl_revision_head (id, revision) VALUES (1, 0);


## Context

A context has a name, which must be unique. The OpenTXL framework searches for contexts by performing a pattern matching comparison on the their names. This pattern matching comparison is performed in SQLite by the `glob` operator. After performance tests this method (in combination with the defined index) was found to be the most effective way to store, search, and retrieve `txl_context` entities.   

SQL statements to setup the tables and indexes for storing contexts:

    CREATE TABLE IF NOT EXISTS txl_context (
	    id integer NOT NULL PRIMARY KEY,
    	name NOT NULL UNIQUE
    );
    
    CREATE INDEX IF NOT EXISTS txl_context_name ON txl_context (name);


### Derived Contexts a.k.a. Situation Definitions

SPARQL contruct queries create new sitution definitions. The resulting situation definitions have to be stored in association with a single context, to which they belong. This entity contains exactly this association. For each context there is only one SPARQL construct query.
        
    CREATE TABLE IF NOT EXISTS txl_context_query (
		id INTEGER NOT NULL PRIMARY KEY,
        query_id INTEGER NOT NULL REFERENCES txl_query (id),
        context_id INTEGER NOT NULL REFERENCES txl_context (id),
        UNIQUE(context_id)
    );

    
## Moving Object

Moving objects are stored in the table `txl_movingobject`. Each moving object consists of a row in this table and at least two snapshots in the table `txl_snapshot`. The table `txl_snapshot` links a geometry collection with a timestamp to the moving object. A `txl_snapshot` entity specifies the geometry  of the moving object at a certain timestamp and has a count property which shows its order in the moving object's list of snapshots.

A moving object entity specifies the `begin` and `end` timestamps of the moving object and its `bounds`. The `begin` and/or `end` timestamps can be:
 * NULL, in which case they show that the moving object spans from (if the `begin` is NULL) and/or to (if the `end` is NULL) the infinity.
 * timestamps.
The `begin` and `end` properties are equal to the timestamps of the first and the last snapshots respectively. There is no sorting performed. It is assumed that the snapshots are in the correct order.

The `bounds` property is a foreign key to the `txl_geometry` table, which stores geometry collection entities as blobs. The geometry collection associated with the `bounds` property of a moving object is computed as the union of the geometries of all snapshots associated with it. If the moving object is valid over the whole world then the geometry collection used for its `bounds` is the POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90)).

It is not possible to have a moving object with either the `begin`/`end` or `bounds` properties undefined, because in that case it would be an invalid moving object.

SQL statements to setup the tables and indexes for storing moving objects:

    CREATE TABLE IF NOT EXISTS txl_movingobject (
        id INTEGER NOT NULL PRIMARY KEY,
        "begin",
        "end",
    	bounds INTEGER REFERENCES txl_geometry (id)
    );
    
    CREATE TABLE IF NOT EXISTS txl_geometry (id integer NOT NULL PRIMARY KEY);
    SELECT AddGeometryColumn('txl_geometry', 'geometry', 4326, 'GEOMETRYCOLLECTION', 2);
    SELECT CreateSpatialIndex('txl_geometry', 'geometry');
   
    
    CREATE TABLE IF NOT EXISTS txl_snapshot (
    	id INTEGER NOT NULL PRIMARY KEY,
        count INTEGER NOT NULL,
        movingobject_id INTEGER NOT NULL REFERENCES txl_movingobject (id),
        geometry_id INTEGER NOT NULL REFERENCES txl_geometry (id),
        timestamp
    );
    
	CREATE INDEX IF NOT EXISTS txl_movingobject_begin ON txl_movingobject ("begin");
	CREATE INDEX IF NOT EXISTS txl_movingobject_end ON txl_movingobject ("end");
	CREATE INDEX IF NOT EXISTS txl_snapshot_movingobject_id ON txl_snapshot (movingobject_id);
	CREATE INDEX IF NOT EXISTS txl_snapshot_timestamp ON txl_snapshot (timestamp);
	CREATE INDEX IF NOT EXISTS txl_snapshot_geometry_id ON txl_snapshot (geometry_id);
    
    
## Moving Object Sequence

A moving object sequence stores a list of moving objects and the count property in the txl_movingobjectsequence_movingobject table shows the order of a moving object in the sequence's moving objects' list.

	CREATE TABLE IF NOT EXISTS txl_movingobjectsequence (
		sequence_id integer NOT NULL PRIMARY KEY
	);
    
   	CREATE TABLE IF NOT EXISTS txl_movingobjectsequence_movingobject (
    	count INTEGER NOT NULL,
        sequence_id integer NOT NULL REFERENCES txl_movingobjectsequence (sequence_id),
        movingobject_id integer NOT NULL REFERENCES txl_movingobject (id),
        UNIQUE(sequence_id, movingobject_id),
        UNIQUE(sequence_id, count)
    );
                        
    CREATE INDEX IF NOT EXISTS txl_movingobjectsequence_sequence_id ON txl_movingobjectsequence (sequence_id);
	CREATE INDEX IF NOT EXISTS txl_movingobjectsequence_movingobject_sequence_id ON txl_movingobjectsequence_movingobject (sequence_id);
	CREATE INDEX IF NOT EXISTS txl_movingobjectsequence_movingobject_movingobject_id ON txl_movingobjectsequence_movingobject (movingobject_id);


## Term

Terms are stored in the table `txl_term`. The types of a term (resource, iri, blank node, literal, plain literal, typed literal, string literal, numeric literal, integer literal, double literal, boolean literal, and date/time literal) are stored in the the same table. The type is described by an integer (column `type`) and the value is stored in the column value. Additional values like an iri for the data type of a typed term or the language tag for a plain literal are stored in the column `meta`. The type of the values stored in `value` or `meta` depends on the value in `type`.

SQL statements to setup the tables and indexes for storing terms:

    CREATE TABLE IF NOT EXISTS txl_term (
    	id integer NOT NULL PRIMARY KEY, 
    	type NOT NULL, 
    	value, 
    	meta, 
    	UNIQUE(type, value, meta)
    );


## Statements

Each statement is stored in the table `txl_statements`. All parts of a statement are references to other tables with the corresponding information.

The statements in this table are never removed (despite the fact that unused revisions may be removed). If a new statement is inserted, it is marked as created in the table `txl_created` with the corresponding revision. If a statement should be removed, it will be marked as removed in the table `txl_removed` with the new revision (If it is removed in revision 12, the statement is valid up to revision 12, but not in revision 12).

A statement is valid in the head revision, if it does not apear in the table `txl_removed`. 

SQL statements to setup the tables and indexes for storing statements:

    CREATE TABLE IF NOT EXISTS txl_statement (
    	id integer NOT NULL PRIMARY KEY,
        subject_id integer NOT NULL REFERENCES txl_term (id),
        predicate_id integer NOT NULL REFERENCES txl_term (id),
        object_id integer NOT NULL REFERENCES txl_term (id),
        mo_id integer REFERENCES txl_movingobject (id),
        context_id integer NOT NULL REFERENCES txl_context (id)
    );
    
    CREATE INDEX IF NOT EXISTS txl_statement_subject_id ON txl_statement (subject_id);
	CREATE INDEX IF NOT EXISTS txl_statement_predicate_id ON txl_statement (predicate_id);
	CREATE INDEX IF NOT EXISTS txl_statement_object_id ON txl_statement (object_id);
	CREATE INDEX IF NOT EXISTS txl_statement_mo_id ON txl_statement (mo_id);
	CREATE INDEX IF NOT EXISTS txl_statement_context_id ON txl_statement (context_id);

SQL statements to setup the tables and indexes for *marking* a statements as created:

    CREATE TABLE IF NOT EXISTS txl_statement_created ( 
		id integer NOT NULL PRIMARY KEY, 
		statement_id integer NOT NULL UNIQUE REFERENCES txl_statement (id), revision_id integer NOT NULL REFERENCES txl_revision (id) 
	);
	
	CREATE INDEX IF NOT EXISTS txl_statement_created_statement_id ON txl_statement_created (statement_id);
	CREATE INDEX IF NOT EXISTS txl_statement_created_revision_id ON txl_statement_created (revision_id);

SQL statements to setup the tables and indexes for *marking* a statements as removed:
    
    CREATE TABLE IF NOT EXISTS txl_statement_removed ( 
		id integer NOT NULL PRIMARY KEY,
		statement_id integer NOT NULL UNIQUE REFERENCES txl_statement (id), revision_id integer NOT NULL REFERENCES txl_revision (id)
	);

	CREATE INDEX IF NOT EXISTS txl_statement_removed_statement_id ON txl_statement_removed (statement_id);
    CREATE INDEX IF NOT EXISTS txl_statement_removed_revision_id ON txl_statement_removed (revision_id);
    
    
## Continuous Queries

Compiled continuous queries (SPARQL expressions) are stored in several tables. The table `txl_query` represents the queries. It contains the SPARQL expression (source) and the revisions of the first and last evaluations. The revision of the last evaluation should always be the same as the head revision. If these are not the same, the evaluation of the query is in progress. The txl_query table also contains a reference to the id of the txl_query_pattern, used to store the pattern in the query's where clause. It also has a reference to the id of the txl_query_pattern, used to store the template pattern of the query, if it is a `CONSTRUCT` query. For non `CONSTRUCT` queries, this column has a NULL value, whereas for `CONSTRUCT` queries this column should have a non NULL value.  

    CREATE TABLE IF NOT EXISTS txl_query (
    	id INTEGER NOT NULL PRIMARY KEY,
        sparql TEXT NOT NULL,
        first_evaluation INTEGER REFERENCES txl_revision (id),
        last_evaluation INTEGER REFERENCES txl_revision (id),
        pattern_id INTEGER NOT NULL REFERENCES txl_query_pattern (id),
		construct_template_pattern_id INTEGER REFERENCES txl_query_pattern (id) 
	);
    
    CREATE INDEX IF NOT EXISTS txl_query_first_evaluation ON txl_query (first_evaluation);
	CREATE INDEX IF NOT EXISTS txl_query_last_evaluation ON txl_query (last_evaluation);

### Query Name

The name with which a SPARQL query is registered is stored in the `txl_query_name` table.

	CREATE TABLE IF NOT EXISTS IF NOT EXISTS txl_query_name (
    	id INTEGER NOT NULL PRIMARY KEY,
        query_id integer REFERENCES txl_query (id),
        name TEXT NOT NULL UNIQUE
    );

### Contexts

The table `txl_query_context` contains the extracted list of contexts from which statements are considered during an evaluation. These contexts are stated with the `FROM` clause in the SPARQL expression.
    
    CREATE TABLE IF NOT EXISTS txl_query_context (
    	id integer NOT NULL PRIMARY KEY,
        query_id integer NOT NULL REFERENCES txl_query (id),
        context_id integer NOT NULL REFERENCES txl_context (id),
        UNIQUE(query_id, context_id)
    );
    
	CREATE INDEX IF NOT EXISTS txl_query_context_query_id ON txl_query_context (query_id);
	CREATE INDEX IF NOT EXISTS txl_query_context_context_id ON txl_query_context (context_id);

### Variables

The table `txl_query_variables` contains the variables and blank nodes for each query. The variables extracted from the `SELECT` clause, as well as the variables and blank nodes contained in a `CONSTRUCT` template of a SPARQL expression have always a value `TRUE` in the column `in_resultset`. Whereas variables and blank nodes contained in the `WHERE` clause of a SPARQL expression have the value `FALSE` in the column `in_resultset`. If a `SELECT` clause contains the selector * then all variables contained in query's `WHERE` clause have `in_resultset` equal to `TRUE`. If no variables are defined in the `SELECT` clause of a query, the query is of type `ASK`.

    CREATE TABLE IF NOT EXISTS txl_query_variable (
    	id integer NOT NULL PRIMARY KEY,
        query_id integer NOT NULL REFERENCES txl_query (id),
        name varchar(1024),
        in_resultset BOOL DEFAULT FALSE,
        is_blanknode BOOL DEFAULT FALSE,
        UNIQUE(query_id, name, is_blanknode)
    );
    
    CREATE INDEX IF NOT EXISTS txl_query_variable_query_id ON txl_query_variable (query_id);
	CREATE INDEX IF NOT EXISTS txl_query_variable_name ON txl_query_variable (name);

### Graph Pattern

	{ ... }

The table `txl_query_pattern` is the main table for graph patterns. Each pair of curly brackets in a SPARQL expression is represented by an entry in this table.

	CREATE TABLE IF NOT EXISTS txl_query_pattern (
		id integer NOT NULL PRIMARY KEY
	);

#### Basic Graph Pattern

	{
		?x :foo true .
	}

Basic graph patterns (triples) are stored in the table `txl_query_pattern_triple`. Each triple has a reference to the pattern to which it is associated. Subject, predicate, and object can be a reference to a term or a variable. If the <subject/predicate/object>_var_id is not null, the corresponding part is treated as a variable (the term is ignored).

	CREATE TABLE IF NOT EXISTS txl_query_pattern_triple (
		id integer NOT NULL PRIMARY KEY,
        in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id),
        subject_id integer REFERENCES txl_term (id),
        subject_var_id integer REFERENCES txl_query_variable (id),
        predicate_id integer REFERENCES txl_term (id),
        predicate_var_id integer REFERENCES txl_query_variable (id),
        object_id integer REFERENCES txl_term (id),
        object_var_id integer REFERENCES txl_query_variable (id)
    );
	
	CREATE INDEX IF NOT EXISTS txl_query_pattern_triple_in_pattern_id ON txl_query_pattern_triple (in_pattern_id);

#### (Sub-)Group Graph Pattern

	{
		{ ... }
	}

A group graph pattern is represented by an entry in the table `txl_query_pattern_group`. Each entry consists of a reference to the surrounding (`in_pattern_id`) and inner (`pattern_id`) pattern.

	CREATE TABLE IF NOT EXISTS txl_query_pattern_group (
    	id integer NOT NULL PRIMARY KEY,
    	in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id),
    	pattern_id integer NOT NULL REFERENCES txl_query_pattern (id)
    );
	
	CREATE INDEX IF NOT EXISTS txl_query_pattern_group_in_pattern_id ON txl_query_pattern_group (in_pattern_id);

#### Optional Graph Pattern

	{
		OPTIONAL { ... }
	}

An optional graph pattern is represented by an entry in the table `txl_query_pattern_optional`. Each entry consists of a reference to the surrounding (`in_pattern_id`) and inner (`pattern_id`) pattern.

	CREATE TABLE IF NOT EXISTS txl_query_pattern_optional (
    	id integer NOT NULL PRIMARY KEY,
    	in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id),
        pattern_id integer NOT NULL REFERENCES txl_query_pattern (id)
    );
	
	CREATE INDEX IF NOT EXISTS txl_query_pattern_optional_in_pattern_id ON txl_query_pattern_optional (in_pattern_id);

#### Alternative Graph Pattern

	{
		{ ... } UNION { ... } UNION { ... }
	}

An alternative graph pattern is represented by an entry in the table `txl_query_pattern_union` and at least two entries in the table `txl_query_pattern_union_pattern`.

	CREATE TABLE IF NOT EXISTS txl_query_pattern_union (
    	id integer NOT NULL PRIMARY KEY,
        in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id)
    );
	
	CREATE INDEX IF NOT EXISTS txl_query_pattern_union_in_pattern_id ON txl_query_pattern_union (in_pattern_id);

	CREATE TABLE IF NOT EXISTS txl_query_pattern_union_pattern (
    	id integer NOT NULL PRIMARY KEY,
        union_id integer NOT NULL REFERENCES txl_query_pattern_union (id),
        pattern_id integer NOT NULL REFERENCES txl_query_pattern (id)
    );
	
	CREATE INDEX IF NOT EXISTS txl_query_pattern_union_pattern_union_id ON txl_query_pattern_union_pattern (union_id);

#### Named Graph Pattern

	{
		GRAPH ?x { ... }
		GRAPH <http://example.com> { ... }
	}

A named graph pattern is represented by an entry in the table `txl_query_pattern_named`. Each entry consists of a reference to the surrounding (`in_pattern_id`) pattern, the inner (`pattern_id`) pattern and either a term with the context which should be used in the evaluation or a variable to which the name of a context should be bound to. If `context_var_id` is null, the value from `context_id` is used.

	CREATE TABLE IF NOT EXISTS txl_query_pattern_named (
		id integer NOT NULL PRIMARY KEY,
        in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id),
        context_id integer REFERENCES txl_context (id),
        context_var_id integer REFERENCES txl_query_variable (id),
        pattern_id integer NOT NULL REFERENCES txl_query_pattern (id)
    );
	
	CREATE INDEX IF NOT EXISTS txl_query_pattern_named_in_pattern_id ON txl_query_pattern_named (in_pattern_id);

#### Not Exists Graph Pattern

    {
    	NOT EXISTS { ... }
    }

A not exists graph pattern is represented by an entry in the table `txl_query_pattern_not_exists`. Each entry consists of a reference to the surrounding (`in_pattern_id`) and inner (`pattern_id`) pattern.

	CREATE TABLE IF NOT EXISTS txl_query_pattern_not_exists (
  		id integer NOT NULL PRIMARY KEY,
        in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id),
        pattern_id integer NOT NULL REFERENCES txl_query_pattern (id)
    );
    
    CREATE INDEX IF NOT EXISTS txl_query_pattern_not_exists_in_pattern_id ON txl_query_pattern_not_exists (in_pattern_id);

#### Filter

	{
		FILTER ( ... ) .
	}

    CREATE TABLE IF NOT EXISTS txl_query_pattern_filter (
		id integer NOT NULL PRIMARY KEY,
        in_pattern_id integer NOT NULL REFERENCES txl_query_pattern (id),
        expression TEXT NOT NULL
    	);
    
    CREATE INDEX IF NOT EXISTS txl_query_pattern_filter_in_pattern_id ON txl_query_pattern_filter (in_pattern_id);


## Result Set

The results of continuous queries are stored in separate tables. Each query has its own set of tables. The table `txl_resultset_<query id>` contains the results for query `<query id>`. It consists of a primary key, a column for a moving object sequence and optional columns (one for each variable in the query) with terms.

	CREATE TABLE txl_resultset_<query id> (
    	id integer NOT NULL PRIMARY KEY,
        mos_id integer NOT NULL REFERENCES txl_movingobjectsequence (id),         var_<var id> integer REFERENCES txl_term (id)
    );

The validity of a row in the table `txl_resultset_<query id>` is tracked in the tables `txl_resultset_<query id>_created` and `txl_resultset_<query id>_removed`. These are used as described in the section of the statement tables.
    
	CREATE TABLE txl_resultset_<query id>_created (
		id integer NOT NULL PRIMARY KEY,
        resultset_id integer NOT NULL UNIQUE REFERENCES txl_resultset_<query id> (id),
        revision_id integer NOT NULL REFERENCES txl_revision (id)
    );
        
    CREATE INDEX txl_resultset_<query id>_created_resultset_id ON txl_resultset_<query id>_created (resultset_id);
    
    CREATE INDEX txl_resultset_<query id>_created_revision_id ON txl_resultset_<query id>_created (revision_id);
        
        
	CREATE TABLE txl_resultset_<query id>_removed (
		id integer NOT NULL PRIMARY KEY,
        resultset_id integer NOT NULL UNIQUE REFERENCES txl_resultset_<query id> (id),
        revision_id integer NOT NULL REFERENCES txl_revision (id)
    );
        
    CREATE INDEX txl_resultset_<query id>_removed_resultset_id ON txl_resultset_<query id>_removed (resultset_id);
	CREATE INDEX txl_resultset_<query id>_removed_revision_id ON txl_resultset_<query id>_removed (revision_id);
		


[SPATIALITE]: http://www.gaia-gis.it/spatialite-2.4.0-3/index.html "SpatiaLite 2.4.0"
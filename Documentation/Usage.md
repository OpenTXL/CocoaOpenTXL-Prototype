# Using the OpenTXL Framework

## TXLTerm & TXLStatement

The classes `TXLTerm` and `TXLStatement` are used to make statements in terms of the Resource Description Framework.

    TXLTerm *subject = [TXLTerm termWithString:@"subject"];
    TXLTerm *predicate = [TXLTerm termWithString:@"predicate"];
    TXLTerm *object = [TXLTerm termWithString:@"object"];
    
    TXLStatement *statement = [TXLStatement statementWithSubject:subject
                                                       predicate:predicate
                                                          object:object];

The method used above creates a TXLTerm from a string in the general representation of a term. Terms are created by using a type hierarchy as defined in [Section 4.1][RDF-TERMS] of [SPARQL][SPARQL].


## TXLMovingObject

A moving object is a snapshot-based representation of a geometry object (point, line, polygon, geometry collection) which changes its shape over time. A moving object consists of a `begin`, an `end`, and a `bounds` property. `Begin` and `end` properties mark the points in time, where the moving object starts and where it ends, but the actual 'begin' and 'end' timestamps are not included in the moving object's validity interval. Both (`begin` and `end`) properties can be nil, which means that this moving object always exists or that it begins / ends at an infinite time point.

In this interval, several snapshots are given. At least two of them are necessary to give the state of the moving object at the begin and end times. The `begin` and `end` properties of the moving object are computed based on the first and last snapshots. Each snapshot consists of a time point (`NSDate`) and a geometry collection (`TXLGeometry`). The `bounds` property of the moving object is computed as the union of the geometries of all snapshots associated with it.

Let's assume the following geometry collections and timestamps:

    TXLGeometryCollection *geometry = ...
    TXLGeometryCollection *anotherGeometry = ...
    NSDate *begin = ...
    NSDate *end = ...

The OpenTXL framework supports the creation of moving objects as:

 1. Empty moving object: it cannot be saved.
   [TXLMovingObject emptyMovingObject];

 2. Omnipresent moving object is the exact opposite of an empty moving object. Its `bounds` are set equal to the POLYGON which represents the entire world (POLYGON((-180 -90, -180 90, 180 90, 180 -90, -180 -90))) and its `begin` and `end` properties are set to nil.
    [TXLMovingObject omnipresentMovingObject];

 3. Everywhere moving object. This moving object is in the specified interval
 everywhere valid. Its `bounds` are set equal to the POLYGON which represents the entire world.
	[TXLMovingObject movingObjectWithBegin:begin
                                       end:end];

 If there are more than one snapshots, then the begin and end times are the timestamp of the first and the last snapshot respectively. There is no sorting or comparison performed. It is assumed that the snapshots are in the correct order.

 4. Always moving object. This moving object is in the specified geometry
 always valid. Its `begin` and `end` properties are set to nil. 
	[TXLMovingObject movingObjectWithGeometry:geometry];


 5. A moving object with one snapshot. This moving object is assigned two snapshots, which are constructed with the timestamps begin and end and the same geometry.
	[TXLMovingObject movingObjectWithGeometry:geometry
                                        begin:begin
                                          end:end;

 6. A moving object with a list of snapshots. The `begin` and `end` properties are set to the first and last snapshots' timestamps. The array must contain snapshots with ascending timestamps. The first or last snapshot can have nil as timestamp to indicate that the moving object starts in the distant past or ends in the distant future.
	[TXLMovingObject movingObjectWithSnapshots:NSArray arrayWithObjects:[TXLSnapshot snapshotWithTimestamp:begin geometry:geometry], [TXLSnapshot snapshotWithTimestamp:end geometry:anotherGeometry], nil];


## TXLMovingObjectSequence

A TXLMovingObjectSequence is a collection of TXLMovingObjects. The moving objects in the sequence must not have intersecting time intervals.

## TXLManager

Each application has one shared manager for the OpenTXL framework. This manager is created when the first call of `[TXLManager sharedManager]` occurs.

    TXLManager *manager = [TXLManager sharedManager];

The manager is the central point to access the information in the OpenTXL framework.

The application can keep trach of the processing activity performed by the manager, by assigning an object to the delegate of the TXLManager instance, which should implement the methods of the TXLManagerDelegateProtocol.

- (void)didStartProcessing {}
- (void)didEndProcessing {}


### Import Spatial Situations

The manager can import new information to the database by importing a spatial situation. This can be done either by importing situations one by one, or by batch importing of situations. 

	NSString *situation = ...
	NSDate *from = ...
	NSDate *to = ...
	[[TXLManager sharedManager] importSpatialSituationFromString:situation
                                                           inIntervalFrom:from
                                                                       to:to
                                                                    error:&error
	                     completionBlock:^(TXLRevision *rev, NSError *error){}];

Alternatively, a batch import can be made with a TXLManagerImportOperation object, which can contain multiple situations.

	NSString *situationPath = ...
	NSDate *from = ...
	NSDate *to = ...
	
	TXLManagerImportOperation *op = [[TXLManagerImportOperation alloc] initWithPath:situationPath
    intervalFrom:from
	to:to];        
    
    [[TXLManager sharedManager] applyOperations:[NSArray arrayWithObject:op]
                            withCompletionBlock:^(TXLRevision *rev, NSError *error){}];


### Continuous Query

In order to retrieve existing information a SPARQL query must be registered to the manager. The registration of a query returns a query handler, which provides access to the query's result (how this is done, is shown later) and continuously checks for updates in these results.

	NSString *queryName = ...
	NSString *queryText = ...
	TXLQueryHandle *query = [[TXLManager sharedManager] registerQueryWithName:queryName
			   expression:queryText
			   parameters:nil
				  options:nil
				    error:&error];		
	
If a query is no longer needed, it can be unregistered from the manager, in which case its results (if any) are marked as deleted and the query handle is dropped.

	NSString *queryName = ...					 
	[[TXLManager sharedManager] unregisterQueryWithName:queryName];

The handle of a query, which is already registered, can be obtained like this:

	NSString *queryName = ...	
	TXLQueryHandle *query = [[TXLManager sharedManager] queryWithName:queryName
																error:&error];

Finally, in order to have access to a query's result and be notified of its updates, an object has to be assigned as the delegate of the query handle. This object must implement the following method of the TXLContinuousQueryDelegateProtocol protocol.

- (void)continuousQuery:(TXLQueryHandle *)query
        hasNewResultSet:(TXLResultSet *)result
            forRevision:(TXLRevision *)revision;

The retrieval of the actual query's results can take place in the implementation of the previous method like that:

for (int i = 0; i < [result count]; i++) {
		NSDictionary *row = [resultSet valuesAtIndex:i];
		TXLMovingObjectSequence *mos = [resultSet movingObjectSequenceAtIndex:i];
}

## TXLContext

A context represents a scope, in which information is defined. It is used to distinguish the source of a certain statement and to apply permissions.

For example, a forecasting system could provide the context `txl://example.com/meteorology` and another could be `txl:///calender/holidays`. The name of each context consists of a protocol, a server and a list of path components. The context `txl://example.com/meteorology` has the components (`txl`, `example.com`, `meteorology`).
 
A context can be instantiated by the manager:

	[[TXLManager sharedManager] contextForProtocol:protocol
		                                      host:host
											  path:pathComponents
                                              error:error];

### Update a Context

There are two methods to update the information in a context. The first method does not need a moving object or time interval. Therefore, this method can be used, to update information, which does not have any temporal or spatial restrictions.

	// Given context
	TXLContext context = ...
	
    // create a statement
    TXLTerm *subject = [TXLTerm termWithString:@"subject"];
    TXLTerm *predicate = [TXLTerm termWithString:@"predicate"];
    TXLTerm *object = [TXLTerm termWithString:@"object"];
    
    TXLStatement *statement = [TXLStatement statementWithSubject:subject
                                                       predicate:predicate
                                                          object:object];
    
    NSArray *statements = [NSArray arrayWithObject:statement];
    
    // define the context
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
    														host:@"localhost"
    														path:[NSArray arrayWithObject:@"test"]
    														error:error];
   
    // update the context
    [context updateWithStatements:statements
             completionBlock:(void(^)(TXLRevision *rev, NSError *error){}];
                              
If the information should only be valid in a certain temporal or spatial extend, you have to define a moving object and a time interval in wich the context should be updated.
    
    // create a statement
    TXLTerm *subject = [TXLTerm termWithString:@"subject"];
    TXLTerm *predicate = [TXLTerm termWithString:@"predicate"];
    TXLTerm *object = [TXLTerm termWithString:@"object"];
    
    TXLStatement *statement = [TXLStatement statementWithSubject:subject
                                                       predicate:predicate
                                                          object:object];
    
    NSArray *statements = [NSArray arrayWithObject:statement];
    
    // create a moving object
    TXLMovingObject *mo = ...
    
    // define the context
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
    														host:@"localhost"
    														path:[NSArray arrayWithObject:@"test"]
    														error:error];
  
    // define the interval in wich the context should be updated
    NSDate *from = ...
    NSDate *to = ...
    
    // update the context
    [context updateWithStatements:statements
                     movingObject:mo
                   inIntervalFrom:from
                               to:to
				  completionBlock:void(^)(TXLRevision *rev, NSError *error){}];


With this method, the context is first cleared of the no more valid statements in the specified interval. That means, that all statements, which are valid in that interval and are not included in the `statements` list are *removed* (marked as removed). Then the moving object (`mo`) is restricted to the interval defined by `from` and `to`. After that, the statements , which are not already stored, with the moving object are stored in the context.

### Clear a Context

Analogous to the update, a context can be cleared completely

	[context clear:void(^)(TXLRevision *rev, NSError *error){}];


or in a defined interval

    NSDate *from = ...
    NSDate *to = ...
    
    [context clearInIntervalFrom:from
                              to:to
                 completionBlock:void(^)(TXLRevision *rev, NSError *error){}];


### Situation Definition

Apart from inserting new information, in the form of spatial situations, and retrieving existing information, the OpenTXL framework offer the prossibility to create new information from the existing data. This can be done through a "situation definition". The manager can define a situation by creating a "construct SPARQL query".

	// define the context
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
    														host:@"localhost"
    														path:[NSArray arrayWithObject:@"test"]
    														error:error];
	// Set the situation definition		
	BOOL success = [context setSituationDefinition:queryText 
									   withOptions:nil
											 error:&error];

The manager can remove the situation definition, if this is no longer valid. This means that the construct query is deleted and the resulted situations are marked as deleted.

	// define the context
    TXLContext *context = [[TXLManager sharedManager] contextForProtocol:@"txl"
    														host:@"localhost"
    														path:[NSArray arrayWithObject:@"test"]
    														error:error];

	// Remove the situation definition		
	[context removeSituationDefinition];


## TXLRevision

Each update of the state of the database results in a new revision. The new revision is given as an argument to the completion block of an update or clear operation. The revision marks the change in the database.

    TXLContext *ctx = ...
    NSArray *statements = ...

    [ctx updateWithStatements:statements
              completionBlock:void(^)(TXLRevision *rev, NSError *error){
                                // do something with the new revision
    }];

Each revision (except the first and the last) has a precursor and a successor. If the precursor is nil, the revision is the fist revision in the database, if the successor is nil, the revision is the head revision.

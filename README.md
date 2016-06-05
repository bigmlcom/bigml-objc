BigML Objective C Bindings
=====================

In this repository you'll find an open source @(language) client that
gives you a simple binding to interact with `BigML
<https://bigml.com>`.

BigML makes machine learning easy by taking care of the details
required to add data-driven decisions and predictive power to your
company. Unlike other machine learning services, BigML creates
`beautiful predictive models <https://bigml.com/gallery/models>`_ that
can be easily understood and interacted with.

The BigML @(language) bindings allow you to interact with `BigML.io
<https://bigml.io/>`, the API for BigML. You can use it to easily
create, retrieve, list, update, and delete BigML resources (i.e.,
sources, datasets, models and, predictions, and `many more
<https://bigml.com/developers/>`). Additionally, they also provide a
few ML algorithms that can be run locally, i.e. offline, such as to
make a prediction from a model, calculate an anomaly score, etc.

This module is licensed under the `Apache License, Version
2.0 <http://www.apache.org/licenses/LICENSE-2.0.html>`.


Support
-------

Please report problems and bugs to our `BigML.io issue
tracker <https://github.com/bigmlcom/io/issues>`.

Discussions about the different bindings take place in the general
`BigML mailing list <http://groups.google.com/group/bigml>`. Or join us
in our `Campfire chatroom <https://bigmlinc.campfirenow.com/f20a0>`.

Requirements
------------

`bigml-objec` is compatible with Modern Objective C and requires ARC.


Importing the module
--------------------

The easiest way to use the BigML Objective-C SDK is to drag the
`bigml-objc` folder on to your Xcode project. Alternatively, you can
drag the Xcode project bigml-objc.xcodeproj on to your Xcode project,
then set your project settings so it handles properly the header
and library path.

When you need to call a method from `bigml-objc` inside a file of
yours, put the following directive on top of it:

    #import "bigml-objc.h"

If you included bigml-objc.xcodeproj as a subproject of your Xcode
project, the above import directly will only work if you have
previously set the project settings to correctly handle the header
path.


Authentication
--------------

All the requests to BigML.io must be authenticated using your username
and `API key <https://bigml.com/account/apikey>` and are always
transmitted over HTTPS.

Knowing that, connecting to BigML is a breeze. You just need to
execute:


    BMLAPIConnector* api = [BMLAPIConnector connectorWithUsername:@"username"
                                                           apiKey:@"api-key"
                                                             mode:BMLModeProduction];


Alternatively, you can initialize the library to work in BigML's Sandbox
environment, which is meant for you to experiment free of charge:


    BMLAPIConnector* api = [BMLAPIConnector connectorWithUsername:@"username"
                                                           apiKey:@"api-key"
                                                             mode:BMLModeDevelopment];



Quick Start
-----------

Imagine that you want to use `this csv
file <https://static.bigml.com/csv/iris.csv>` containing the `Iris
flower dataset <http://en.wikipedia.org/wiki/Iris_flower_data_set>`_ to
predict the species of a flower whose ``sepal length`` is ``5`` and
whose ``sepal width`` is ``2.5``. A preview of the dataset is shown
below. It has 4 numeric fields: ``sepal length``, ``sepal width``,
``petal length``, ``petal width`` and a categorical field: ``species``.
By default, BigML considers the last field in the dataset as the
objective field (i.e., the field that you want to generate predictions
for).


    sepal length,sepal width,petal length,petal width,species
    5.1,3.5,1.4,0.2,Iris-setosa
    4.9,3.0,1.4,0.2,Iris-setosa
    4.7,3.2,1.3,0.2,Iris-setosa
    ...
    5.8,2.7,3.9,1.2,Iris-versicolor
    6.0,2.7,5.1,1.6,Iris-versicolor
    5.4,3.0,4.5,1.5,Iris-versicolor
    ...
    6.8,3.0,5.5,2.1,Iris-virginica
    5.7,2.5,5.0,2.0,Iris-virginica
    5.8,2.8,5.1,2.4,Iris-virginica

You can easily generate a prediction following these steps::


    BMLAPIConnector* api = [BMLAPIConnector connectorWithUsername:@"username"
                                                           apiKey:@"api-key"
                                                             mode:BMLModeDevelopment];

    BMLMinimalResource* resource =
    [[BMLMinimalResource alloc] initWithName:@"My Data Source"
                                        type:BMLResourceTypeFile
                                        uuid:@"./tests/data/iris.csv"
                                  definition:nil];

    // All requests are asynchronous and have a completion block
    [_api createResource:BMLResourceTypeSource
                          name:file
                       options:nil
                          from:resource
                    completion:^(id<BMLResource> resource, NSError* error) {

                           if (error == nil) {

                              [_api createResource:BMLResourceTypeDataset
                                              name:file
                                           options:nil
                                              from:resource
                                        completion:^(id<BMLResource> resource, NSError* error) {

                                              if (error == nil) {
                                                  [_api createResource:BMLResourceTypeModel
                                                                  name:file
                                                               options:nil
                                                                  from:resource
                                                            completion:^(id<BMLResource> resource, NSError* error) {
                                                                if (error == nil) {
                                                                    NSDictionary* pred = [BMLLocalPredictions
                                                                       localPredictionWithJSONModelSync:resource.jsonDefinition
                                                                                              arguments:@{@"sepal width" : @3.15,
                                                                                       @"petal length" : @4.07,
                                                                                        @"petal width" : @1.51}
                                                                                   options:@{@"byName" : @YES}];
                                                                       NSLog(@"First
                                                  Prediction: %@", pred);

                                                                }
                                        }];
                                    }
                               }];
                           }
                    }];



Dataset
-------

If you want to get some basic statistics for each field you can
retrieve the fields from the dataset as follows to get a dictionary
keyed by field id:


    [_api getResource:BMLResourceTypeDataset
                    uuid:datasetUuid
              completion:^(id<BMLResource> resource, NSError* error) {
                  if (error == nil) {
                      NSLog(@"Fields: %@", resource.jsonDefinition[@"fields"]);
                  }
    }];



The field filtering options are also available using a query string
expression, for instance:


    [_api listResource:BMLResourceTypeDataset
                    filters:@{@"limit" : @5}
              completion:^(NSArray* resources, NSError* error) {
                  //-- process resources or handle error
              }];



limits the number of fields that will be included in dataset to 20.

Model
-----

One of the greatest things about BigML is that the models that it
generates for you are fully white-boxed.  To get the explicit
tree-like predictive model for the example above:


    [_api getResource:BMLResourceTypeModel
                 uuid:modelUuid
           completion:^(id<BMLResource> resource, NSError* error) {
                  //-- process resource or handle error
              }];



Again, filtering options are also available using a query string
expression, for instance:


    [_api listResource:BMLResourceTypeModel
                    filters:@{@"limit" : @5}
              completion:^(NSArray* resources, NSError* error) {
                  //-- process resources or handle error
              }];



limits the number of fields that will be included in model to 5.

Projects
---------

A special kind of resource is ``project``. Projects are repositories
for resources, intended to fulfill organizational purposes. Each project can
contain any other kind of resource, but the project that a certain resource
belongs to is determined by the one used in the ``source``
they are generated from. Thus, when a source is created
and assigned a certain ``project_id``, the rest of resources generated from
this source will remain in this project.

The REST calls to manage the ``project`` resemble the ones used to manage the
rest of resources. When you create a ``project``:


[_api createResource:BMLResourceTypeProject
                name:@"my first project"
             options:nil
          completion:^(id<BMLResource> resource, NSError* error) {
        //-- process resource
}];



the resulting resource is similar to the rest of resources, although shorter::

    {'code': 201,
     'resource': 'project/54a1bd0958a27e3c4c0002f0',
     'location': 'http://bigml.io/andromeda/project/54a1bd0958a27e3c4c0002f0',
     'object': {'category': 0,
                'updated': '2014-12-29T20:43:53.060045',
                'resource': 'project/54a1bd0958a27e3c4c0002f0',
                'name': 'my first project',
                'created': '2014-12-29T20:43:53.060013',
                'tags': [],
                'private': True,
                'dev': None,
                'description': ''},
     'error': None}

and you can use its project id to get, update or delete it:


**Important**: Deleting a non-empty project will also delete **all resources**
assigned to it, so please be extra-careful when doing it.

Creating sources
----------------

To create a source from a local data file, you can use the create_source method. The only required parameter is the path to the data file (or file-like object). You can use a second optional parameter to specify any of the options for source creation described in the `BigML API documentation <https://bigml.com/developers>`.

Here’s a sample invocation::


    BMLMinimalResource* resource =
    [[BMLMinimalResource alloc] initWithName:@"My Data Source"
                                        type:BMLResourceTypeFile
                                        uuid:@"./tests/data/iris.csv"
                                  definition:nil];

    [_api createResource:BMLResourceTypeSource
                          name:@"TestCreateDatasource"
                       options:@{@"source_parser" : @{ @"header" : @NO, @"missing_tokens" : @[@"x"]}}
                          from:resource
                    completion:^(id<BMLResource> resource, NSError* error) {
                        //-- process resource or handle error
                    }];



or you may want to create a source from a file in a remote location::


    [_api createResource:BMLResourceTypeSource
                          name:@"TestCreateDatasourceFromRemoteFile"
                       options:@{@"remote" : @"s3://bigml-public/csv/iris.csv"}
                          from:resource
                    completion:^(id<BMLResource> resource, NSError* error) {
                        //-- process resource or handle error
                    }];



Creating datasets
-----------------

Once you have created a source, you can create a dataset. The only
required argument to create a dataset is a source id.  You can add any
of the optional arguments accepted by BigML and documented in `the
Datasets section of the Developer’s documentation
<https://bigml.com/developers/datasets>`.

For example, to create a dataset named “my dataset” with the first
1024 bytes of a source, you can execute the following call:


    [_api createResource:BMLResourceTypeDataset
                          name:@"TestCreateDatasetWithOptions"
                       options:@{@"size" : @1024}
                          from:source
                    completion:^(id<BMLResource> resource, NSError* error) {
                        //-- process resource or handle error
                    }];



You can also extract samples from an existing dataset and generate a
new one with them with the following call:


    [_api createResource:BMLResourceTypeDataset
                          name:@"TestCloneDatasetWithSampling"
                       options:@{@"sample_rate" : @0.8}
                          from:originDataset
                    completion:^(id<BMLResource> resource, NSError* error) {
                        //-- process resource or handle error
                    }];




Creating models
---------------

Once you have created a dataset you can create a model from it.  If
you don’t select one, the model will use the last field of the dataset
as objective field.  The only required argument to create a model is a
dataset id.  You can also include in the request all the additional
arguments accepted by BigML and documented in `the Models section of
the Developer’s documentation <https://bigml.com/developers/models>`.

For example, to create a model only including the first two fields and the first 10 instances in the dataset, you can use the following invocation::


    [_api createResource:BMLResourceTypeModel
                          name:@"TestCreateModel"
                       options:@{@"name" : @"My Model",
                         @"input_fields" : @[@"000000", @"000001"],
                                @"range" : @[1, 10]}
                          from:dataset
                    completion:^(id<BMLResource> resource, NSError* error) {
                        //-- process resource or handle error
                    }];



the model is scheduled for creation.

Creating clusters
-----------------

If your dataset has no fields showing the objective information to
predict for the training data, you can still build a cluster that will
group similar data around some automatically chosen points
(centroids).  Again, the only required argument to create a cluster is
the dataset id.  You can also include in the request all the
additional arguments accepted by BigML and documented in `the Clusters
section of the Developer’s documentation
<https://bigml.com/developers/clusters>`.

Let’s create a cluster from a given dataset:


    [_api createResource:BMLResourceTypeCluster
                          name:@"TestCreateCluster"
                       options:@{@"k" : @5}
                          from:dataset
                    completion:^(id<BMLResource> resource, NSError* error) {
                        //-- process resource or handle error
                    }];



that will create a cluster with 5 centroids.

Creating anomaly detectors
--------------------------

If your problem is finding the anomalous data in your dataset, you can
build an anomaly detector, that will use iforest to single out the
anomalous records. Again, the only required argument to create an
anomaly detector is the dataset id. You can also include in the
request all the additional arguments accepted by BigML and documented
in the `Anomaly detectors section of the Developer’s documentation
<https://bigml.com/developers/anomalies>`_.

Let’s create an anomaly detector from a given dataset:


    [_api createResource:BMLResourceTypeAnomaly
                          name:@"TestCreateAnomaly"
                       options:nil
                          from:dataset
                    completion:^(id<BMLResource> resource, NSError* error) {
                        //-- process resource or handle error
                    }];



Creating associations
---------------------

To find relations between the field values you can create an association
discovery resource. The only required argument to create an association
is a dataset id.
You can also
include in the request all the additional arguments accepted by BigML
and documented in the `Association section of the Developer's
documentation <https://bigml.com/developers/associations>`_.

For example, to create an association only including the first two fields and
the first 10 instances in the dataset, you can use the following
invocation:


    [_api createResource:BMLResourceTypeAssociation
                          name:@"TestCreateAssociation"
                       options:@{@"name" : @"My Association",
                         @"input_fields" : @[@"000000", @"000001"],
                                @"range" : @[1, 10]}
                          from:dataset
                    completion:^(id<BMLResource> resource, NSError* error) {
                        //-- process resource or handle error
                    }];



Associations can also be created from lists of datasets. Just use the
list of ids as the first argument in the api call:


    [_api createResource:BMLResourceTypeAssociation
                          name:@"TestCreateAssociation"
                       options:@{@"name" : @"My Association",
                         @"input_fields" : @[@"000000", @"000001"],
                                @"range" : @[1, 10]}
                          from:dataset
                    completion:^(id<BMLResource> resource, NSError* error) {
                        //-- process resource or handle error
                    }];



Creating predictions
--------------------

You can now use the model resource identifier together with some input parameters to ask for predictions, using the create_prediction method.
You can also give the prediction a name:


    [_api createResource:BMLResourceTypePrediction
                          name:@"TestCreateRemotePrediction"
                       options:@{@"name" : @"My Prediction",
                         @"input_data" : @{@"sepal length" : @5, @"sepal width" : @2.5}}
                          from:dataset
                    completion:^(id<BMLResource> resource, NSError* error) {
                        //-- process resource or handle error
                    }];



Creating centroids
------------------

To obtain the centroid associated to new input data, you can now use
the create_centroid method.  Give the method a cluster identifier and
the input data to obtain the centroid.  You can also give the centroid
predicition a name:


    [_api createResource:BMLResourceTypeCentroid
                          name:@"TestCreateRemoteCentroid"
                       options:@{@"name" : @"My Centroid",
                         @"input_data" : @{@"pregnancies" : @0,
                                            @"plasma glucose" : @118,
                                            @"blood pressure" : @84,
                                            @"triceps skin thickness" : @47,
                                            @"insulin" : @230,
                                            @"bmi" : @45.8,
                                            @"diabetes pedigree" : @0.551,
                                            @"age" : @31,
                                            @"diabetes" : @YES}}
                          from:dataset
                    completion:^(id<BMLResource> resource, NSError* error) {
                        //-- process resource or handle error
                    }];

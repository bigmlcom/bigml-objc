// Copyright 2014-2016 BigML
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License. You may obtain
// a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import <XCTest/XCTest.h>
#import "PredictiveCluster.h"
#import "bigmlObjcTestCase.h"
#import "bigmlObjcTester.h"

@interface bigmlObjcClusterPredictionTests : bigmlObjcTestCase

@end

@implementation bigmlObjcClusterPredictionTests

- (void)testLocalClusterPredictionByName {
    
    NSString* clusterId = [self.apiLibrary createAndWaitClusterFromDatasetId:self.apiLibrary.datasetId];
    NSDictionary* prediction = [self.apiLibrary localPredictionForClusterId:clusterId
                                                            data:@{@"sepal length": @2,
                                                                   @"sepal width": @1,
                                                                   @"petal length": @1,
                                                                   @"petal width": @1,
                                                                   @"species": @"Iris-versicolor"}
                                                          options:@{ @"byName" : @(YES) }];
    [self.apiLibrary deleteClusterWithIdSync:clusterId];
    XCTAssert(prediction);
}

- (void)testLocalClusterPrediction {
    
    NSString* clusterId = [self.apiLibrary createAndWaitClusterFromDatasetId:self.apiLibrary.datasetId];
    NSDictionary* prediction = [self.apiLibrary localPredictionForClusterId:clusterId
                                                            data:@{@"000000": @2,
                                                                   @"000001": @1,
                                                                   @"000002": @1,
                                                                   @"000003": @1,
                                                                   @"000004": @"Iris-versicolor"}
                                                         options:@{ @"byName" : @(NO) }];
    [self.apiLibrary deleteClusterWithIdSync:clusterId];
    XCTAssert(prediction);
}

- (void)testSpanTextCluster {
    
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [bundle pathForResource:@"spam-text" ofType:@"cluster"];
    NSData* clusterData = [NSData dataWithContentsOfFile:path];
    
    NSError* error = nil;
    NSDictionary* cluster = [NSJSONSerialization JSONObjectWithData:clusterData
                                                            options:0
                                                              error:&error];
    
    NSDictionary* prediction = [PredictiveCluster
                                predictWithJSONCluster:cluster
                                arguments:@{@"Message":@"Hello, how are you doing?",
                                            @"Type" : @"Ham"}
                                options:@{ @"byName" : @YES }];
    XCTAssert(prediction);
}

- (void)testSpanCluster {
    
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [bundle pathForResource:@"spam" ofType:@"cluster"];
    NSData* clusterData = [NSData dataWithContentsOfFile:path];
    
    NSError* error = nil;
    NSDictionary* cluster = [NSJSONSerialization JSONObjectWithData:clusterData
                                                            options:0
                                                              error:&error];
    
    NSDictionary* prediction =
    [PredictiveCluster predictWithJSONCluster:cluster
                                    arguments:@{@"Message":@"Hello, how are you doing?",
                                                @"Type" : @"Ham"}
                                      options:@{ @"byName" : @YES }];
    NSLog(@"CAT PREDICTIONfor 'Hello, how are you doing': %@", prediction);
    XCTAssert(prediction);
}

@end

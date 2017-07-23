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
#import "bigmlObjcTestCase.h"
#import "BMLLocalPredictions.h"
#import "bigmlObjcTester.h"

@interface bigmlObjcModelPredictionTests : bigmlObjcTestCase

@end

@implementation bigmlObjcModelPredictionTests

- (NSDictionary*)comparePredictionsWithModelId:(NSString*)modelId
                                  arguments:(NSDictionary*)arguments
                                    options:(NSDictionary*)options {
    
    NSDictionary* prediction1 = [self.apiLibrary localPredictionForModelId:modelId
                                                                      data:arguments
                                                                   options:options];

//-- Add here check against remote result, e.g.:
//    NSDictionary* prediction2 = [self.apiLibrary remotePredictionForId:modelId
//                                                          resourceType:@"model"
//                                                                  data:arguments
//                                                               options:options];
//    
//    XCTAssert(prediction1 && prediction2);
//    XCTAssert([self.apiLibrary comparePrediction:prediction1 andPrediction:prediction2],
//              @"Wrong predictions: %@ -- %@", prediction1[@"prediction"], prediction2[@"output"]);
//    XCTAssert([self.apiLibrary compareConfidence:prediction1 andConfidence:prediction2],
//              @"Wrong confidences: %@ -- %@", prediction1[@"confidence"], prediction2[@"confidence"]);
    
    return prediction1;
}

- (void)testStoredIrisModel {
    
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [bundle pathForResource:@"iris" ofType:@"model"];
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    NSError* error = nil;
    NSDictionary* model = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0
                                                               error:&error];
    
    NSDictionary* prediction = [BMLLocalPredictions
                                localPredictionWithJSONModelSync:model
                                arguments:@{ @"sepal length": @(6.02),
                                             @"sepal width": @(3.15),
                                             @"petal width": @(1.51),
                                             @"petal length": @(4.07) }
                                options:@{ @"byName" : @YES }];
    
    XCTAssert([prediction[@"prediction"] isEqualToString:@"Iris-versicolor"]);
}

- (void)testLocalIrisPredictionAgainstRemote1 {
    
    self.apiLibrary.csvFileName = @"iris.csv";
    NSString* modelId = [self.apiLibrary createAndWaitModelFromDatasetId:self.apiLibrary.datasetId
                                                                 options:nil];
    NSDictionary* prediction1 = [self comparePredictionsWithModelId:modelId
                                                       arguments:@{@"000001": @3.15,
                                                                   @"000002": @4.07,
                                                                   @"000003": @1.51}
                                                         options:@{ @"byName" : @(NO) }];
    
    NSDictionary* prediction2 = [self comparePredictionsWithModelId:modelId
                                                       arguments:@{@"sepal width": @3.15,
                                                                   @"petal length": @4.07,
                                                                   @"petal width": @1.51}
                                                         options:@{ @"byName" : @(YES) }];
    
    [self.apiLibrary deleteModelWithIdSync:modelId];
    
    XCTAssert([prediction1[@"prediction"] isEqualToString:@"Iris-versicolor"]);
    XCTAssert([self.apiLibrary comparePrediction:prediction1 andPrediction:prediction2]);
    XCTAssert([self.apiLibrary compareConfidence:prediction1 andConfidence:prediction2]);
}

- (void)testLocalIrisPredictionAgainstRemote2 {
    
    self.apiLibrary.csvFileName = @"iris.csv";
    NSString* modelId = [self.apiLibrary createAndWaitModelFromDatasetId:self.apiLibrary.datasetId
                                                                 options:nil];
    NSDictionary* prediction1 = [self comparePredictionsWithModelId:modelId
                                                       arguments:@{@"000001": @4.1,
                                                                   @"000002": @0.96,
                                                                   @"000003": @2.52}
                                                         options:@{ @"byName" : @(NO) }];
    
    NSDictionary* prediction2 = [self comparePredictionsWithModelId:modelId
                                                       arguments:@{@"sepal width": @4.1,
                                                                   @"petal length": @0.96,
                                                                   @"petal width": @2.52}
                                                         options:@{ @"byName" : @(YES) }];
    
    [self.apiLibrary deleteModelWithIdSync:modelId];
    
    XCTAssert([prediction1[@"prediction"] isEqualToString:@"Iris-setosa"]);
    XCTAssert([self.apiLibrary comparePrediction:prediction1 andPrediction:prediction2]);
    XCTAssert([self.apiLibrary compareConfidence:prediction1 andConfidence:prediction2]);
}

- (void)testLocalWinesPredictionAgainstRemote1 {
    
    self.apiLibrary.csvFileName = @"wines.csv";
    NSString* modelId = [self.apiLibrary createAndWaitModelFromDatasetId:self.apiLibrary.datasetId
                                                                 options:nil];
    NSDictionary* prediction1 = [self comparePredictionsWithModelId:modelId
                                                          arguments:@{@"000004": @32.0,
                                                                      @"000001": @"Cabernet Sauvignon",
                                                                      @"000000": @"France",
                                                                      @"000002": @90}
                                                            options:@{ @"byName" : @(NO) }];
    
    NSDictionary* prediction2 = [self comparePredictionsWithModelId:modelId
                                                          arguments:@{@"Price": @32.0,
                                                                      @"Grape": @"Cabernet Sauvignon",
                                                                      @"Country": @"France",
                                                                      @"Rating": @90}
                                                            options:@{ @"byName" : @(YES) }];
    
    [self.apiLibrary deleteModelWithIdSync:modelId];
    
    XCTAssert([self.apiLibrary compareFloat:[prediction1[@"prediction"] doubleValue] float:78.57]);
    XCTAssert([self.apiLibrary comparePrediction:prediction1 andPrediction:prediction2]);
    XCTAssert([self.apiLibrary compareConfidence:prediction1 andConfidence:prediction2]);
}

- (void)testLocalWinesPredictionAgainstRemote2 {
    
    self.apiLibrary.csvFileName = @"wines.csv";
    NSString* modelId = [self.apiLibrary createAndWaitModelFromDatasetId:self.apiLibrary.datasetId
                                                                 options:nil];
    NSDictionary* prediction1 = [self comparePredictionsWithModelId:modelId
                                                          arguments:@{@"000004": @5.8,
                                                                      @"000001": @"Pinot Grigio",
                                                                      @"000000": @"Italy",
                                                                      @"000002": @92}
                                                            options:@{ @"byName" : @(NO) }];
    
    NSDictionary* prediction2 = [self comparePredictionsWithModelId:modelId
                                                          arguments:@{@"Price": @5.8,
                                                                      @"Grape": @"Pinot Grigio",
                                                                      @"Country": @"Italy",
                                                                      @"Rating": @92}
                                                            options:@{ @"byName" : @(YES) }];
    
    [self.apiLibrary deleteModelWithIdSync:modelId];
    
    XCTAssert([self.apiLibrary compareFloat:[prediction1[@"prediction"] doubleValue] float:112.07]);
    XCTAssert([self.apiLibrary comparePrediction:prediction1 andPrediction:prediction2]);
    XCTAssert([self.apiLibrary compareConfidence:prediction1 andConfidence:prediction2]);
}

- (void)testLocalSpamPredictionAgainstRemote1 {
    
    self.apiLibrary.csvFileName = @"spam.tsv";
    NSString* modelId = [self.apiLibrary createAndWaitModelFromDatasetId:self.apiLibrary.datasetId
                                                                 options:nil];
    NSDictionary* prediction1 = [self comparePredictionsWithModelId:modelId
                                                       arguments:@{ @"000001": @"Hey there!" }
                                                         options:@{ @"byName" : @(NO) }];
    
    NSDictionary* prediction2 = [self comparePredictionsWithModelId:modelId
                                                       arguments:@{ @"Message": @"Hey there!" }
                                                         options:@{ @"byName" : @(YES) }];
    
    [self.apiLibrary deleteModelWithIdSync:modelId];
    
    XCTAssert([prediction1[@"prediction"] isEqualToString:@"ham"]);
    XCTAssert([self.apiLibrary comparePrediction:prediction1 andPrediction:prediction2]);
    XCTAssert([self.apiLibrary compareConfidence:prediction1 andConfidence:prediction2]);
}

- (void)testLocalSpamPredictionAgainstRemote2 {
    
    NSString* spam = @"Congratulations! Thanks to a good friend U have WON the £2,000 Xmas prize. 2 claim is easy, just call 08718726971 NOW! Only 10p per minute. BT-national-rate.";
    self.apiLibrary.csvFileName = @"spam.tsv";
    NSString* modelId = [self.apiLibrary createAndWaitModelFromDatasetId:self.apiLibrary.datasetId
                                                                 options:nil];
    NSDictionary* prediction1 = [self comparePredictionsWithModelId:modelId
                                                       arguments:@{ @"000001": spam }
                                                         options:@{ @"byName" : @(NO) }];
    
    NSDictionary* prediction2 = [self comparePredictionsWithModelId:modelId
                                                       arguments:@{ @"Message": spam }
                                                         options:@{ @"byName" : @(YES) }];
    
    [self.apiLibrary deleteModelWithIdSync:modelId];

    XCTAssert([prediction1[@"prediction"] isEqualToString:@"spam"]);
    XCTAssert([self.apiLibrary comparePrediction:prediction1 andPrediction:prediction2]);
    XCTAssert([self.apiLibrary compareConfidence:prediction1 andConfidence:prediction2]);
}

@end

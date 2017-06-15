//
//  bigmlObjcLogisticRegressionTests.m
//  bigml-objc
//
//  Created by sergio on 17/11/15.
//
//

#import <XCTest/XCTest.h>
#import "bigmlObjcTester.h"
#import "BMLEnums.h"
#import "BMLLocalPredictions.h"
#import "bigmlObjcTestCase.h"

@interface bigmlObjcLogisticRegressionTests : bigmlObjcTestCase

@end

@implementation bigmlObjcLogisticRegressionTests

/*
- (void)testLR {
    
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [bundle pathForResource:@"testAnomaly" ofType:@"json"];
    NSData* clusterData = [NSData dataWithContentsOfFile:path];
    
    NSError* error = nil;
    NSMutableDictionary* ensemble =
    [NSJSONSerialization JSONObjectWithData:clusterData
                                    options:NSJSONReadingMutableContainers
                                      error:&error];
    
    double score = [BMLLocalPredictions
                    localScoreWithJSONAnomalySync:ensemble
                    arguments:@{ @"sepal length": @(6.02),
                                 @"sepal width": @(3.15),
                                 @"petal width": @(1.51),
                                 @"petal length": @(4.07) }
                    options:@{ @"byName": @YES }];
    
    XCTAssert([self.apiLibrary compareFloat:score float:0.699]);
}

- (void)testWinesLR {
    
    self.apiLibrary.csvFileName = @"wines.csv";
    NSString* anomalyId = [self.apiLibrary createAndWaitAnomalyFromDatasetId:self.apiLibrary.datasetId];

    double score = [self.apiLibrary localAnomalyScoreForAnomalyId:anomalyId
                                                             data:@{ @"Price": @5.8,
                                                                     @"Grape": @"Pinot Grigio",
                                                                     @"Country": @"Italy",
                                                                     @"Rating": @91,
                                                                     @"Total Sales": @89.11}
                                                          options:@{ @"byName": @YES }];
    
    [self.apiLibrary deleteAnomalyWithIdSync:anomalyId];
    
    //-- score from web
    XCTAssert([self.apiLibrary compareFloat:score float:0.6018]);
}
*/
- (void)testIrisLR {
    
    self.apiLibrary.csvFileName = @"iris.csv";
    NSString* lrId = [self.apiLibrary createAndWaitLRFromDatasetId:self.apiLibrary.datasetId];
    
    
    NSDictionary* prediction = [self.apiLibrary
                                localLRPredictionForLRId:lrId
                                data:@{ @"sepal length": @(6.02),
                                             @"sepal width": @(3.15),
                                             @"petal width": @(1.51),
                                             @"petal length": @(4.07) }
                                options:@{ @"byName" : @YES }];

    /*
    double score2 = [self.apiLibrary localAnomalyScoreForAnomalyId:anomalyId
                                                      data:@{ @"sepal width": @4.1,
                                                              @"petal length": @0.96,
                                                              @"petal width": @2.52,
                                                              @"species": @"Iris-setosa"}
                                                   options:@{ @"byName": @YES }];

    [self.apiLibrary deleteAnomalyWithIdSync:anomalyId];

    XCTAssert([self.apiLibrary compareFloat:score1 float:0.6383]);
    XCTAssert([self.apiLibrary compareFloat:score2 float:0.7755]);
     */
}

@end

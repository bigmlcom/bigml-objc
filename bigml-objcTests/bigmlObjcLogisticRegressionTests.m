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
    NSLog(@"LR Prediction: %@", prediction);
}

@end

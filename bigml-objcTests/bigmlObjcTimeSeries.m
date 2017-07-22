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

@interface bigmlObjcTimeSeriesTests : bigmlObjcTestCase

@end

@implementation bigmlObjcTimeSeriesTests

- (void)testTimeSeriesCreation {
    
    self.apiLibrary.csvFileName = @"monthly-milk.csv";
    NSString* tsId = [self.apiLibrary createAndWaitTimeSeriesFromDatasetId:self.apiLibrary.datasetId];
    XCTAssert(tsId);
    
    NSDictionary* d = [self.apiLibrary
                    localForecastForTimeSeriesId:tsId
                    data:@{ @"sepal length": @(6.02),
                                 @"sepal width": @(3.15),
                                 @"petal width": @(1.51),
                                 @"petal length": @(4.07) }
                    options:@{ @"byName": @YES }];
    NSLog(@"FORECAST: %@", d);
}

@end

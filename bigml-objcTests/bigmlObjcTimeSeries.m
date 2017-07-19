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
}

@end

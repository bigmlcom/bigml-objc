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
                       data:@{ @"000001":@{
                                       @"horizon":@30,
                                       @"ets_models":@{
                                               @"indices":@[@0,@1,@2],
                                               @"names": @[@"A,A,N"],
                                               @"criterion": @"bic",
                                               @"limit":@2
                                               }
                                       }
                               }
                    options:@{ @"byName": @NO }];
    NSLog(@"FORECAST: %@", d);
}

@end

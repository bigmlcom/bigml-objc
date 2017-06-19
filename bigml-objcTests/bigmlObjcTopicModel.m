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

@interface bigmlObjcTopicModelTests : bigmlObjcTestCase

@end

@implementation bigmlObjcTopicModelTests

- (void)testTopicModelDistribution {
    
    self.apiLibrary.csvFileName = @"novel.txt";
    NSString* tmId = [self.apiLibrary createAndWaitTopicModelFromDatasetId:self.apiLibrary.datasetId];
    NSDictionary* prediction = [self.apiLibrary
                                localTMPredictionForTMId:tmId
                                data:@""
                                options:nil];
    NSLog(@"TM Prediction: %@", prediction);
}

@end

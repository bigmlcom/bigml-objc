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

#import "BMLResourceTypeIdentifier.h"

@interface bigmlObjcTimeSeriesTests : bigmlObjcTestCase

@end

@implementation bigmlObjcTimeSeriesTests

- (void)checkForecast:(NSDictionary*)f reference:(NSDictionary*)rf {
    
    XCTAssert(f.allKeys.count == rf.allKeys.count);
    for (NSString* fieldId in f.allKeys) {
        NSDictionary* item = f[fieldId][0];
        NSDictionary* rItem = rf[fieldId][0];
        XCTAssert([item[@"submodel"] isEqualTo:rItem[@"submodel"]]);
        XCTAssert([item[@"pointForecast"] isEqualTo:rItem[@"pointForecast"]]);
        NSInteger len = [item[@"pointForecast"] count];
        for (NSInteger i = 0; i < len; ++i) {
            XCTAssert(fabs([item[@"pointForecast"][i] floatValue] -
                           [rItem[@"pointForecast"][i] floatValue]) < 0.001);
        }
    }
}

- (BMLResourceFullUuid*)timeSeries:(NSString*)csv options:(NSDictionary*)options {
    
    static NSMutableDictionary* _tss = nil;
    if (!_tss) {
        _tss = [NSMutableDictionary new];
    }
    if (!_tss[csv]) {
        self.apiLibrary.csvFileName = csv;
        _tss[csv] = [self.apiLibrary
                     createAndWaitTimeSeriesFromDatasetId:self.apiLibrary.datasetId
                     options:options];
    }
    return _tss[csv];
}

- (BMLResourceFullUuid*)timeSeries1 {
    return [self timeSeries:@"monthly-milk.csv" options:nil];
}

- (BMLResourceFullUuid*)timeSeries2 {
    return [self timeSeries:@"grades.csv" options:nil];
}

- (NSDictionary*)referenceForecast:(BMLResourceUuid*)ts options:(NSDictionary*)options {
    
    static NSMutableDictionary* _rfs = nil;
    if (!_rfs) {
        _rfs = [NSMutableDictionary new];
    }
    if (!_rfs[ts]) {

        NSString* field = [[options[@"input_data"] allKeys] firstObject];
        BMLResourceUuid* rfId = [self.apiLibrary
                                 createAndWaitResourceOfType:BMLResourceTypeForecast
                                 from:ts
                                 type:BMLResourceTypeTimeSeries
                                 options:options];
        
        NSDictionary* fr = [self.apiLibrary getResourceOfType:BMLResourceTypeForecast
                                                         uuid:rfId];
        fr = fr[@"forecast"][@"result"][field][0];
        _rfs[ts] = @{ field :
                      @[ @{ @"pointForecast" : fr[@"point_forecast"],
                            @"submodel" : fr[@"model"] ?: @{}
                            }
                         ]
                  };
    }
    return _rfs[ts];
}

- (NSDictionary*)options1 {
    
    return @{ @"000001":@{
                      @"horizon":@30,
                      @"ets_models":@{
                              @"indices":@[@0,@1,@2],
                              @"names": @[@"A,A,N"],
                              @"criterion": @"bic",
                              @"limit":@2
                              }
                      }
              };
}

- (NSDictionary*)options2 {

    return @{ @"000005": @{ @"horizon": @5 }};
}

- (NSDictionary*)referenceForecast1 {
    
    
    return [self referenceForecast:[self timeSeries1]
                           options:@{ @"input_data": [self options1]}];
}

- (NSDictionary*)referenceForecast2 {
    
    
    return [self referenceForecast:[self timeSeries2]
                           options:@{ @"input_data": [self options2]}];
}

- (void)testTimeSeriesCreation1 {
    
    NSString* tsId = [self timeSeries1];
    XCTAssert(tsId);
    
    NSDictionary* d = [self.apiLibrary
                       localForecastForTimeSeriesId:tsId
                       data:[self options1]
                       options:@{ @"byName": @NO }];
    
    [self checkForecast:d reference:[self referenceForecast1]];
}

- (void)testTimeSeriesCreation1b {
    
    NSString* tsId = [self timeSeries1];
    XCTAssert(tsId);
    
    NSDictionary* d = [self.apiLibrary
                       localForecastForTimeSeriesId:tsId
                       data:[self options1]
                       options:@{ @"byName": @NO }];
    
    [self checkForecast:d reference:[self referenceForecast1]];
}


- (void)testTimeSeriesCreation2 {
    
    NSString* tsId = [self timeSeries2];
    XCTAssert(tsId);
    
    NSDictionary* d = [self.apiLibrary
                       localForecastForTimeSeriesId:tsId
                       data:[self options2]
                       options:@{ @"byName": @NO }];
    [self checkForecast:d reference:[self referenceForecast2]];
    NSLog(@"FORECAST: %@", d);
}

@end

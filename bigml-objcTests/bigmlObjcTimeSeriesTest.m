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

- (NSDictionary*)referenceForecast1 {
    
    static NSDictionary* _rf1 = nil;
    if (!_rf1) {
        NSString* rfId = [self.apiLibrary
                          createAndWaitResourceOfType:BMLResourceTypeForecast
                          from:[self timeSeries1]
                          type:BMLResourceTypeTimeSeries
                          options:@{ @"input_data": @{ @"000001":@{
                                                               @"horizon":@30,
                                                               @"ets_models":@{
                                                                       @"indices":@[@0,@1,@2],
                                                                       @"names": @[@"A,A,N"],
                                                                       @"criterion": @"bic",
                                                                       @"limit":@2
                                                                    }
                                                               }
                                                       }
                                     }];
        NSDictionary* fr = [self.apiLibrary getResourceOfType:BMLResourceTypeForecast
                                                         uuid:rfId];
        fr = fr[@"forecast"][@"result"][@"000001"][0];
        _rf1 = @{ @"000001" :
                      @[ @{ @"pointForecast" : fr[@"point_forecast"],
                            @"submodel" : fr[@"model"] ?: @{}
                            }
                         ]
                  };
    }
    return _rf1;
}

- (void)testTimeSeriesCreation1 {
    
    NSString* tsId = [self timeSeries1];
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
    
    [self checkForecast:d reference:[self referenceForecast1]];
}


- (void)testTimeSeriesCreation2 {
    
    NSString* tsId = [self timeSeries2];
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

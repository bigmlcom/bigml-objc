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

#import <CommonCrypto/CommonDigest.h>

NSString* md5Hash(NSDictionary* map) {

    NSError* error = NULL;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:map
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error != nil) {
        NSLog(@"Serialization Error: %@", error);
        return nil;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // Now create the MD5 hashs
    const char* ptr = [jsonString UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(ptr, (unsigned int)strlen(ptr), md5Buffer);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}


@interface bigmlObjcTimeSeriesTests : bigmlObjcTestCase

@end

@implementation bigmlObjcTimeSeriesTests

- (void)checkForecast:(NSDictionary*)f reference:(NSDictionary*)rf {
    
    XCTAssert(f.allKeys.count == rf.allKeys.count);
    for (NSString* fieldId in f.allKeys) {
        NSDictionary* item = f[fieldId][0];
        NSDictionary* rItem = rf[fieldId][0];
        XCTAssert([item[@"submodel"] isEqualToString:rItem[@"submodel"]]);
        XCTAssert([item[@"pointForecast"] count]  == [rItem[@"pointForecast"] count]);
        NSInteger len = [item[@"pointForecast"] count];
        for (NSInteger i = 0; i < len; ++i) {
            XCTAssert(fabs([item[@"pointForecast"][i] floatValue] -
                           [rItem[@"pointForecast"][i] floatValue]) < 0.001);
        }
    }
}

- (NSDictionary*)inputs:(NSInteger)n {
    
    static NSArray* _inputs = nil;
    if (!_inputs) {
        _inputs = @[@{ @"000001" : @{
                               @"horizon" : @30,
                               @"ets_models" : @{
                                       @"indices" : @[@0,@1,@2],
                                       @"names" : @[@"A,A,N"],
                                       @"criterion" : @"bic",
                                       @"limit" : @2
                                       }
                               }
                       },
                    @{ @"000005": @{ @"horizon": @5 }},
                    @{ @"000005" : @{
                               @"horizon" : @5,
                               @"ets_models" : @{
                                       @"criterion" : @"aic",
                                       @"names" : @[@"A,A,N"],
                                       @"limit" : @3
                                       }
                               }
                       },
                    @{ @"000005" : @{
                               @"horizon" : @5,
                               @"ets_models" : @{
                                       @"criterion" : @"aic",
                                       @"names" : @[@"M,N,N"],
                                       @"limit" : @3
                                       }
                               }
                       },
                    @{ @"000005" : @{
                               @"horizon" : @5,
                               @"ets_models" : @{
                                       @"criterion" : @"aic",
                                       @"names" : @[@"A,A,A"],
                                       @"limit" : @3
                                       }
                               }
                       },
                    @{ @"000005" : @{
                               @"horizon" : @5,
                               @"ets_models" : @{
                                       @"criterion" : @"aic",
                                       @"names" : @[@"M,N,A"],
                                       @"limit" : @3
                                       }
                               }
                       },
                    @{ @"000005" : @{
                               @"horizon" : @5,
                               @"ets_models" : @{
                                       @"criterion" : @"aic",
                                       @"names" : @[@"A,Ad,A"],
                                       @"limit" : @3
                                       }
                               }
                       },
                    @{ @"000005" : @{
                               @"horizon" : @5,
                               @"ets_models" : @{
                                       @"criterion" : @"aic",
                                       @"names" : @[@"A,A,N"],
                                       @"limit" : @3
                                       }
                               }
                       }
                    ];
    }
    return _inputs[n];
}

- (BMLResourceFullUuid*)timeSeries:(NSInteger)n options:(NSDictionary*)options {
    
    static NSArray* _files = nil;
    if (!_files) {
        _files = @[@"monthly-milk.csv",
                   @"grades.csv",
                   @"grades.csv",
                   @"grades.csv",
                   @"grades.csv",
                   @"grades.csv",
                   @"grades.csv",
                   @"grades.csv",
                   @"grades.csv",
                   @"grades.csv"];
    }

    NSString* csv = _files[n];
    NSString* hash = md5Hash(@{ @"csv" : csv, @"options" : options ?: @{}});
    
    static NSMutableDictionary* _tss = nil;
    if (!_tss) {
        _tss = [NSMutableDictionary new];
    }
    if (!_tss[hash]) {
        self.apiLibrary.csvFileName = csv;
        _tss[hash] = [self.apiLibrary
                      createAndWaitTimeSeriesFromDatasetId:self.apiLibrary.datasetId
                      options:options];
    }
    return _tss[hash];
}

- (NSDictionary*)referenceForecast:(BMLResourceUuid*)ts options:(NSDictionary*)options {
    
    static NSMutableDictionary* _rfs = nil;
    if (!_rfs) {
        _rfs = [NSMutableDictionary new];
    }
    
    NSString* hash = md5Hash(@{ @"ts" : ts, @"options" : options ?: @{}});
    if (!_rfs[hash]) {

        NSString* field = [[options[@"input_data"] allKeys] firstObject];
        BMLResourceUuid* rfId = [self.apiLibrary
                                 createAndWaitResourceOfType:BMLResourceTypeForecast
                                 from:ts
                                 type:BMLResourceTypeTimeSeries
                                 options:options];
        
        NSDictionary* fr = [self.apiLibrary getResourceOfType:BMLResourceTypeForecast
                                                         uuid:rfId];
        fr = fr[@"forecast"][@"result"][field][0];
        _rfs[hash] = @{ field :
                      @[ @{ @"pointForecast" : fr[@"point_forecast"],
                            @"submodel" : fr[@"model"] ?: @{}
                            }
                         ]
                  };
    }
    return _rfs[hash];
}

- (NSDictionary*)referenceForecast:(NSInteger)n {
    
    return [self referenceForecast:[self timeSeries:n options:nil]
                           options:@{ @"input_data": [self inputs:n]}];
}

- (void)runTest:(NSInteger)n {
    
    NSString* tsId = [self timeSeries:n options:nil];
    XCTAssert(tsId);
    
    NSDictionary* d = [self.apiLibrary
                       localForecastForTimeSeriesId:tsId
                       data:[self inputs:n]
                       options:@{ @"byName": @NO }];
    
    [self checkForecast:d reference:[self referenceForecast:n]];
}


- (void)testTimeSeriesCreation0 {
    [self runTest:0];
}

- (void)testTimeSeriesCreation1 {
    [self runTest:1];
}

- (void)testTimeSeriesCreation2 {
    [self runTest:2];
}

- (void)testTimeSeriesCreation3 {
    [self runTest:3];
}

- (void)testTimeSeriesCreation4 {
    [self runTest:4];
}

- (void)testTimeSeriesCreation5 {
    [self runTest:5];
}

- (void)testTimeSeriesCreation6 {
    [self runTest:6];
}

- (void)testTimeSeriesCreation7 {
    [self runTest:7];
}

@end

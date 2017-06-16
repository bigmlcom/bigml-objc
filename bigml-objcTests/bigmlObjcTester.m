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

#import "objc/message.h"
#import "bigmlObjcTester.h"
#import "bigmlObjcTestCredentials.h"
#import "BMLEnums.h"
#import "BMLLocalPredictions.h"
#import "BMLResourceTypeIdentifier.h"

@implementation bigmlObjcTester

- (instancetype)init {
    
    NSAssert([bigmlObjcTestCredentials username] &&
             [bigmlObjcTestCredentials apiKey], @"Please, provide correct username and apiKey");
    
    if (self = [super initWithUsername:[bigmlObjcTestCredentials username]
                                apiKey:[bigmlObjcTestCredentials apiKey]
                                  mode:BMLModeDevelopment
                                server:nil
                               version:nil]) {
    }
    return self;
}

- (void)dealloc {
    
    [self deleteDatasetWithIdSync:_datasetId];
}

- (NSString*)datasetId {
    
    NSAssert(_datasetId || _csvFileName, @"Neither dataset id not csv file specified");
    if (!_datasetId) {
        if (_csvFileName) {
            NSString* sourceId = [self createAndWaitSourceFromCSV:_csvFileName];
            if (sourceId) {
                _datasetId = [self createAndWaitDatasetFromSourceId:sourceId];
                [self deleteSourceWithIdSync:sourceId];
            }
        }
    }
    return _datasetId;
}

- (void)setCsvFileName:(NSString*)csvFileName {
    
    _csvFileName = csvFileName;
    _datasetId = nil;
}

- (BOOL)deleteResource:(BMLResourceUuid*)uuid type:(BMLResourceTypeIdentifier*)type {
    
    BOOL __block result = YES;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self deleteResource:type uuid:uuid completion:^(NSError* e) {
        
        if (e)
            result = NO;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result;
}

- (BOOL)deleteSourceWithIdSync:(NSString*)sourceId {
    
    return [self deleteResource:sourceId type:BMLResourceTypeSource];
}

- (BOOL)deleteDatasetWithIdSync:(NSString*)datasetId {
    
    return [self deleteResource:datasetId type:BMLResourceTypeDataset];
}

- (BOOL)deleteModelWithIdSync:(NSString*)modelId {
    
    return [self deleteResource:modelId type:BMLResourceTypeModel];
}

- (BOOL)deleteClusterWithIdSync:(NSString*)clusterId {
    
    return [self deleteResource:clusterId type:BMLResourceTypeCluster];
}

- (BOOL)deleteAnomalyWithIdSync:(NSString*)anomalyId {
    
    return [self deleteResource:anomalyId type:BMLResourceTypeAnomaly];
}

#pragma mark - Create and Wait
- (BMLResourceUuid*)createAndWaitSourceFromCSV:(NSString*)file {
    
    id<BMLResource> __block result = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSString* filePath = pathForResource(file);
    BMLMinimalResource* resource =
    [[BMLMinimalResource alloc] initWithName:file
                                        type:BMLResourceTypeFile
                                        uuid:filePath
                                  definition:nil];
    [self createResource:BMLResourceTypeSource
                    name:file
                 options:nil
                    from:resource
              completion:^(id<BMLResource> resource, NSError* error) {
                  
                  result = resource;
                  dispatch_semaphore_signal(semaphore);
              }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result.uuid;
}

- (NSDictionary*)getResourceOfType:(BMLResourceTypeIdentifier*)targetType
                              uuid:(BMLResourceUuid*)originId {
    
    NSDictionary* __block result = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self getResource:targetType uuid:originId completion:^(id<BMLResource> r, NSError* e) {

        if (!e)
            result = r.jsonDefinition;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result;
}
- (BMLResourceUuid*)createAndWaitResourceOfType:(BMLResourceTypeIdentifier*)targetType
                                           from:(BMLResourceUuid*)originId
                                           type:(BMLResourceTypeIdentifier*)originType {
    
    id<BMLResource> __block result = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    BMLMinimalResource* resource =
    [[BMLMinimalResource alloc] initWithName:originId
                                        type:originType
                                        uuid:originId
                                  definition:nil];
    [self createResource:targetType
                    name:@"testResource"
                 options:nil
                    from:resource
              completion:^(id<BMLResource> resource, NSError* error) {
                  
                  result = resource;
                  dispatch_semaphore_signal(semaphore);
              }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result.uuid;
}

- (BMLResourceUuid*)createAndWaitDatasetFromSourceId:(BMLResourceUuid*)srcId {
    
    return [self createAndWaitResourceOfType:BMLResourceTypeDataset
                                        from:srcId
                                        type:BMLResourceTypeSource];
}

- (BMLResourceUuid*)createAndWaitModelFromDatasetId:(BMLResourceUuid*)dataSetId {
    
    return [self createAndWaitResourceOfType:BMLResourceTypeModel
                                        from:dataSetId
                                        type:BMLResourceTypeDataset];
}

- (BMLResourceUuid*)createAndWaitClusterFromDatasetId:(BMLResourceUuid*)dataSetId {
    
    return [self createAndWaitResourceOfType:BMLResourceTypeCluster
                                        from:dataSetId
                                        type:BMLResourceTypeDataset];
}

- (BMLResourceUuid*)createAndWaitEnsembleFromDatasetId:(BMLResourceUuid*)dataSetId {
    
    return [self createAndWaitResourceOfType:BMLResourceTypeEnsemble
                                        from:dataSetId
                                        type:BMLResourceTypeDataset];
}

- (BMLResourceUuid*)createAndWaitAnomalyFromDatasetId:(BMLResourceUuid*)dataSetId {
    
    return [self createAndWaitResourceOfType:BMLResourceTypeAnomaly
                                        from:dataSetId
                                        type:BMLResourceTypeDataset];
}

- (BMLResourceUuid*)createAndWaitLRFromDatasetId:(BMLResourceUuid*)dataSetId {
    
    return [self createAndWaitResourceOfType:BMLResourceTypeLogisticRegression
                                        from:dataSetId
                                        type:BMLResourceTypeDataset];
}

//- (BMLResourceUuid*)createAndWaitPredictionFromId:(BMLResourceUuid*)resourceId
//                              resourceType:(BMLResourceTypeIdentifier*)resourceType
//                                 inputData:(NSDictionary*)inputData {
//    
//    return [self createAndWaitResourceOfType:BMLResourceTypePrediction
//                                        from:resourceId
//                                        type:BMLResourceTypeDataset];
//}
//
//#pragma mark - Remote Prediction Helpers
//- (NSDictionary*)remotePredictionForId:(BMLResourceUuid*)resourceId
//                          resourceType:(BMLResourceTypeIdentifier*)resourceType
//                                  data:(NSDictionary*)inputData
//                               options:(NSDictionary*)options {
//    
//    if (!options || [options[@"method"] intValue] == BMLPredictionMethodPlurality) {
//        self.options = @{ @"combiner" : @(BMLPredictionMethodPlurality)};
//    } else if ([options[@"method"] intValue] == BMLPredictionMethodConfidence) {
//        self.options = @{ @"combiner" : @(ML4iOSPredictionMethodConfidence)};
//    } else if ([options[@"method"] intValue] == ML4iOSPredictionMethodProbability) {
//        self.options = @{ @"combiner" : @(ML4iOSPredictionMethodProbability)};
//    } else if ([options[@"method"] intValue] == ML4iOSPredictionMethodThreshold) {
//        self.options = @{ @"combiner" : @(ML4iOSPredictionMethodThreshold),
//                          @"threshold" : @{ @"k" : options[@"threshold-k"],
//                                             @"class" : options[@"threshold-category"]}};
//    }
//    
//    NSString* predictionId = [self createAndWaitPredictionFromId:resourceId
//                                                    resourceType:resourceType
//                                                       inputData:inputData];
//    NSInteger code = 0;
//    NSDictionary* prediction = [self getPredictionWithIdSync:predictionId statusCode:&code];
//    return prediction;
//}

#pragma mark - Local Prediction Helpers
- (NSDictionary*)localPredictionForModelId:(BMLResourceUuid*)modelId
                                      data:(NSDictionary*)inputData
                                    options:(NSDictionary*)options {
    
    if ([modelId length] > 0) {
        
        NSDictionary* model = [self getResourceOfType:BMLResourceTypeModel uuid:modelId];
        NSDictionary* prediction =
        [BMLLocalPredictions localPredictionWithJSONModelSync:model
                                                       arguments:inputData
                                                         options:options];
        return prediction;
    }
    return nil;
}

//- (NSDictionary*)localPredictionForEnsembleId:(BMLResourceUuid*)ensembleId
//                                         data:(NSDictionary*)inputData
//                                      options:(NSDictionary*)options {
//    
//    if ([ensembleId length] > 0) {
//        
//        NSDictionary* ensemble = [self getResourceOfType:BMLResourceTypeEnsemble uuid:ensembleId];
//        NSDictionary* prediction =
//        [BMLLocalPredictions localPredictionWithJSONEnsembleSync:ensemble
//                                                          arguments:inputData
//                                                            options:options
//                                                             ml4ios:self];
//        return prediction;
//    }
//    return nil;
//}

- (NSDictionary*)localPredictionForClusterId:(BMLResourceUuid*)clusterId
                                        data:(NSDictionary*)inputData
                                     options:(NSDictionary*)options {
    
    if ([clusterId length] > 0) {
        
        NSDictionary* cluster = [self getResourceOfType:BMLResourceTypeCluster uuid:clusterId];
        NSDictionary* prediction =
        [BMLLocalPredictions localCentroidsWithJSONClusterSync:cluster
                                                        arguments:inputData
                                                          options:options];
        return prediction;
    }
    return nil;
}

- (double)localAnomalyScoreForAnomalyId:(BMLResourceUuid*)anomalyId
                                   data:(NSDictionary*)inputData
                                options:(NSDictionary*)options {
    
    if ([anomalyId length] > 0) {
        
        NSDictionary* anomaly = [self getResourceOfType:BMLResourceTypeAnomaly uuid:anomalyId];
        double score =
        [BMLLocalPredictions localScoreWithJSONAnomalySync:anomaly
                                                    arguments:inputData
                                                      options:options];
        return score;
    }
    return NAN;
}

- (NSDictionary*)localLRPredictionForLRId:(BMLResourceUuid*)LRId
                                   data:(NSDictionary*)inputData
                                options:(NSDictionary*)options {
    
    if ([LRId length] > 0) {
        
        NSDictionary* LR = [self getResourceOfType:BMLResourceTypeLogisticRegression
                                              uuid:LRId];
        id lr =
        [BMLLocalPredictions localLRPredictionWithJSONLRSync:LR
                                                   arguments:inputData
                                                     options:options];
        NSLog(@"LR: %@", [lr description]);
        return lr;
    }
    return @{};
}


#pragma mark - Prediction Result Check Helpers

- (BOOL)compareFloat:(double)f1 float:(float)f2 {
    float eps = 0.01;
    return ((f1 - eps) < f2) && ((f1 + eps) > f2);
}

- (BOOL)comparePrediction:(NSDictionary*)prediction1 andPrediction:(NSDictionary*)prediction2 {
    return [prediction1[@"output"]?:prediction1[@"prediction"]
            isEqual:prediction2[@"output"]?:prediction2[@"prediction"]];
}

- (BOOL)compareConfidence:(NSDictionary*)prediction1 andConfidence:(NSDictionary*)prediction2 {
    
    double confidence1 = [prediction1[@"confidence"] doubleValue];
    double confidence2 = [prediction2[@"confidence"] doubleValue];
    return [self compareFloat:confidence1 float:confidence2];
}

@end

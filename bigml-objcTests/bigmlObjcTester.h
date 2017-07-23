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

#import <Foundation/Foundation.h>
#import "BMLAPIConnector.h"

@interface bigmlObjcTester : BMLAPIConnector

@property (nonatomic, strong) NSString* datasetId;
@property (nonatomic, strong) NSString* csvFileName;

- (BMLResourceUuid*)createAndWaitSourceFromCSV:(NSString*)path;
- (BMLResourceUuid*)createAndWaitDatasetFromSourceId:(BMLResourceUuid*)srcId
                                             options:(NSDictionary*)options;
- (BMLResourceUuid*)createAndWaitModelFromDatasetId:(BMLResourceUuid*)dataSetId
                                            options:(NSDictionary*)options;
- (BMLResourceUuid*)createAndWaitClusterFromDatasetId:(BMLResourceUuid*)dataSetId
                                              options:(NSDictionary*)options;
- (BMLResourceUuid*)createAndWaitEnsembleFromDatasetId:(BMLResourceUuid*)dataSetId
                                               options:(NSDictionary*)options;
- (BMLResourceUuid*)createAndWaitAnomalyFromDatasetId:(BMLResourceUuid*)dataSetId
                                              options:(NSDictionary*)options;
- (BMLResourceUuid*)createAndWaitLRFromDatasetId:(BMLResourceUuid*)dataSetId
                                         options:(NSDictionary*)options;
- (BMLResourceUuid*)createAndWaitTopicModelFromDatasetId:(BMLResourceUuid*)dataSetId
                                                 options:(NSDictionary*)options;
- (BMLResourceUuid*)createAndWaitTimeSeriesFromDatasetId:(BMLResourceUuid*)dataSetId
                                                 options:(NSDictionary*)options;

//- (BMLResourceUuid*)createAndWaitPredictionFromId:(BMLResourceUuid*)modelId
//                                     resourceType:(BMLResourceUuid*)resourceTyp
//                                        inputData:(NSDictionary*)inputData;

//- (NSDictionary*)remotePredictionForId:(BMLResourceUuid*)resourceId
//                          resourceType:(BMLResourceTypeIdentifier*)resourceType
//                                  data:(NSDictionary*)inputData
//                               options:(NSDictionary*)options;

- (NSDictionary*)localPredictionForModelId:(BMLResourceUuid*)modelId
                                      data:(NSDictionary*)inputData
                                   options:(NSDictionary*)options;

//- (NSDictionary*)localPredictionForEnsembleId:(BMLResourceUuid*)ensembleId
//                                         data:(NSDictionary*)inputData
//                                      options:(NSDictionary*)options;

- (NSDictionary*)localPredictionForClusterId:(BMLResourceUuid*)clusterId
                                        data:(NSDictionary*)inputData
                                     options:(NSDictionary*)options;

- (double)localAnomalyScoreForAnomalyId:(BMLResourceUuid*)anomalyId
                                   data:(NSDictionary*)inputData
                                options:(NSDictionary*)options;

- (NSDictionary*)localLRPredictionForLRId:(BMLResourceUuid*)LRId
                              data:(NSDictionary*)inputData
                           options:(NSDictionary*)options;

- (NSDictionary*)localTMPredictionForTMId:(BMLResourceUuid*)TMId
                                     data:(NSString*)inputData
                                  options:(NSDictionary*)options;

- (NSDictionary*)localForecastForTimeSeriesId:(BMLResourceUuid*)TSId
                                         data:(NSDictionary*)inputData
                                      options:(NSDictionary*)options;

- (BOOL)deleteSourceWithIdSync:(NSString*)sourceId;
- (BOOL)deleteDatasetWithIdSync:(NSString*)datasetId;
- (BOOL)deleteModelWithIdSync:(NSString*)modelId;
- (BOOL)deleteClusterWithIdSync:(NSString*)clusterId;
- (BOOL)deleteAnomalyWithIdSync:(NSString*)anomalyId;

- (BOOL)compareFloat:(double)f1 float:(float)f2;
- (BOOL)comparePrediction:(NSDictionary*)prediction1 andPrediction:(NSDictionary*)prediction2;
- (BOOL)compareConfidence:(NSDictionary*)prediction1 andConfidence:(NSDictionary*)prediction2;

@end

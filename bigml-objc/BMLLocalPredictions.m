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

#import "BMLLocalPredictions.h"
#import "PredictiveModel.h"
#import "PredictiveCluster.h"
#import "PredictiveEnsemble.h"
#import "Anomaly.h"

@implementation BMLLocalPredictions

+ (NSDictionary*)localPredictionWithJSONModelSync:(NSDictionary*)jsonModel
                                        arguments:(NSDictionary*)args
                                          options:(NSDictionary*)options {
    
    return [PredictiveModel predictWithJSONModel:jsonModel arguments:args options:options];
}

+ (NSDictionary*)localPredictionWithJSONEnsembleModelsSync:(NSArray*)models
                                                 arguments:(NSDictionary*)args
                                                   options:(NSDictionary*)options
                                             distributions:distributions {
    
    return [PredictiveEnsemble predictWithJSONModels:models
                                                args:args
                                             options:options
                                       distributions:distributions];
}

+ (NSDictionary*)localCentroidsWithJSONClusterSync:(NSDictionary*)jsonCluster
                                         arguments:(NSDictionary*)args
                                           options:(NSDictionary*)options {
    
    return [PredictiveCluster predictWithJSONCluster:jsonCluster
                                           arguments:args
                                             options:options];
}

+ (double)localScoreWithJSONAnomalySync:(NSDictionary*)jsonAnomaly
                              arguments:(NSDictionary*)args
                                options:(NSDictionary*)options {
    
    return [[[Anomaly alloc] initWithJSONAnomaly:jsonAnomaly]
            score:args
            options:options];
}

@end

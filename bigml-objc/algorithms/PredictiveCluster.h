// Copyright 2014-2015 BigML
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

/** A local Predictive Cluster.
 
 This module defines a Cluster to make predictions (centroids) locally or
 embedded into your application without needing to send requests to
 BigML.io.
 
 This module cannot only save you a few credits, but also enormously
 reduce the latency for each prediction and let you use your models
 offline.
 
**/

@interface PredictiveCluster : NSObject

+ (NSDictionary*)predictWithJSONCluster:(NSDictionary*)jsonCluster
                              arguments:(NSDictionary*)args
                                options:(NSDictionary*)options;

@end

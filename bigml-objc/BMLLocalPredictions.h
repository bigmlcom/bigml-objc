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

/**
 * A convenience class to use BigML algorithms for local predictions.
**/
@interface BMLLocalPredictions : NSObject

/**
 * Computes a local prediction based on the given model.
 * @param jsonModel The model to use to create the prediction
 * @param args The arguments to create the prediction
 * @param options A dictionary of options that will affect the prediction.
          This is a list of allowed options:
            - byName: set to YES when specifying arguments by their names
                      (vs. field IDs)
 * @return The result of the prediction
 */
+ (NSDictionary*)localPredictionWithJSONModelSync:(NSDictionary*)jsonModel
                                        arguments:(NSDictionary*)args
                                          options:(NSDictionary*)options;

/** 
 * Computes a local prediction from the given set of models/distributions.
 * This method is useful, e.g., if you store locally all the models that belong to
 * an ensemble to avoid the latency of getting them from the server (as 
 * localPredictionWithJSONModelSync: does).
 * In such case, you can also pass a list of distributions from the ensemble,
 * which are stored in the jsonEnsemble[@"models"][@"distribution"] element.
 *
 * For a description of arguments and options, see localPredictionWithJSONModelSync:
 */
+ (NSDictionary*)localPredictionWithJSONEnsembleModelsSync:(NSDictionary*)jsonEnsemble
                                                 arguments:(NSDictionary*)args
                                                   options:(NSDictionary*)options
                                             distributions:(NSArray*)distributions;

/**
 * Computes local centroids using the cluster and args passed as parameters
 * @param jsonCluster The cluster to use to create the prediction
 * @param args The arguments to create the prediction
 * @param options A dictionary of options that will affect the prediction.
 This is a list of allowed options:
 - byName: set to YES when specifying arguments by their names
 (vs. field IDs)
 * @return The result of the prediction
 */
+ (NSDictionary*)localCentroidsWithJSONClusterSync:(NSDictionary*)jsonCluster
                                         arguments:(NSDictionary*)args
                                           options:(NSDictionary*)options;

/**
 * Computes local score using the anomaly and args passed as parameters
 * @param jsonAnomaly The anomaly to use to calculate the score
 * @param args The arguments to create the score
 * @param options A dictionary of options that will affect the scoring.
 This is a list of allowed options:
 - byName: set to YES when specifying arguments by their names
 (vs. field IDs)
 * @return The score
 */
+ (double)localScoreWithJSONAnomalySync:(NSDictionary*)jsonAnomaly
                              arguments:(NSDictionary*)args
                                options:(NSDictionary*)options;

/**
 * Computes local LR prediction using the anomaly and args passed as parameters
 * @param jsonAnomaly The anomaly to use to calculate the score
 * @param args The arguments to create the score
 * @param options A dictionary of options that will affect the scoring.
 This is a list of allowed options:
 - byName: set to YES when specifying arguments by their names
 (vs. field IDs)
 * @return The prediction
 */
+ (NSDictionary*)localLRPredictionWithJSONLRSync:(NSDictionary*)jsonLR
                                       arguments:(NSDictionary*)args
                                         options:(NSDictionary*)options;


@end

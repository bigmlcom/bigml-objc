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

@class ML4iOS;

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
 * Computes local prediction based on the given ensemble.
 * This method will get all the models belonging to the ensemble from the server.
 *
 * @param jsonEnsemble The ensemble to use to create the prediction
 * @param arguments The arguments to create the prediction
 * @param options A dictionary of options that will affect the prediction.
          This is a list of allowed options:
            - byName: set to YES when specifying arguments by their names
              (vs. field IDs)
              Default is NO.
            - strategy: a strategy to handle missing values; this should be
              one of the value of the BMLMissingStrategy type (currently,
              MissingStrategyProportional is only supported for classifications,
              not regressions).
              Default is MissingStrategyLastPrediction.
            - method: the method to use; a value from BMLPredictionMethod type.
              See the BMLPredictionMethod definition for more allowed values.
              Default is BMLPredictionMethodPlurality.
            - threshold: the vote threshold to use when method is
              BMLPredictionMethodThreshold.
            - multiple: for classification problems, this parameter specifies
              the number of categories to include in the distribution of the 
              predicted node, e.g.:
                 [{'prediction': 'Iris-setosa',
                   'confidence': 0.9154
                   'probability': 0.97
                   'count': 97},
                  {'prediction': 'Iris-virginica',
                   'confidence': 0.0103
                   'probability': 0.03,
                   'count': 3}]
              Default value is 0, so no distributions are provided.
              Pass NSUIntegerMax if you want them all.
 
            Example:
              @{ @"byName" : @(YES),
                 @"strategy" : @(MissingStrategyProportional),
                 @"multiple" : @(3) }

 * @param ml4ios An ML4iOS instance that is used to retrieve that models that 
          make the ensemble.
 * @return The result of the prediction
 */
+ (NSDictionary*)localPredictionWithJSONEnsembleSync:(NSDictionary*)jsonEnsemble
                                           arguments:(NSDictionary*)args
                                             options:(NSDictionary*)options
                                              ml4ios:(ML4iOS*)ml4ios;

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

@end

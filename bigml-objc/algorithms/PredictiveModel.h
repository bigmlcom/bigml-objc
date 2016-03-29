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
#import "FieldResource.h"
#import "PredictionTree.h"

/*
 * A local Predictive Model.
 
 * This module defines a Model to make predictions locally or
 * embedded into your application without needing to send requests to
 * BigML.io.
 
 * This module cannot only save you a few credits, but also enormously
 * reduce the latency for each prediction and let you use your models
 * offline.
 */

/**
 * A lightweight wrapper around a Tree model.
 *
 * Uses a BigML remote model to build a local version that can be used to
 * generate prediction locally.
 *
 */
@interface PredictiveModel : FieldResource

/**
 * Makes a prediction based on a number of field values.
 *
 * By default the input fields must be keyed by field name but you can use
 *  `byName` to input them directly keyed by id.
 *
 * @param arguments: Input data to be predicted
 *
 * @param options: a map of options that will determine how the prediction
 *        is calculated. It may include the following key/values:
 *
 *        - missingStrategy: LAST_PREDICTION|PROPORTIONAL missing strategy for
 *                           missing fields
 *
 *        - multiple: For categorical fields, it will make this method return
 *                    the categories in the distribution of the predicted node as a
 *                    list of dicts, e.g.:
 *
 *          [{'prediction': 'Iris-setosa',
 *              'confidence': 0.9154
 *              'probability': 0.97
 *              'count': 97},
 *           {'prediction': 'Iris-virginica',
 *              'confidence': 0.0103
 *              'probability': 0.03,
 *              'count': 3}]
 *
 *  The value of this argument is an integer specifying
 *  the maximum number of categories to be returned. If NSUIntegerMax,
 *  the entire distribution in the node will be returned.
 *
 * This method will return an NSArray of TreePrediction objects.
 */
- (NSArray*)predictWithArguments:(NSDictionary*)arguments
                         options:(NSDictionary*)options;

/**
 * Creates a local prediction using the model and args passed as parameters
 * @param jsonModel The model to use to create the prediction
 * @param args The arguments to create the prediction as a string
 * @param options a map of options that will determine how the prediction
 *        is calculated. See predictWithArguments:options: for a list of them.
 * @return The result of the prediction encoded in a NSDictionary
 */
+ (NSDictionary*)predictWithJSONModel:(NSMutableDictionary*)jsonModel
                            inputData:(NSString*)args
                              options:(NSDictionary*)options;

/**
 * Creates a local prediction using the model and args passed as parameters
 * @param jsonModel The model to use to create the prediction
 * @param arguments An NSDictionary containing the arguments to create the prediction
 * @param options a map of options that will determine how the prediction
 *        is calculated. See predictWithArguments:options: for a list of them.
 * @return The result of the prediction encoded in a NSDictionary
 */

+ (NSDictionary*)predictWithJSONModel:(NSDictionary*)jsonModel
                            arguments:(NSDictionary*)args
                              options:(NSDictionary*)options;

@end

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

#import "PredictionCentroid.h"


@implementation PredictionCentroid

- (instancetype)initWithCluster:(NSDictionary*)dict {

    if (self = [super init]) {
        
        self.center = dict[@"center"];
        self.count = [dict[@"count"] intValue];
        self.centroidId = [dict[@"id"] intValue];
        self.name = dict[@"name"];
    }
    return self;
}

/**
 * Squared distance from the given input data to the centroid
 *
 * @param {object} inputData Object describing the numerical or categorical
 *                           input data per field
 * @param {object} termSets Object containing the array of unique terms per
 *                          field
 * @param {object} scales Object containing the scaling factor per field
 * @param {number} stopDistance2 Maximum allowed distance. If reached,
 *                               the algorithm stops computing the actual
 *                               squared distance
 */

- (float) distance2WithInputData:(NSDictionary*)inputData
                     uniqueTerms:(NSMutableDictionary*)termSets
                          scales:(NSDictionary*)scales
                 nearestDistance:(float)stopDistance2 {
    
    float distance2 = 0.0;
    NSMutableArray* terms = nil;
    
    for (NSString* fieldId in [self.center allKeys]) {
     
        id value = self.center[fieldId];
        if ([value isKindOfClass:[NSArray class]]) {
            
            terms = termSets[fieldId] ?: [NSMutableArray array];
            distance2 += [self cosineDistance2WithTerms:terms
                                          centroidTerms:value
                                                  scale:[scales[fieldId] floatValue]];
            
        } else {
            
            if ([value isKindOfClass:[NSString class]]) {

                if (![inputData[fieldId] isEqualToString:value]) {
                    distance2 += pow([scales[fieldId] floatValue], 2);
                }
            } else {
                
                distance2 += pow(([inputData[fieldId] floatValue] - [value floatValue]) * [scales[fieldId] floatValue], 2);

            }
        }
        if (stopDistance2 <= distance2) {
            return NAN;
        }
        
    }
    return distance2;
}

/**
 * Returns the square of the distance defined by cosine similarity
 *
 * @param {array} terms Array of input terms
 * @param {array} centroidTerms Array of terms used in the centroid field
 * @param {number} scale Scaling factor for the field
 */
- (float)cosineDistance2WithTerms:(NSArray*)terms centroidTerms:(NSArray*)centroidTerms scale:(float)scale {
 
    int inputCount = 0;
    
    if (terms.count == 0 && centroidTerms.count == 0)
        return 0.0;
    
    if (terms.count == 0 || centroidTerms.count == 0)
        return pow(scale, 2);
    
    for (NSString* term in centroidTerms) {
     
        if ([terms indexOfObject:term] > -1) {
            inputCount++;
        }
    }
    
    float cosineSimilarity = (inputCount / sqrt(terms.count * centroidTerms.count));
    float similarityDistance = scale * (1 - cosineSimilarity);
    return pow(similarityDistance, 2);
}



@end

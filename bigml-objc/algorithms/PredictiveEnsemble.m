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

#import "PredictiveEnsemble.h"
#import "MultiModel.h"
#import "MultiVote.h"
#import "BMLEnums.h"

@implementation PredictiveEnsemble {
    
    NSArray* _distributions;
    NSArray* _multiModels;
}

- (instancetype)initWithModels:(NSArray*)models
                     maxModels:(NSUInteger)maxModels
                 distributions:(NSArray*)distributions {
    
    NSAssert([models isKindOfClass:[NSArray class]] &&
             [models count] > 0,
             @"initWithModels:threshold:distributions: contract unfulfilled");

    if (self = [super init]) {
        
        _multiModels = [self multiModelsFromModels:models maxModels:maxModels];
        _isReadyToPredict = YES;
        _distributions = distributions;
    }
    return self;
}

- (instancetype)initWithModels:(NSArray*)models
                     maxModels:(NSUInteger)maxModels {
    
    return [self initWithModels:models maxModels:maxModels distributions:nil];
}

- (NSDictionary*)predictWithArguments:(NSDictionary*)inputData
                              options:(NSDictionary*)options {
    
    NSAssert(_isReadyToPredict,
             @"You should wait for .isReadyToPredict to be YES before calling this method");

    BMLPredictionMethod method = [options[@"method"] ?: @(BMLPredictionMethodPlurality) intValue];
    BMLMissingStrategy missingStrategy = [options[@"strategy"] ?: @(BMLMissingStrategyLastPrediction) intValue];
    BOOL byName = [options[@"byName"] ?: @(NO) boolValue];
    BOOL confidence = [options[@"confidence"] ?: @(YES) boolValue];
    BOOL distribution = [options[@"distribution"] ?: @(NO) boolValue];
    BOOL count = [options[@"count"] ?: @(NO) boolValue];
    BOOL median = [options[@"median"] ?: @(NO) boolValue];
    BOOL min = [options[@"min"] ?: @(NO) boolValue];
    BOOL max = [options[@"max"] ?: @(NO) boolValue];
    
    MultiVote* votes = [MultiVote new];
    for (MultiModel* multiModel in _multiModels) {
        MultiVote* partialVote = [multiModel generateVotes:inputData
                                                    byName:byName
                                           missingStrategy:missingStrategy
                                                 median:median];
        if (median) {
            [partialVote addMedian];
        }
        [votes extendWithMultiVote:partialVote];
    }

    return [votes combineWithMethod:method
                         confidence:confidence
                    distribution:distribution
                           count:count
                          median:median
                             min:min
                             max:max
                            options:options];
}

+ (NSDictionary*)predictWithJSONModels:(NSArray*)models
                                  args:(NSDictionary*)inputData
                               options:(NSDictionary*)options
                         distributions:(NSArray*)distributions {

    NSUInteger maxModels = [options[@"maxModels"] ?: @(0) intValue];

    return [[[self alloc] initWithModels:models maxModels:maxModels distributions:distributions]
            predictWithArguments:inputData
            options:options];
}

- (NSArray*)multiModelsFromModels:(NSArray*)models maxModels:(NSUInteger)maxModels {
    
    maxModels = maxModels ?: models.count;
    NSUInteger multiModelSize = MIN(maxModels, models.count);
    
    NSMutableArray* multiModels = [NSMutableArray new];
    for (NSInteger i = 0; i < models.count; i += multiModelSize) {
        [multiModels addObject:
         [MultiModel multiModelWithModels:
          [models subarrayWithRange:(NSRange){
             i * maxModels,
             MIN(multiModelSize, models.count - i*multiModelSize)
         }]]];
    }
    return multiModels;
}

@end

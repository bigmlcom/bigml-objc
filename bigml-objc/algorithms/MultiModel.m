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

#import "MultiModel.h"
#import "MultiVote.h"
#import "PredictiveModel.h"

@implementation MultiModel {
    
    NSArray* _models;
}

- (instancetype)initWithModels:(NSArray*)models {
    
    if (self = [super init]) {
        _models = models;
    }
    return self;
}

+ (MultiModel*)multiModelWithModels:(NSArray*)models {
    return [[self alloc] initWithModels:models];
}

- (MultiVote*)generateVotes:(NSDictionary*)inputData
                     byName:(BOOL)byName
            missingStrategy:(NSInteger)missingStrategy
                     median:(BOOL)median {
    
    MultiVote* votes = [MultiVote new];
    for (NSDictionary* model in _models) {
        [votes append:[PredictiveModel predictWithJSONModel:model
                                                  arguments:inputData
                                                    options:@{ @"byName" : @(byName),
                                                               @"strategy" : @(missingStrategy),
                                                               @"median" : @(median),
                                                               @"confidence" : @(YES),
                                                               @"count" : @(YES),
                                                               @"distribution" : @(YES),
                                                               @"multiple" : @NSUIntegerMax}]];
    }
    return votes;
}

@end


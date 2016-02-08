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

@interface TreePrediction : NSObject

@property (nonatomic, strong) id prediction;
@property (nonatomic) double confidence;
@property (nonatomic) long count;
@property (nonatomic) double median;
@property (nonatomic) double probability;
@property (nonatomic, strong) NSString* next;
@property (nonatomic, strong) NSArray* path;
@property (nonatomic, strong) NSArray* distribution;
@property (nonatomic, strong) NSString* distributionUnit;
@property (nonatomic, strong) NSArray* children;

+ (TreePrediction*)treePrediction:(id)prediction
                       confidence:(double)confidence
                            count:(long)count
                           median:(double)median
                             path:(NSArray*)path
                     distribution:(NSArray*)distribution
                 distributionUnit:(NSString*)distributionUnit
                         children:(NSArray*)children;

@end

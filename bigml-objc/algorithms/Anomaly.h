// Copyright 2015-2016 BigML
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

@interface Anomaly : FieldResource

@property (nonatomic) BOOL stopped;
@property (nonatomic) double sampleSize;
@property (nonatomic) double meanDepth;
@property (nonatomic) double expectedMeanDepth;
@property (nonatomic) NSUInteger anomalyCount;
@property (nonatomic, strong) NSString* inputFields;
@property (nonatomic, strong) NSArray* iForest;
@property (nonatomic, strong) NSArray* topAnomalies;

- (instancetype)initWithJSONAnomaly:(NSDictionary*)anomalyDictionary;
- (double)score:(NSDictionary*)input options:(NSDictionary*)options;

@end

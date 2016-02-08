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

#import "Anomaly.h"
#import "Predicates.h"

#define DEPTH_FACTOR 0.5772156649

/**
 * Tree structure for the BigML anomaly detector
 *
 * This class defines an auxiliary tree that is used when calculating
 * anomaly scores without needing to send requests to BigML.io.
 *
 */
@interface AnomalyTreeNode : NSObject

@property (nonatomic, strong) Anomaly* anomaly;
@property (nonatomic, strong) Predicates* predicates;
@property (nonatomic, strong) NSString* identifier;
@property (nonatomic, strong) NSMutableArray* children;

@end

@implementation AnomalyTreeNode {
    
    NSDictionary* _fields;
}

- (instancetype)initWithTree:(NSDictionary*)tree anomaly:(Anomaly*)anomaly {
    
    if (self = [super init]) {
        _anomaly = anomaly;
        _fields = anomaly.fields;
        _predicates = [[Predicates alloc] initWithPredicates:tree[@"predicates"]?:@[@(YES)]];
        _identifier = tree[@"id"];
        
        _children = [NSMutableArray arrayWithCapacity:[tree[@"children"] count]];
        for (id child in tree[@"children"]) {
            [_children addObject:[[AnomalyTreeNode alloc] initWithTree:child anomaly:anomaly]];
        }
    }
    return self;
}

/**
 *
 * Returns the depth of the tree that the input data "verifies"
 * and the associated set of rules.
 *
 * If a node has any child whose predicates are all true for the given
 * input, then the depth is incremented and we flow through.
 * If the node has no children or no children with all valid predicates,
 * then it outputs the depth of the node.
 *
 * @return
 */
- (NSUInteger)verifiedDepthForTree:(NSDictionary*)tree
                              path:(NSMutableArray*)path
                             depth:(NSInteger)depth {

    if (!path)
        path = [NSMutableArray new];
    if (depth == 0) {
        if (![self.predicates apply:tree fields:_fields]) {
            return depth;
        }
        ++depth;
    }
    for (AnomalyTreeNode* child in _children) {
        if (_anomaly.stopped)
            return 0;
        if ([child.predicates apply:tree fields:_fields]) {
            [path addObject:[child.predicates ruleWithFields:_fields label:nil]];
            return [child verifiedDepthForTree:tree path:path depth:++depth];
        }
    }
    return depth;
}

@end


@implementation Anomaly {
    
    NSMutableArray* _iForest;
}

@synthesize iForest = _iForest;

- (instancetype)initWithJSONAnomaly:(NSDictionary*)anomalyDictionary {
    
    
    NSDictionary* model = anomalyDictionary[@"model"];
    NSAssert(model && [model[@"fields"] count] > 0,
             @"Anomaly constructor's contract unfulfilled: no fields");
    NSAssert([model[@"top_anomalies"] isKindOfClass:[NSArray class]],
              @"Anomaly constructor's contract unfulfilled: no top anomalies");
    NSAssert([anomalyDictionary[@"status"][@"code"] intValue] == 5,
             @"Anomaly constructor's contract unfulfilled: anomaly did not finish processing");
    
    if (self = [super initWithFields:model[@"fields"]]) {
        
        _sampleSize = [anomalyDictionary[@"sample_size"] doubleValue];
        _inputFields = anomalyDictionary[@"input_field"];
        
        _meanDepth = [model[@"mean_depth"] doubleValue];
        double defaultDepth = 2 * (DEPTH_FACTOR + log(_sampleSize - 1) -
                                   ((_sampleSize - 1) / _sampleSize));
        _expectedMeanDepth = fmin(_meanDepth, defaultDepth);
        _iForest = [NSMutableArray arrayWithCapacity:[model[@"trees"] count]];
        for (NSDictionary* tree in model[@"trees"]) {
            [_iForest addObject:[[AnomalyTreeNode alloc] initWithTree:tree[@"root"] anomaly:self]];
        }
        _topAnomalies = model[@"top_anomalies"];
    }
    return self;
}

- (double)score:(NSDictionary*)input options:(NSDictionary*)options {

    BOOL byName = [options[@"byName"] ?: @(NO) boolValue];
    _stopped = false;
    NSAssert(_iForest, @"Could not find forest info. The anomaly was possibly not completely created");

    NSDictionary* filteredInput = [self filteredInputData:input byName:byName];
    double depthSum = 0.0;
    for (AnomalyTreeNode* tree in _iForest) {
        depthSum += _stopped ? 0 : [tree verifiedDepthForTree:filteredInput path:nil depth:0];
    }
    double observedMeanDepth = depthSum / _iForest.count;
    return pow(2.0, -observedMeanDepth / _expectedMeanDepth);
}

@end
































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

#import "PredictionTree.h"
#import "TreePrediction.h"
#import "Predicates.h"
#import "BMLEnums.h"
#import "BMLUtils.h"

#define BINS_LIMIT 32
#define DEFAULT_RZ 1.96

typedef PredictionTree TreeHolder;

@interface PredictionTree ()

@property (nonatomic, strong) id output;
@property (nonatomic) double confidence;
@property (nonatomic) double median;
@property (nonatomic, strong) NSArray* distribution;
@property (nonatomic, strong) NSString* distributionUnit;
@property (nonatomic, strong) NSArray* children;

@end

@implementation PredictionTree {
    
    NSDictionary* _fields;
    NSArray* _objectiveFields;
    NSNumber* _nodeId;
    NSNumber* _parentId;
    Predicate* _predicate;
    long _count;
    double _impurity;
    NSDictionary* _rootDistribution;
}

@synthesize predicate = _predicate;
@synthesize objectiveFields = _objectiveFields;

- (PredictionTree*)initWithRoot:(NSDictionary*)root
                              fields:(NSDictionary*)fields
                      objectiveFields:(NSArray*)objectiveFields
                    rootDistribution:(NSDictionary*)rootDistribution
                            parentId:(NSNumber*)parentId
                              idsMap:(NSMutableDictionary*)idsMap
                             subtree:(BOOL)subtree
                             maxBins:(NSInteger)maxBins {

    if (self = [super init]) {
        
        _fields = fields;
        _objectiveFields = objectiveFields;
        
        _output = root[@"output"];
        _confidence = [root[@"confidence"] doubleValue];
        rootDistribution = rootDistribution;
        
        NSObject* predicateObj = root[@"predicate"];
        
        if ([predicateObj respondsToSelector:@selector(boolValue)] &&
            [(NSNumber*)predicateObj boolValue] == YES) {
            _isPredicate = YES;
        } else {
            
            NSDictionary* predicateDict = (NSDictionary*)predicateObj;
            self.predicate = [[Predicate alloc] initWithOperator:predicateDict[@"operator"]
                                                         field:predicateDict[@"field"]
                                                         value:predicateDict[@"value"]
                                                          term:predicateDict[@"term"]];
        }
        
        if (root[@"id"]) {
            _nodeId = root[@"id"];
            _parentId = parentId;
            [idsMap setObject:self forKey:_nodeId];
        }
        
        //-- Generate children array
        NSMutableArray* children = [[NSMutableArray alloc] init];
        for (NSDictionary* child in root[@"children"]) {
            
            PredictionTree* childTree =
            [[PredictionTree alloc] initWithRoot:child
                                               fields:_fields
                                      objectiveFields:_objectiveFields
                                     rootDistribution:nil
                                             parentId:_nodeId
                                               idsMap:idsMap
                                              subtree:subtree
                                              maxBins:maxBins];
            [children addObject:childTree];
        }
        _children = children;
        
        _count = [root[@"count"] integerValue];
        _confidence = [root[@"confidence"] doubleValue];
        _distribution = nil;
        _distributionUnit = nil;
        
        NSDictionary* summary = nil;
        NSArray* distributionObject = root[@"distribution"];
        if (distributionObject) {
            _distribution = distributionObject;
        } else {
            summary = [self setDistributionFromSummary:root[@"objective_summary"]];
        }
        
        if ([self isRegression]) {
            _maxBins = MAX(_maxBins, _distribution.count);
            _median = NAN;
            
            if (summary) {
                _median = [summary[@"median"] doubleValue];
            }
            if (isnan(_median)) {
                _median = [self medianForDistribution:_distribution count:_count];
            }
        }
        if (![self isRegression] && _distribution) {
            _impurity = [self giniImpurity:_distribution count:_count];
        }
    }
    
    return self;
}

/**
 * Returns the median value for a distribution
 *
 * @param distribution
 * @param count
 * @return
 */
- (double)medianForDistribution:(NSArray*)distribution count:(long)count {
    
    NSInteger counter = 0;
    double previousValue = NAN;
    for (NSArray* binInfo in distribution) {
        NSAssert([binInfo isKindOfClass:[NSArray class]] && binInfo.count == 2,
                 @"Wrong binInfo found -- not a proper array");
        double value = [binInfo.firstObject doubleValue];
        counter += [binInfo.lastObject intValue];
        if (counter > count / 2) {
            if ((count % 2) != 0 && (counter - 1) == (count / 2) && !isnan(previousValue)) {
                return (value + previousValue) / 2;
            }
            return value;
        }
        previousValue = value;
    }
    return  NAN;
}

/**
 * Returns the gini impurity score associated to the distribution in the node
 *
 * @param distribution
 * @param count
 * @return
 */
- (double)giniImpurity:(NSArray*)distribution count:(long)count {
    
    if (!distribution)
        return NAN;
    
    double purity = 0.0;
    for (NSArray* binInfo in distribution) {
        NSAssert([binInfo isKindOfClass:[NSArray class]] && binInfo.count == 2,
                 @"Wrong binInfo found -- not a proper array");
        double instances = [binInfo.lastObject doubleValue];
        purity += (instances / count) * (instances / count);
    }
    return (1.0 - purity) / 2;
}

/**
 * Checks if the node's value is a category
 *
 * @param node the node to be checked
 * @return true if the node's value is a category
 */
- (BOOL)isClassification:(PredictionTree*)node {
    return [node.output isKindOfClass:[NSString class]];
}

/**
 * Checks if the subtree structure can be a regression
 *
 * @return true if it's a regression or false if it's a classification
 */
- (BOOL)isRegression {
    
    if ([self isClassification:self]) {
        return NO;
    }
    
    if (_children.count == 0) {
        return YES;
    } else {
        for (PredictionTree* node in _children) {
            if ([self isClassification:node]) {
                return NO;
            }
        }
    }
    
    return true;
}

/**
 * Sets internal properties based on the passed summary.
 * If no summary is given, it uses the _rootDistribution.
 *
 * @return the used summary
 */
- (NSDictionary*)setDistributionFromSummary:(NSDictionary*)summary {
    
    if (!summary)
        summary = _rootDistribution;
    if (summary[@"bins"]) {
        _distribution = summary[@"bins"];
        _distributionUnit = @"bins";
    } else if (summary[@"counts"]) {
        _distribution = summary[@"counts"];
        _distributionUnit = @"counts";
    } else if (summary[@"categories"]) {
        _distribution = summary[@"categories"];
        _distributionUnit = @"categories";
    }
    return summary;
}

- (PredictionTree*)initWithRoot:(NSDictionary*)root
                              fields:(NSDictionary*)fields
                      objectiveField:(NSString*)objectiveField
                    rootDistribution:(NSDictionary*)rootDistribution
                            parentId:(NSNumber*)parentId
                              idsMap:(NSMutableDictionary*)idsMap
                             subtree:(BOOL)subtree
                             maxBins:(NSInteger)maxBins {
    
    return [self initWithRoot:root
                       fields:fields
              objectiveFields:@[objectiveField]
             rootDistribution:rootDistribution
                     parentId:parentId
                       idsMap:idsMap
                      subtree:subtree
                      maxBins:maxBins];
}

/**
 * Check if any node has a missing-valued predicate
 *
 * @param children
 * @return
 */
- (BOOL)missingBranch:(NSArray*)nodes {
    
    for (PredictionTree* node in nodes) {
        if (node.predicate.missing)
            return YES;
    }
    return  NO;
}

/**
 * Check if any node has a null-valued predicate
 *
 * @param nodes
 * @return
 */
- (BOOL)noneValue:(NSArray*)nodes {
    
    for (PredictionTree* node in nodes) {
        if (!node.predicate.value)
            return YES;
    }
    return  NO;
}

/**
 * Check if there's only one branch to be followed
 *
 * @param children
 * @param inputData
 * @return
 */
- (BOOL)isOneBranch:(NSArray*)nodes inputData:(NSDictionary*)inputData {
  
    BOOL missing = [inputData.allKeys containsObject:[BMLUtils splitNodes:nodes]];
    return missing || [self missingBranch:nodes] || [self noneValue:nodes];
}

/**
 * Makes a prediction based on a number of field values averaging
 *  the predictions of the leaves that fall in a subtree.
 *
 * Each time a splitting field has no value assigned, we consider
 *  both branches of the split to be true, merging their predictions.
 *  The function returns the merged distribution and the last node
 *  reached by a unique path.
 *
 * @param inputData
 * @param path
 * @param missingFound
 * @return
 */
- (NSDictionary*)predictProportional:(NSDictionary*)inputData
                            lastNode:(TreeHolder**)lastNode
                                path:(NSMutableArray*)path
                        missingFound:(BOOL)missingFound
                              median:(BOOL)median {

    if (!path)
        path = [NSMutableArray new];
    
    NSMutableDictionary* finalDistribution = [NSMutableDictionary new];
    if (_children.count == 0) {
        *lastNode = self;
        return [BMLUtils dictionaryFromDistributionArray:_distribution];
    }
    if ([self isOneBranch:_children inputData:inputData]) {
        for (PredictionTree* child in _children) {
            if ([child.predicate apply:inputData fields:_fields]) {
                NSString* newRule = [child.predicate ruleWithFields:_fields label:nil];
                if (![path containsObject:newRule] && !missingFound) {
                    [path addObject:newRule];
                }
                return [child predictProportional:inputData
                                         lastNode:lastNode
                                             path:path
                                     missingFound:missingFound
                                           median:median];
            }
        }
    } else {
        // missing value found, the unique path stops
        missingFound = YES;
        for (PredictionTree* child in _children) {
            finalDistribution = [BMLUtils
                                 mergeDistribution:finalDistribution
                                 andDistribution:[child predictProportional:inputData
                                                                   lastNode:lastNode
                                                                       path:path
                                                               missingFound:missingFound
                                                                     median:median]];
        }
        *lastNode = self;
        return finalDistribution;
    }
    NSAssert(NO, @"PredictionTree predictProportional: Should not be here.");
    return nil;
}

- (long)totalInstances:(NSArray*)distribution {
    
    long count = 0;
    for (NSArray* bin in distribution) {
        NSAssert([bin isKindOfClass:[NSArray class]] && bin.count == 2,
                 @"Bad bins in distribution");
        count += [bin.lastObject doubleValue];
    }
    return count;
}

/**
 * Makes a prediction based on a number of field values.
 *
 * The input fields must be keyed by Id.
 *
 * .predict({"petal length": 1})
 *
 */
- (TreePrediction*)predict:(NSDictionary*)inputData
                      path:(NSMutableArray*)path
                  strategy:(BMLMissingStrategy)strategy {

    if (!path)
        path = [NSMutableArray new];
    
    if (strategy == BMLMissingStrategyLastPrediction) {
        if (_children.count > 0) {
            for (PredictionTree* child in _children) {
                if ([child.predicate apply:inputData fields:_fields]) {
                    [path addObject:[child.predicate ruleWithFields:_fields label:nil]];
                    return [child predict:inputData path:path strategy:strategy];
                }
            }
        }
        return [TreePrediction treePrediction:_output
                                   confidence:_confidence
                                        count:_count
                                       median:([self isRegression]?_median:NAN)
                                         path:path
                                 distribution:_distribution
                             distributionUnit:_distributionUnit
                                     children:_children];
        
    } else if (strategy == BMLMissingStrategyProportional) {

        TreeHolder* lastNode = [TreeHolder new];
        NSDictionary* finalDistribution = [self predictProportional:inputData
                                                           lastNode:&lastNode
                                                               path:path
                                                       missingFound:NO
                                                             median:NO];
        if ([self isRegression]) {
            if (finalDistribution.count == 1) {
                NSAssert([finalDistribution.allValues.firstObject isKindOfClass:[NSArray class]] &&
                         [finalDistribution.allValues.firstObject count] == 2,
                          @"finalDistribution contains wrong values");
                long instances = [[finalDistribution.allValues.firstObject lastObject] longValue];
                if (instances == 1) {
                    return [TreePrediction treePrediction:lastNode.output
                                               confidence:lastNode.confidence
                                                    count:instances
                                                   median:lastNode.median
                                                     path:path
                                             distribution:lastNode.distribution
                                         distributionUnit:lastNode.distributionUnit
                                                 children:lastNode.children];
                } else
                    NSAssert(NO, @"Got more than one instances in single-node case");
            }
            //-- when there's more instances, sort elements by their mean
            NSArray* distribution = [BMLUtils arrayFromDistributionDictionary:finalDistribution];
            NSString* distributionUnit = (distribution.count > BINS_LIMIT) ? @"bins" : @"counts";
            distribution = [BMLUtils mergeBins:distribution limit:BINS_LIMIT];
            long totalInstances = [self totalInstances:distribution];
            double mean = [BMLUtils meanOfDistribution:distribution];
            double confidence = [BMLUtils regressionErrorWithVariance:
                                 [BMLUtils varianceOfDistribution:distribution mean:mean]
                                                   instances:totalInstances
                                                          rz:DEFAULT_RZ];
            return [TreePrediction
                    treePrediction:@(mean)
                    confidence:confidence
                    count:totalInstances
                    median:[BMLUtils medianOfDistribution:distribution instances:totalInstances]
                    path:path
                    distribution:distribution
                    distributionUnit:distributionUnit
                    children:lastNode.children];
        } else {
            
            NSArray* distribution = [BMLUtils arrayFromDistributionDictionary:finalDistribution];
            long totalInstances = [self totalInstances:distribution];
            NSAssert([_distributionUnit isEqualToString:@"categories"],
                     @"Bad distributionUnit");

            return [TreePrediction treePrediction:[distribution.firstObject firstObject]
                                       confidence:[BMLUtils wsConfidence:[distribution.firstObject firstObject]
                                                        distribution:finalDistribution]
                                            count:totalInstances
                                           median:NAN
                                             path:path
                                     distribution:distribution
                                 distributionUnit:_distributionUnit
                                         children:lastNode.children];

        }
    }
    NSAssert(NO, @"Unsupported missing strategy %d", strategy);
    return nil;
}

- (TreePrediction*)predict:(NSDictionary*)inputData
                      path:(NSMutableArray*)path {
    
    return [self predict:inputData path:path strategy:BMLMissingStrategyLastPrediction];
}

- (TreePrediction*)predict:(NSDictionary*)inputData {
    
    return [self predict:inputData path:nil strategy:BMLMissingStrategyLastPrediction];
}

@end

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

#import "BMLResourceTypeIdentifier.h"

#define BML_ADD_TYPE(NAME, VALUE) \
NAME = \
[[BMLResourceTypeIdentifier alloc] initWithStringLiteral:(VALUE)]

BMLResourceTypeIdentifier* BMLResourceTypeProject = nil;
BMLResourceTypeIdentifier* BMLResourceTypeFile = nil;
BMLResourceTypeIdentifier* BMLResourceTypeResource = nil;
BMLResourceTypeIdentifier* BMLResourceTypeSource = nil;
BMLResourceTypeIdentifier* BMLResourceTypeDataset = nil;
BMLResourceTypeIdentifier* BMLResourceTypeModel = nil;
BMLResourceTypeIdentifier* BMLResourceTypeCluster = nil;
BMLResourceTypeIdentifier* BMLResourceTypeAnomaly = nil;
BMLResourceTypeIdentifier* BMLResourceTypeEnsemble = nil;
BMLResourceTypeIdentifier* BMLResourceTypeLogisticRegression = nil;
BMLResourceTypeIdentifier* BMLResourceTypeAssociation = nil;
BMLResourceTypeIdentifier* BMLResourceTypeEvaluation = nil;
BMLResourceTypeIdentifier* BMLResourceTypePrediction = nil;
BMLResourceTypeIdentifier* BMLResourceTypeCentroid = nil;
BMLResourceTypeIdentifier* BMLResourceTypeBatchPrediction = nil;
BMLResourceTypeIdentifier* BMLResourceTypeAnomalyScore = nil;
BMLResourceTypeIdentifier* BMLResourceTypeTopicDistribution = nil;
BMLResourceTypeIdentifier* BMLResourceTypeTopicModel = nil;
BMLResourceTypeIdentifier* BMLResourceTypeWhizzmlScript = nil;
BMLResourceTypeIdentifier* BMLResourceTypeWhizzmlExecution = nil;
BMLResourceTypeIdentifier* BMLResourceTypeWhizzmlLibrary = nil;
BMLResourceTypeIdentifier* BMLResourceTypeWhizzmlSource = nil;
BMLResourceTypeIdentifier* BMLResourceTypeNotAResource = nil;

@implementation BMLResourceTypeIdentifier {
    
    NSString* _typeIdentifier;
}

+ (void)load {
    
    if (self == [BMLResourceTypeIdentifier class]) {
        BML_ADD_TYPE(BMLResourceTypeProject, @"project");
        BML_ADD_TYPE(BMLResourceTypeFile, @"file");
        BML_ADD_TYPE(BMLResourceTypeResource, @"resource");
        BML_ADD_TYPE(BMLResourceTypeSource, @"source");
        BML_ADD_TYPE(BMLResourceTypeDataset, @"dataset");
        BML_ADD_TYPE(BMLResourceTypeModel, @"model");
        BML_ADD_TYPE(BMLResourceTypeCluster, @"cluster");
        BML_ADD_TYPE(BMLResourceTypeAnomaly, @"anomaly");
        BML_ADD_TYPE(BMLResourceTypeEnsemble, @"ensemble");
        BML_ADD_TYPE(BMLResourceTypeLogisticRegression, @"logisticregression");
        BML_ADD_TYPE(BMLResourceTypeAssociation, @"association");
        BML_ADD_TYPE(BMLResourceTypeEvaluation, @"evaluation");
        BML_ADD_TYPE(BMLResourceTypePrediction, @"prediction");
        BML_ADD_TYPE(BMLResourceTypeCentroid, @"centroid");
        BML_ADD_TYPE(BMLResourceTypeBatchPrediction, @"batchprediction");
        BML_ADD_TYPE(BMLResourceTypeAnomalyScore, @"anomalyscore");
        BML_ADD_TYPE(BMLResourceTypeTopicDistribution, @"topicdistribution");
        BML_ADD_TYPE(BMLResourceTypeTopicModel, @"topicmodel");
        BML_ADD_TYPE(BMLResourceTypeWhizzmlScript, @"script");
        BML_ADD_TYPE(BMLResourceTypeWhizzmlExecution, @"execution");
        BML_ADD_TYPE(BMLResourceTypeWhizzmlSource, @"sourcecode");
        BML_ADD_TYPE(BMLResourceTypeWhizzmlLibrary, @"library");
        BML_ADD_TYPE(BMLResourceTypeNotAResource, @"invalid");
    }
}

+ (NSArray*)resourceTypes {
    
    return @[BMLResourceTypeFile,
             BMLResourceTypeSource,
             BMLResourceTypeDataset,
             BMLResourceTypeModel,
             BMLResourceTypeEnsemble,
             BMLResourceTypeLogisticRegression,
             BMLResourceTypeEvaluation,
             BMLResourceTypeCluster,
             BMLResourceTypeAnomaly,
             BMLResourceTypeAssociation,
             BMLResourceTypePrediction,
             BMLResourceTypeAnomaly,
             BMLResourceTypeCentroid,
             BMLResourceTypeBatchPrediction,
             BMLResourceTypeTopicModel,
             BMLResourceTypeTopicDistribution,
             BMLResourceTypeWhizzmlScript,
             BMLResourceTypeWhizzmlExecution,
             BMLResourceTypeWhizzmlLibrary,
             BMLResourceTypeProject];
}

- (instancetype)initWithStringLiteral:(NSString*)value {
    
    if (self = [super init]) {
        _typeIdentifier = value;
    }
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    
    return [[BMLResourceTypeIdentifier allocWithZone:zone] initWithStringLiteral:self.stringValue];
}

- (BOOL)isEqualTo:(id)object {
    
    if ([object isKindOfClass:[BMLResourceTypeIdentifier class]]) {
        return [self.stringValue isEqualToString:[(BMLResourceTypeIdentifier*)object stringValue]];
    } else if ([object isKindOfClass:[NSString class]]) {
        return [self.stringValue isEqualToString:object];
    }
    return NO;
}

- (NSString*)stringValue {
    
    return _typeIdentifier;
}

- (NSString*)description {
    
    return _typeIdentifier;
}

+ (BMLResourceTypeIdentifier*)typeFromTypeString:(NSString*)type {
    
    for (id resourceType in [BMLResourceTypeIdentifier resourceTypes]) {
        
        if ([type isEqualToString:[resourceType stringValue]])
            return resourceType;
    }
    return nil;
}

+ (BOOL)isValidFullUuid:(id)obj {

    return ([obj isKindOfClass:[NSString class]] &&
            [self typeFromTypeString:[obj componentsSeparatedByString:@"/"].firstObject]);
}

+ (BMLResourceTypeIdentifier*)typeFromFullUuid:(BMLResourceFullUuid*)fullUuid {
    
    NSString* type = [[fullUuid componentsSeparatedByString:@"/"] firstObject];
    return [self typeFromTypeString:type];
}

+ (BMLResourceUuid*)uuidFromFullUuid:(BMLResourceFullUuid*)fullUuid {
    
    NSMutableArray* parts = [[fullUuid componentsSeparatedByString:@"/"] mutableCopy];
    if ([parts count] == 2)
        return [parts lastObject];
    else if ([parts count] > 2) {
        return [[parts subarrayWithRange:NSMakeRange(1, [parts count]-1)] componentsJoinedByString:@"/"];
    }
    return nil;
}

@end

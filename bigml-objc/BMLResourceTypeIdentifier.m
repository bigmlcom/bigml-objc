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
        BML_ADD_TYPE(BMLResourceTypeAssociation, @"association2");
        BML_ADD_TYPE(BMLResourceTypeEvaluation, @"evaluation");
        BML_ADD_TYPE(BMLResourceTypePrediction, @"prediction");
        BML_ADD_TYPE(BMLResourceTypeWhizzmlScript, @"script");
        BML_ADD_TYPE(BMLResourceTypeWhizzmlExecution, @"execution");
        BML_ADD_TYPE(BMLResourceTypeWhizzmlSource, @"sourcecode");
        BML_ADD_TYPE(BMLResourceTypeNotAResource, @"invalid");
        BML_ADD_TYPE(BMLResourceTypeWhizzmlLibrary, @"library");
    }
}

- (instancetype)initWithStringLiteral:(NSString*)value {
    
    if (self = [super init]) {
        _typeIdentifier = value;
    }
    return self;
}

- (NSString*)stringValue {
    
    return _typeIdentifier;
}

- (NSString*)description {
    
    return _typeIdentifier;
}

+ (BMLResourceTypeIdentifier*)typeFromTypeString:(NSString*)type {
    
    if ([type isEqualToString:[BMLResourceTypeFile stringValue]])
        return BMLResourceTypeFile;
    if ([type isEqualToString:[BMLResourceTypeResource stringValue]])
        return BMLResourceTypeResource;
    if ([type isEqualToString:[BMLResourceTypeSource stringValue]])
        return BMLResourceTypeSource;
    if ([type isEqualToString:[BMLResourceTypeDataset stringValue]])
        return BMLResourceTypeDataset;
    if ([type isEqualToString:[BMLResourceTypeModel stringValue]])
        return BMLResourceTypeModel;
    if ([type isEqualToString:[BMLResourceTypeEnsemble stringValue]])
        return BMLResourceTypeEnsemble;
    if ([type isEqualToString:[BMLResourceTypeCluster stringValue]])
        return BMLResourceTypeCluster;
    if ([type isEqualToString:[BMLResourceTypePrediction stringValue]])
        return BMLResourceTypePrediction;
    if ([type isEqualToString:[BMLResourceTypeAnomaly stringValue]])
        return BMLResourceTypeAnomaly;
    if ([type isEqualToString:[BMLResourceTypeEvaluation stringValue]])
        return BMLResourceTypeEvaluation;
    if ([type isEqualToString:[BMLResourceTypeLogisticRegression stringValue]])
        return BMLResourceTypeLogisticRegression;
    if ([type isEqualToString:[BMLResourceTypeAssociation stringValue]])
        return BMLResourceTypeAssociation;
    if ([type isEqualToString:[BMLResourceTypeWhizzmlScript stringValue]])
        return BMLResourceTypeWhizzmlScript;
    if ([type isEqualToString:[BMLResourceTypeWhizzmlSource stringValue]])
        return BMLResourceTypeWhizzmlSource;
    if ([type isEqualToString:[BMLResourceTypeWhizzmlExecution stringValue]])
        return BMLResourceTypeWhizzmlExecution;
    if ([type isEqualToString:[BMLResourceTypeWhizzmlLibrary stringValue]])
        return BMLResourceTypeWhizzmlLibrary;
    if ([type isEqualToString:[BMLResourceTypeProject stringValue]])
        return BMLResourceTypeProject;
//    NSLog(@"Type Id: Should not be here! (%@)", type);
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

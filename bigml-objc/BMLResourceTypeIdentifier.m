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

NSString* const BMLResourceTypeFile = @"file";
NSString* const BMLResourceTypeProject = @"project";
NSString* const BMLResourceTypeSource = @"source";
NSString* const BMLResourceTypeDataset = @"dataset";
NSString* const BMLResourceTypeModel = @"model";
NSString* const BMLResourceTypeCluster = @"cluster";
NSString* const BMLResourceTypeAnomaly = @"anomaly";
NSString* const BMLResourceTypeEnsemble = @"ensemble";
NSString* const BMLResourceTypeLogisticRegression = @"logisticRegression";
NSString* const BMLResourceTypeAssociation = @"association";
NSString* const BMLResourceTypeEvaluation = @"evaluation";
NSString* const BMLResourceTypePrediction = @"prediction";
NSString* const BMLResourceTypeWhizzmlScript = @"script";
NSString* const BMLResourceTypeWhizzmlExecution = @"execution";
NSString* const BMLResourceTypeWhizzmlSource = @"sourcecode";
NSString* const BMLResourceTypeNotAResource = @"invalid";

@implementation BMLResourceTypeIdentifier

- (instancetype)initWithStringLiteral:(NSString*)value {
    
    return [super initWithString:value];
}

- (NSString*)stringValue {
    
    return self;
}

- (NSString*)description {
    
    return self;
}

@end

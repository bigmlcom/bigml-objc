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

BMLResourceTypeIdentifier* const BMLResourceTypeFile = (BMLResourceTypeIdentifier*)@"file";
BMLResourceTypeIdentifier* const BMLResourceTypeProject = (BMLResourceTypeIdentifier*)@"project";
BMLResourceTypeIdentifier* const BMLResourceTypeSource = (BMLResourceTypeIdentifier*)@"source";
BMLResourceTypeIdentifier* const BMLResourceTypeDataset = (BMLResourceTypeIdentifier*)@"dataset";
BMLResourceTypeIdentifier* const BMLResourceTypeModel = (BMLResourceTypeIdentifier*)@"model";
BMLResourceTypeIdentifier* const BMLResourceTypeCluster = (BMLResourceTypeIdentifier*)@"cluster";
BMLResourceTypeIdentifier* const BMLResourceTypeAnomaly = (BMLResourceTypeIdentifier*)@"anomaly";
BMLResourceTypeIdentifier* const BMLResourceTypeEnsemble = (BMLResourceTypeIdentifier*)@"ensemble";
BMLResourceTypeIdentifier* const BMLResourceTypeLogisticRegression = (BMLResourceTypeIdentifier*)@"logisticRegression";
BMLResourceTypeIdentifier* const BMLResourceTypeAssociation = (BMLResourceTypeIdentifier*)@"association";
BMLResourceTypeIdentifier* const BMLResourceTypeEvaluation = (BMLResourceTypeIdentifier*)@"evaluation";
BMLResourceTypeIdentifier* const BMLResourceTypePrediction = (BMLResourceTypeIdentifier*)@"prediction";
BMLResourceTypeIdentifier* const BMLResourceTypeWhizzmlScript = (BMLResourceTypeIdentifier*)@"script";
BMLResourceTypeIdentifier* const BMLResourceTypeWhizzmlExecution = (BMLResourceTypeIdentifier*)@"execution";
BMLResourceTypeIdentifier* const BMLResourceTypeWhizzmlSource = (BMLResourceTypeIdentifier*)@"sourcecode";
BMLResourceTypeIdentifier* const BMLResourceTypeNotAResource = (BMLResourceTypeIdentifier*)@"invalid";

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

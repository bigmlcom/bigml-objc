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
#import "BMLResourceProtocol.h"

//@class BMLResourceTypeIdentifier;

@interface BMLResourceTypeIdentifier : NSObject

+ (BMLResourceTypeIdentifier*)typeFromFullUuid:(BMLResourceFullUuid*)fullUuid;
+ (BMLResourceUuid*)uuidFromFullUuid:(BMLResourceFullUuid*)fullUuid;
+ (BMLResourceTypeIdentifier*)typeFromTypeString:(NSString*)type;

- (instancetype)initWithStringLiteral:(NSString*)value;

- (NSString*)stringValue;
- (NSString*)description;

@end

extern BMLResourceTypeIdentifier* BMLResourceTypeFile;
extern BMLResourceTypeIdentifier* BMLResourceTypeProject;
extern BMLResourceTypeIdentifier* BMLResourceTypeSource;
extern BMLResourceTypeIdentifier* BMLResourceTypeDataset;
extern BMLResourceTypeIdentifier* BMLResourceTypeModel;
extern BMLResourceTypeIdentifier* BMLResourceTypeCluster;
extern BMLResourceTypeIdentifier* BMLResourceTypeAnomaly;
extern BMLResourceTypeIdentifier* BMLResourceTypeEnsemble;
extern BMLResourceTypeIdentifier* BMLResourceTypeLogisticRegression;
extern BMLResourceTypeIdentifier* BMLResourceTypeAssociation;
extern BMLResourceTypeIdentifier* BMLResourceTypeEvaluation;
extern BMLResourceTypeIdentifier* BMLResourceTypePrediction;
extern BMLResourceTypeIdentifier* BMLResourceTypeWhizzmlScript;
extern BMLResourceTypeIdentifier* BMLResourceTypeWhizzmlExecution;
extern BMLResourceTypeIdentifier* BMLResourceTypeWhizzmlSource;
extern BMLResourceTypeIdentifier* BMLResourceTypeNotAResource;
extern BMLResourceTypeIdentifier* BMLResourceTypeConfiguration;

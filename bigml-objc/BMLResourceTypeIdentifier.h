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

@class BMLResourceTypeIdentifier;

@interface BMLResourceTypeIdentifier : NSString

- (instancetype)initWithStringLiteral:(NSString*)value;

- (NSString*)stringValue;
- (NSString*)description;

@end

extern BMLResourceTypeIdentifier* const BMLResourceTypeFile;
extern BMLResourceTypeIdentifier* const BMLResourceTypeProject;
extern BMLResourceTypeIdentifier* const BMLResourceTypeSource;
extern BMLResourceTypeIdentifier* const BMLResourceTypeDataset;
extern BMLResourceTypeIdentifier* const BMLResourceTypeModel;
extern BMLResourceTypeIdentifier* const BMLResourceTypeCluster;
extern BMLResourceTypeIdentifier* const BMLResourceTypeAnomaly;
extern BMLResourceTypeIdentifier* const BMLResourceTypeEnsemble;
extern BMLResourceTypeIdentifier* const BMLResourceTypeLogisticRegression;
extern BMLResourceTypeIdentifier* const BMLResourceTypeAssociation;
extern BMLResourceTypeIdentifier* const BMLResourceTypeEvaluation;
extern BMLResourceTypeIdentifier* const BMLResourceTypePrediction;
extern BMLResourceTypeIdentifier* const BMLResourceTypeWhizzmlScript;
extern BMLResourceTypeIdentifier* const BMLResourceTypeWhizzmlExecution;
extern BMLResourceTypeIdentifier* const BMLResourceTypeWhizzmlSource;
extern BMLResourceTypeIdentifier* const BMLResourceTypeNotAResource;

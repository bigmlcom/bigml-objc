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

extern NSString* const BMLResourceTypeFile;
extern NSString* const BMLResourceTypeProject;
extern NSString* const BMLResourceTypeSource;
extern NSString* const BMLResourceTypeDataset;
extern NSString* const BMLResourceTypeModel;
extern NSString* const BMLResourceTypeCluster;
extern NSString* const BMLResourceTypeAnomaly;
extern NSString* const BMLResourceTypeEnsemble;
extern NSString* const BMLResourceTypeLogisticRegression;
extern NSString* const BMLResourceTypeAssociation;
extern NSString* const BMLResourceTypeEvaluation;
extern NSString* const BMLResourceTypePrediction;
extern NSString* const BMLResourceTypeWhizzmlScript;
extern NSString* const BMLResourceTypeWhizzmlExecution;
extern NSString* const BMLResourceTypeWhizzmlSource;
extern NSString* const BMLResourceTypeNotAResource;

@interface BMLResourceTypeIdentifier : NSString

- (instancetype)initWithStringLiteral:(NSString*)value;

- (NSString*)stringValue;
- (NSString*)description;

@end

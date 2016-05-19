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

/**
 * Resource type identifier.
 *
 * Instances of this class are used to identify the type of resources
 * that you wish to manipulate through the methods in BMLAPIConnector.
 * This class also provides convenience methods to handle
 * BMLResourceFullUuids.
 * 
 * The class is a wrapper of an NSString. If you instantiate this class
 * directly, you should ensure that the string you use is recognized
 * by BigML as a supported resource type, e.g. dataset, model, cluster, etc.
 *
 * You do not actually need to instantiate this class since you
 * can use the global identifiers defined below for recognized resources.
 */
@interface BMLResourceTypeIdentifier : NSObject

/**
 * Returns YES if the passed string is a valid full resource identifier.
 * @param fullUuid The BMLResourceFullUuid of the resource.
 * @return YES if the passed string is a valid full resource identifier.
 */
+ (BOOL)isValidFullUuid:(NSString*)fullUuid;

/**
 * Returns the type identifier corresponding to the given BMLResourceFullUuid.
 * @param fullUuid The BMLResourceFullUuid of the resource.
 * @return one of the BMLResourceTypeIdentifier globals for recognized resources,
 *  or nil.
 */
+ (BMLResourceTypeIdentifier*)typeFromFullUuid:(BMLResourceFullUuid*)fullUuid;

/**
 * Returns the BMLResourceUuuid part of the given BMLResourceFullUuid.
 * @param fullUuid The BMLResourceFullUuid of the resource.
 * @return The BMLResourceUuuid part of the given BMLResourceFullUuid.
 */
+ (BMLResourceUuid*)uuidFromFullUuid:(BMLResourceFullUuid*)fullUuid;

/**
 * Convenience constructor returning the BMLResourceTypeIdentifier corresponding
 *  to the given NSString.
 * @param type An NSString representing the type of the resource. It should be
 *  one of the resource types recognized by BigML.
 * @return The BMLResourceTypeIdentifier corresponding to the given NSString, or nil.
 */
+ (BMLResourceTypeIdentifier*)typeFromTypeString:(NSString*)type;


/// The NSString corresponding to this resource type.
- (NSString*)stringValue;

/// The NSString corresponding to this resource type. Used for debugging.
- (NSString*)description;

/**
 * Low-level constructor. Should not be used.
 */
- (instancetype)initWithStringLiteral:(NSString*)value;

@end

extern BMLResourceTypeIdentifier* BMLResourceTypeProject;
extern BMLResourceTypeIdentifier* BMLResourceTypeFile;
extern BMLResourceTypeIdentifier* BMLResourceTypeResource;
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

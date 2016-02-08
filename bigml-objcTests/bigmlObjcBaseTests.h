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

#import <XCTest/XCTest.h>

#import "BMLAPIConnector.h"
#import "BMLResourceProtocol.h"
#import "BMLResourceTypeIdentifier.h"

@interface bigmlObjcBaseTests : XCTestCase

@property (nonatomic, strong) BMLAPIConnector* connector;
@property (nonatomic, readonly) id<BMLResource> aSource;
@property (nonatomic, readonly) id<BMLResource> aDataset;
@property (nonatomic, readonly) id<BMLResource> altDataset;

- (void)runTest:(NSString*)name
           test:(void(^)(XCTestExpectation*))test;

- (id<BMLResource>)createDatasource:(NSString*)file
                            options:(NSDictionary*)options;

- (id<BMLResource>)createDatasetFromDataSource:(id<BMLResource>)datasource
                                       options:(NSDictionary*)options;

- (id<BMLResource>)createDataset:(NSString*)file
                         options:(NSDictionary*)options;

- (NSError*)deleteResource:(id<BMLResource>)resource;

@end

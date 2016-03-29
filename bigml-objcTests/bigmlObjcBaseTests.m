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
#import "bigmlObjcBaseTests.h"
#import "bigmlObjcTestCredentials.h"

static id<BMLResource> _aSource = nil;
static id<BMLResource> _aDataset = nil;
static id<BMLResource> _altDataset = nil;
static dispatch_once_t _dispatchToken = 0;

@implementation bigmlObjcBaseTests

@dynamic aSource;
@dynamic aDataset;
@dynamic altDataset;

- (id<BMLResource>)aSource {
    return _aSource;
}

- (id<BMLResource>)aDataset {
    return _aDataset;
}

- (id<BMLResource>)altDataset {
    return _altDataset;
}

- (void)setUp {
    [super setUp];

    self.connector = [BMLAPIConnector connectorWithUsername:[bigmlObjcTestCredentials username]
                                                     apiKey:[bigmlObjcTestCredentials apiKey]
                                                       mode:BMLModeProduction];
    
    dispatch_once(&_dispatchToken, ^{
        _aSource = [self createDatasource:@"iris.csv" options:nil];
        _aDataset = [self createDataset:@"iris.csv" options:nil];
        _altDataset = [self createDataset:@"iris.csv" options:nil];
    });
}

- (void)runTest:(NSString*)name test:(void(^)(XCTestExpectation*))test {
    
    XCTestExpectation* exp = [self expectationWithDescription:name];
    test(exp);
    [self waitForExpectationsWithTimeout:360 handler:^(NSError* error) {
        if (error)
            NSLog(@"Expect error: %@", error);
    }];
}

- (id<BMLResource>)createDatasource:(NSString*)file options:(NSDictionary*)options {
    
    id<BMLResource> __block result = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSString* filePath = pathForResource(file);
    BMLMinimalResource* resource =
    [[BMLMinimalResource alloc] initWithName:file
                                        type:BMLResourceTypeFile
                                        uuid:filePath
                                  definition:nil];
    [_connector createResource:BMLResourceTypeSource
                          name:file
                       options:options[BMLResourceTypeSource]
                          from:resource
                    completion:^(id<BMLResource> resource, NSError* error) {
                       
                        if (options[BMLResourceTypeSource]) {
                            
                            [_connector updateResource:BMLResourceTypeSource
                                                  uuid:resource.uuid
                                               values:options[BMLResourceTypeSource]
                                            completion:^(NSError* error) {
                                                
                                                result = resource;
                                                dispatch_semaphore_signal(semaphore);
                                            }];
                        } else {
                            
                            result = resource;
                            dispatch_semaphore_signal(semaphore);
                        }
                    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result;
}

- (id<BMLResource>)createDatasetFromDataSource:(id<BMLResource>)datasource
                                       options:(NSDictionary*)options {
    
    id<BMLResource> __block result = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [_connector createResource:BMLResourceTypeDataset
                          name:datasource.name
                       options:options[BMLResourceTypeDataset]
                          from:datasource
                    completion:^(id<BMLResource> resource, NSError* error) {
                        
                        result = resource;
                        dispatch_semaphore_signal(semaphore);
                        XCTAssert(resource);
                    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result;
}

- (id<BMLResource>)createDataset:(NSString*)file options:(NSDictionary*)options {
    
    id<BMLResource> datasource = [self createDatasource:file options:options];
    id<BMLResource> dataset = [self createDatasetFromDataSource:datasource options:options];
    return dataset;
}

- (NSError*)deleteResource:(id<BMLResource>)resource {
    
    NSError* __block error = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self.connector deleteResource:resource.type
                              uuid:resource.uuid
                        completion:^(NSError* err) {
                            
                            error = err;
                            dispatch_semaphore_signal(semaphore);
                            XCTAssert(err == nil);
                        }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return error;
}


@end

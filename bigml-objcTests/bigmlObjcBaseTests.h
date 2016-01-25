//
//  bigmlObjcAPITests.h
//  bigml-objc
//
//  Created by sergio on 25/01/16.
//  Copyright © 2016 BigML Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BMLAPIConnector.h"
#import "BMLResource.h"
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

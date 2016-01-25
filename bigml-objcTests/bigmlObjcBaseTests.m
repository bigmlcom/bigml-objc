//
//  bigml_objcTests.m
//  bigml-objcTests
//
//  Created by sergio on 19/11/15.
//  Copyright © 2015 BigML Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "bigmlObjcBaseTests.h"

static id<BMLResource> _aSource = nil;
static id<BMLResource> _aDataset = nil;
static id<BMLResource> _altDataset = nil;
static dispatch_once_t _dispatchToken = 0;

static NSString* pathForResource(NSString* name) {
    for (NSBundle* bundle in [NSBundle allBundles]) {
        NSString* p = [bundle pathForResource:name ofType:nil];
        if (p)
            return p;
    }
    return nil;
}

@interface BMLTestCredentials : NSObject

@end

@implementation BMLTestCredentials

+ (NSDictionary*)credentials {
    return [[NSDictionary alloc]
            initWithContentsOfFile:pathForResource(@"credentials.plist")];
}

+ (NSString*)username {
    return self.credentials[@"username"];
}

+ (NSString*)apiKey {
    return self.credentials[@"apiKey"];
}

@end

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

    self.connector = [BMLAPIConnector connectorWithUsername:[BMLTestCredentials username]
                                                     apiKey:[BMLTestCredentials apiKey]
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
                                                
                                                XCTAssert(resource);
                                                result = resource;
                                                dispatch_semaphore_signal(semaphore);
                                            }];
                        } else {
                            
                            result = resource;
                            dispatch_semaphore_signal(semaphore);
                            XCTAssert(resource);
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

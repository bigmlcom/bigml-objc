//
//  bigml_objcTests.m
//  bigml-objcTests
//
//  Created by sergio on 19/11/15.
//  Copyright © 2015 BigML Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BMLAPIConnector.h"
#import "BMLResource.h"
#import "BMLResourceTypeIdentifier.h"

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

@interface bigmlObjcTests : XCTestCase

@property (nonatomic, strong) BMLAPIConnector* connector;

@end

@implementation bigmlObjcTests

- (void)setUp {
    [super setUp];

    self.connector = [BMLAPIConnector connectorWithUsername:[BMLTestCredentials username]
                                                     apiKey:[BMLTestCredentials apiKey]
                                                       mode:BMLModeProduction];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)runTest:(NSString*)name test:(void(^)(XCTestExpectation*))test {
    
    XCTestExpectation* exp = [self expectationWithDescription:name];
    test(exp);
    [self waitForExpectationsWithTimeout:360 handler:^(NSError* error) {
        if (error)
            NSLog(@"Expect error: %@", error);
    }];
}

- (id<BMLResource>)createDataSource:(NSString*)file options:(NSDictionary*)options {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSString* filePath = pathForResource(file);
    id<BMLResource> __block result = nil;
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
                       
                        XCTAssert(resource);
                        result = resource;
                        dispatch_semaphore_signal(semaphore);
                    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result;
}

- (void)testExample {

    NSLog(@"RESULT: %@", [self createDataSource:@"iris.csv" options:nil]);
}

@end

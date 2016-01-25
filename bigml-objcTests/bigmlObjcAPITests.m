//
//  bigmlObjcAPITests.m
//  bigml-objc
//
//  Created by sergio on 25/01/16.
//  Copyright © 2016 BigML Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "bigmlObjcBaseTests.h"

@interface bigmlObjcAPITests : bigmlObjcBaseTests

@end

@implementation bigmlObjcAPITests

- (void)testCreateRemoteDatasource {

    NSString* name = @"testCreateRemoteDatasource";
    [self runTest:name test:^(XCTestExpectation* exp) {
       
        [self.connector createResource:BMLResourceTypeSource
                                  name:name
                               options:@{@"remote" : @"s3://bigml-public/csv/iris.csv"}
                            completion:^(id<BMLResource> resource, NSError* error) {
                                
                                XCTAssert(resource != nil && error == nil);
                                XCTAssert([self deleteResource:resource] == nil);
                                [exp fulfill];
                            }];
    }];
}

- (void)testCreateAnomaly {
    
    NSString* name = @"testCreateAnomaly";
    [self runTest:name test:^(XCTestExpectation* exp) {
        
        [self.connector createResource:BMLResourceTypeAnomaly
                                  name:name
                               options:nil
                                  from:self.aDataset
                            completion:^(id<BMLResource> resource, NSError* error) {
                                
                                XCTAssert(resource != nil && error == nil);
                                XCTAssert([self deleteResource:resource] == nil);
                                [exp fulfill];
                            }];
    }];
}

- (void)testCreateDatasourceWithOption1 {
    
    id<BMLResource> resource = [self createDatasource:@"iris.csv" options:
                                @{ @"source_parser": @{ @"header" : @NO,
                                                        @"missing_tokens" : @[@"x"]},
                                   @"term_analysis" : @{@"enabled" : @YES}}];
    
    XCTAssert(resource);
    XCTAssert([self deleteResource:resource] == nil);
}

- (void)testCreateDatasourceWithOption2 {
    
    id<BMLResource> resource = [self createDatasource:@"spam.csv" options:
                                @{ @"term_analysis" : @{@"case_sensitive" : @YES,
                                                        @"enabled" : @YES,
                                                        @"stem_words" : @NO}}];
    XCTAssert(resource);
    XCTAssert([self deleteResource:resource] == nil);
}

- (void)testCreateDatasourceWithOption3 {
    
    id<BMLResource> resource = [self createDatasource:@"spam.csv" options:nil];
    XCTAssert(resource);
    
    NSString* name = @"testCreateAnomaly";
    [self runTest:name test:^(XCTestExpectation* exp) {
        
        [self.connector updateResource:resource.type
                                  uuid:resource.uuid
                                values: @{ @"fields" : @{
                                                   @"000001" : @{
                                                           @"optype" : @"text",
                                                           @"term_analysis" : @{
                                                                   @"case_sensitive" : @YES,
                                                                   @"stem_words" : @YES,
                                                                   @"use_stopwords" : @NO,
                                                                   @"language" : @"en"}}}}
                            completion:^(NSError* error) {
                                
                                XCTAssert(error == nil);
                                XCTAssert([self deleteResource:resource] == nil);
                                [exp fulfill];
                            }];
    }];
}

- (void)testCloneDataset {
    
    NSString* name = @"testCloneDataset";
    [self runTest:name test:^(XCTestExpectation* exp) {
        
        [self.connector createResource:BMLResourceTypeDataset
                                  name:name
                               options:nil
                                  from:self.aDataset
                            completion:^(id<BMLResource> resource, NSError* error) {
                                
                                XCTAssert(resource != nil && error == nil);
                                XCTAssert([self deleteResource:resource] == nil);
                                [exp fulfill];
                            }];
    }];
}

- (void)testCreateResourceFail {
    
    NSString* name = @"testCreateResourceFail";
    [self runTest:name test:^(XCTestExpectation* exp) {
        
        [self.connector createResource:BMLResourceTypeModel
                                  name:name
                               options:nil
                                  from:self.aSource
                            completion:^(id<BMLResource> resource, NSError* error) {
                                
                                XCTAssert(resource == nil && error != nil);
                                [exp fulfill];
                            }];
    }];
}


@end

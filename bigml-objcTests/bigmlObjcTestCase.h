//
//  bigmlObjcTestCase.h
//  bigml-objc
//
//  Created by sergio on 12/11/15.
//
//

#import <XCTest/XCTest.h>

@class bigmlObjcTester;

@interface bigmlObjcTestCase : XCTestCase

@property (nonatomic, readonly) bigmlObjcTester* apiLibrary;

@end


//
//  LogisticRegression.h
//  bigml-objc
//
//  Created by sergio on 21/03/16.
//  Copyright © 2017 BigML Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FieldResource.h"

@interface LogisticRegression : FieldResource

- (instancetype)initWithLogisticRegression:(NSDictionary*)logisticRegression;

- (NSDictionary*)predictWithData:(NSDictionary*)input options:(NSDictionary*)options;

+ (NSDictionary*)predictWithJSONLogisticRegression:(NSDictionary*)logisticRegression
                                              args:(NSDictionary*)inputData
                                           options:(NSDictionary*)options;

@end

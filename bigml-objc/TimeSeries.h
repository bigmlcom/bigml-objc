//
//  TimeSeries.h
//  bigml-objc
//
//  Created by sergio on 19/07/17.
//  Copyright © 2017 BigML Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FieldResource.h"

@interface TimeSeries : FieldResource

+ (NSArray*)forecastWithJSONTimeSeries:(NSDictionary*)timeSeries
                             inputData:(NSString*)inputData
                               options:(NSDictionary*)options;

@end

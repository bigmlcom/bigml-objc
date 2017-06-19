//
//  TopicModel.h
//  bigml-objc
//
//  Created by sergio on 30/06/16.
//  Copyright © 2017 BigML Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FieldResource.h"

@interface TopicModel : FieldResource

+ (NSArray*)predictWithJSONTopicModel:(NSDictionary*)topicModel
                            inputData:(NSString*)inputData
                              options:(NSDictionary*)options;

@end

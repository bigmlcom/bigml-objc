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

#import "BMLResource.h"
#import "BMLResourceTypeIdentifier.h"

@implementation BMLMinimalResource {
    
    NSString* _name;
    BMLResourceTypeIdentifier* _typeIdentifier;
    BMLResourceUuid* _uuid;
}

@synthesize jsonDefinition = _jsonDefinition;
@synthesize status = _status;
@synthesize progress = _progress;

- (NSString*)name {
    return _name;
}

- (BMLResourceTypeIdentifier*)type {
    return _typeIdentifier;
}

- (BMLResourceUuid*)uuid {
    return _uuid;
}

- (BMLResourceFullUuid*)fullUuid {
    return [BMLResourceTypeIdentifier stringWithFormat:@"%@/%@", _typeIdentifier, _uuid];
}

- (instancetype)initWithName:(NSString*)name
                        type:(BMLResourceTypeIdentifier*)type
                        uuid:(BMLResourceUuid*)uuid
                  definition:(NSDictionary*)definition {
    
    if (self = [super init]) {
        _name = name;
        _typeIdentifier = type;
        _uuid = uuid;
        _status = BMLResourceStatusUndefined;
        _progress = 0.0;
        _jsonDefinition = definition;
    }
    return self;
}

- (instancetype)initWithName:(NSString*)name
                    fullUuid:(BMLResourceFullUuid*)fullUuid
                  definition:(NSDictionary*)definition {
    
    NSArray* components = [fullUuid componentsSeparatedByString:@"/"];
    return [self initWithName:name
                         type:components.firstObject
                         uuid:components.lastObject
                   definition:definition];
}

@end

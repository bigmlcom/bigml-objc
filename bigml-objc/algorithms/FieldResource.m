// Copyright 2014-2016 BigML
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

#import "FieldResource.h"

#define DEFAULT_MISSING_TOKENS @[ \
@"", @"N/A", @"n/a", @"NULL", @"null", @"-", @"#DIV/0", \
@"#REF!", @"#NAME?", @"NIL", @"nil", @"NA", @"na", \
@"#VALUE!", @"#NULL!", @"NaN", @"#N/A", @"#NUM!", @"?" \
]


@interface FieldResource ()

@property (nonatomic, strong) NSString* objectiveFieldName;
@property (nonatomic, strong) NSMutableArray* fieldNames;
@property (nonatomic, strong) NSMutableArray* fieldIds;

@property (nonatomic, strong) NSArray* missingTokens;
@property (nonatomic, strong) NSDictionary* invertedFields;
@property (nonatomic, strong) NSString* locale;

@end

@implementation FieldResource {
    
    NSMutableDictionary* _fieldIdByName;
    NSMutableDictionary* _fieldNameById;
}

@synthesize fieldIdByName = _fieldIdByName;
@synthesize fieldNameById = _fieldNameById;

- (instancetype)initWithFields:(NSDictionary*)fields
              objectiveFieldId:(NSString*)objectiveFieldId
                        locale:(NSString*)locale
                 missingTokens:(NSArray*)missingTokens {
    
    if (self = [super init]) {
        
//        for (NSString* fieldName in fields.allKeys) {
//            NSMutableDictionary* field = fields[fieldName];
//            NSAssert(field, @"Missing field %@", fieldName);
//            NSDictionary* modelField = fields[fieldName];
//            [field setObject:modelField[@"summary"] forKey:@"summary"];
//            [field setObject:modelField[@"name"] forKey:@"name"];
//        }
        
        _fields = fields;
        _objectiveFieldId = objectiveFieldId;
        _locale = locale;
        if (_objectiveFieldId)
            _objectiveFieldName = _fields[_objectiveFieldId][@"name"];
        [self makeFieldNamesUnique:_fields];
        if (!_missingTokens)
            _missingTokens = DEFAULT_MISSING_TOKENS;
    }
    return self;
}

- (instancetype)initWithFields:(NSDictionary*)fields {
    return [self initWithFields:fields objectiveFieldId:nil locale:nil missingTokens:nil];
}

- (id)normalizedValue:(id)value {
    return ([_missingTokens indexOfObject:value] != NSNotFound) ? nil : value;
}

- (NSDictionary*)filteredInputData:(NSDictionary*)inputData byName:(BOOL)byName {
    
    NSMutableDictionary* filteredInputData =
    [NSMutableDictionary dictionaryWithCapacity:inputData.allKeys.count];
    for (NSString* __strong fieldId in inputData.allKeys) {

        id value = [self normalizedValue:inputData[fieldId]];
        if (value) {
            if (byName)
                fieldId = _fieldIdByName[fieldId];
            if (fieldId)
                [filteredInputData setObject:value forKey:fieldId];
        }
    }
    return filteredInputData;
}

- (BOOL)checkModelStructure:(NSDictionary*)model {

    return (model[@"resource"] &&
            model[@"object"] &&
            model[@"object"][@"model"]);
}

- (void)addFieldId:(NSString*)fieldId name:(NSString*)name {
    
    [_fieldNames addObject:name];
    [_fieldIdByName setObject:fieldId forKey:name];
    [_fieldNameById setObject:name forKey:fieldId];
}

/**
 * Tests if the fields names are unique. If they aren't, a
 * transformation is applied to ensure unicity.
 */
- (void)makeFieldNamesUnique:(NSDictionary*)fields {
    
    _fieldNames = [NSMutableArray arrayWithCapacity:fields.allKeys.count];
    _fieldIds = [NSMutableArray arrayWithCapacity:fields.allKeys.count];
    _fieldNameById = [NSMutableDictionary dictionaryWithCapacity:fields.allKeys.count];
    _fieldIdByName = [NSMutableDictionary dictionaryWithCapacity:fields.allKeys.count];
    
    if (_objectiveFieldId) {
        [self addFieldId:_objectiveFieldId name:fields[_objectiveFieldId][@"name"]];
    }
    
    for (id fieldId in fields.allKeys) {
        if ([_fieldIds indexOfObject:fieldId] == NSNotFound) {
            [_fieldIds addObject:fieldId];
            NSString* name = fields[fieldId][@"name"];
            if ([_fieldNames indexOfObject:name] != NSNotFound) {
                name = [NSString stringWithFormat:@"%@%@", name, fields[fieldId][@"column_number"]];
                if ([_fieldNames indexOfObject:name] != NSNotFound) {
                    name = [NSString stringWithFormat:@"%@%@", name, fieldId];
                }
            }
            [self addFieldId:fieldId name:name];
            [fields[fieldId] setObject:name forKey:@"name"];
        }
    }
}

+ (NSString*)objectiveField:(id)objectiveField {
    if ([objectiveField isKindOfClass:[NSArray class]])
        return [objectiveField firstObject];
    return objectiveField;
}

@end

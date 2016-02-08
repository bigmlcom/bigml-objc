// Copyright 2014-2015 BigML
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

#import "PredictiveModel.h"
#import "TreePrediction.h"
#import "Predicates.h"
#import "BMLUtils.h"

#define ML4iOS_DEFAULT_LOCALE @"en.US"

@implementation PredictiveModel {
    
    NSDictionary* fields;
    NSString* _description;
    NSMutableArray* _fieldImportance;
    PredictionTree* _tree;
    NSMutableDictionary* _idsMap;
    NSInteger _maxBins;
    
    NSDictionary* _model;
}

- (instancetype)initWithJSONModel:(NSDictionary*)jsonModel {
    
    NSString* locale;
    NSString* objectiveField;
    NSDictionary* model = jsonModel[@"object"] ?: jsonModel;
    
    //-- base model
    NSDictionary* status = model[@"status"];
    NSAssert([status[@"code"] intValue] == 5, @"The model is not ready");
    if ([status[@"code"] intValue] != 5)
        return nil;

    fields = CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault,
                                                            (CFDictionaryRef)model[@"model"][@"model_fields"],
                                                            kCFPropertyListMutableContainers));

    NSDictionary* modelFields = model[@"model"][@"fields"];
    for (NSString* fieldName in fields.allKeys) {
        NSMutableDictionary* field = fields[fieldName];
        NSAssert(field, @"Missing field %@", fieldName);
        NSDictionary* modelField = modelFields[fieldName];
        [field setObject:modelField[@"summary"] forKey:@"summary"];
        [field setObject:modelField[@"name"] forKey:@"name"];
    }
    
    id objectiveFields = model[@"objective_fields"];
    if ([objectiveFields isKindOfClass:[NSArray class]])
        objectiveField = [objectiveFields firstObject];
    else
        objectiveField = objectiveFields;
    
    locale = jsonModel[@"locale"] ?: ML4iOS_DEFAULT_LOCALE;
    
    if (self = [super initWithFields:fields
                    objectiveFieldId:objectiveField
                              locale:locale
                       missingTokens:nil]) {
        
        _maxBins = 0;
        _model = model;
        _description = jsonModel[@"description"] ?: @"";
        NSArray* modelFieldImportance = _model[@"model"][@"importance"];
        
        if (modelFieldImportance) {
            _fieldImportance = [NSMutableArray new];
            for (NSArray* element in modelFieldImportance) {
                if (self.fields[element.firstObject]) {
                    [_fieldImportance addObject:element];
                }
            }
        }
        
        _idsMap = [NSMutableDictionary new];
        _tree = [[PredictionTree alloc] initWithRoot:_model[@"model"][@"root"]
                                              fields:self.fields
                                      objectiveField:objectiveField
                                    rootDistribution:jsonModel[@"model"][@"distribution"][@"training"]
                                            parentId:nil
                                              idsMap:_idsMap
                                             subtree:YES
                                             maxBins:_maxBins];
        
        if (_tree.isRegression) {
            _maxBins = _tree.maxBins;
        }
    }
    return self;
}

- (double)roundedConfidence:(double)confidence {
    return floor(confidence * 10000.0) / 10000.0;
}

- (NSArray*)predictWithArguments:(NSDictionary*)arguments
                         options:(NSDictionary*)options {
    
    BOOL byName = [options[@"byName"]?:@NO boolValue];
    BMLMissingStrategy strategy = [options[@"strategy"]?:@(BMLMissingStrategyLastPrediction) intValue];
    NSUInteger multiple = [options[@"multiple"]?:@0 intValue];
    
    NSAssert(arguments, @"Prediction arguments missing.");
    NSMutableArray* output = [NSMutableArray new];
    
    arguments = [ML4iOSUtils cast:[self filteredInputData:arguments byName:byName]
                           fields:self.fields];
    
    TreePrediction* prediction = [_tree predict:arguments
                                           path:nil
                                       strategy:strategy];
    NSArray* distribution = [prediction distribution];
    NSDictionary* distributionDictionary = [ML4iOSUtils dictionaryFromDistributionArray:distribution];
    long instances = prediction.count;
    if (multiple != 0 && ![_tree isRegression]) {
        for (NSInteger i = 0; i < MIN(distribution.count, multiple); ++i) {
            
            NSArray* distributionElement = distribution[i];
            id category = distributionElement.firstObject;
            double confidence =
            [ML4iOSUtils wsConfidence:category
                         distribution:distributionDictionary];
            [output addObject:@{ @"prediction" : category,
                                 @"confidence" : @([self roundedConfidence:confidence]),
                                 @"probability" : @([distributionElement.lastObject doubleValue] / instances),
                                 @"distribution" : distributionDictionary,
                                 @"count" : @([distributionElement.lastObject longValue])
                                 }];
        }
    } else {
        
        NSArray* children = prediction.children;
        NSString* field = (!children || children.count == 0) ? nil : [(Predicate*)[children.firstObject predicate] field];
        if (field && self.fields[field]) {
            field = self.fieldNameById[field];
        }
        prediction.next = field;
        [output addObject:@{ @"prediction" : prediction.prediction,
                             @"confidence" : @([self roundedConfidence:prediction.confidence]),
                             @"distribution" : distributionDictionary,
                             @"count" : @(prediction.count)
                             }];
    }
    return output;
}

+ (NSDictionary*)predictWithJSONModel:(NSDictionary*)jsonModel
                            arguments:(NSDictionary*)inputData
                              options:(NSDictionary*)options {
    
    if (jsonModel != nil && inputData != nil && inputData.allKeys.count > 0) {
        
        PredictiveModel* predictiveModel = [[PredictiveModel alloc] initWithJSONModel:jsonModel];
        return [predictiveModel predictWithArguments:inputData options:options].firstObject;
    }
    return nil;
}

+ (NSDictionary*)predictWithJSONModel:(NSMutableDictionary*)jsonModel
                            inputData:(NSString*)inputData
                              options:(NSDictionary*)options {
    
    if(jsonModel != nil && inputData != nil) {
        
        NSError *error = nil;
        NSMutableDictionary* arguments =
        [NSJSONSerialization JSONObjectWithData:[inputData dataUsingEncoding:NSUTF8StringEncoding]
                                        options:NSJSONReadingMutableContainers error:&error];
        
        return [self predictWithJSONModel:jsonModel arguments:arguments options:options];
    }
    return nil;
}

@end

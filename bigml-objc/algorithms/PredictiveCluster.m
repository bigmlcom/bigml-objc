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

#import "PredictiveCluster.h"
#import "PredictionCentroid.h"
#import "BMLEnums.h"

@interface PredictiveCluster ()

@property (nonatomic, strong) NSDictionary* fields;
@property (nonatomic, strong) NSMutableDictionary* termForms;
@property (nonatomic, strong) NSMutableDictionary* tagClouds;
@property (nonatomic, strong) NSMutableDictionary* termAnalysis;
@property (nonatomic, strong) NSMutableArray* centroids;
@property (nonatomic, strong) NSDictionary* scales;

@property (nonatomic, strong) NSString* clusterDescription;
@property (nonatomic, strong) NSString* locale;
@property (nonatomic) BOOL ready;

@end

/** A lightweight wrapper around a cluster model.

Uses a BigML remote cluster model to build a local version that can be used
to generate centroid predictions locally.

**/
@implementation PredictiveCluster

+ (NSDictionary*)predictWithJSONCluster:(NSDictionary*)jsonCluster
                              arguments:(NSDictionary*)args
                                options:(NSDictionary*)options {
    
    BOOL byName = [options[@"byName"] ?: @(NO) boolValue];
    NSDictionary* fields = jsonCluster[@"clusters"][@"fields"];
    NSMutableDictionary* inputData = [NSMutableDictionary dictionaryWithCapacity:[fields allKeys].count];
    for (NSString* key in [fields allKeys]) {
        NSString* fieldId = byName ? fields[key][@"name"] : key;
        if (args[fieldId]) {
            [inputData setObject:args[fieldId] forKey:fieldId];
        } else {
            NSAssert(NO, @"All input fields should be provided to calculate a centroid");
        }
    }
    
    return [[[self alloc] initWithCluster:jsonCluster] computeNearest:inputData];
}

- (void)fillStructureForResource:(NSDictionary*)resourceDict {
    
    self.termForms = [NSMutableDictionary dictionary];
    self.tagClouds = [NSMutableDictionary dictionary];
    self.termAnalysis = [NSMutableDictionary dictionary];
    
    NSDictionary* clusters = resourceDict[@"clusters"][@"clusters"];
    self.centroids = [NSMutableArray array];
    for (NSDictionary* cluster in clusters) {
        [_centroids addObject:[[PredictionCentroid alloc] initWithCluster:cluster]];
    }
    self.scales = resourceDict[@"scales"];
    NSDictionary* fields = resourceDict[@"clusters"][@"fields"];
    for (NSString* fieldId in [fields allKeys]) {
        
        NSDictionary* field = fields[fieldId];
        if ([field[@"optype"] isEqualToString:@"text"]) {
            if (field[@"summary"][@"term_forms"])
                self.termForms[fieldId] = field[@"summary"][@"term_forms"]; //-- cannot be found
            if (field[@"summary"][@"tag_cloud"])
                self.tagClouds[fieldId] = field[@"summary"][@"tag_cloud"]; //-- cannot be found
            self.termAnalysis[fieldId] = field[@"term_analysis"];
        }
    }
    self.fields = fields;
//    self.invertedFields = utils.invertObject(fields);
    self.clusterDescription = resourceDict[@"description"];
    self.locale = resourceDict[@"locale"] ?: @"";
    self.ready = true;
}

- (instancetype)initWithCluster:(NSDictionary*)resourceDict {
    
    if (self = [super init]) {
        
        [self fillStructureForResource:resourceDict];
    }
    return self;
}

- (NSMutableArray*)parsePhrase:(NSString*)phrase isCaseSensitive:(BOOL)isCaseSensitive {
 
    NSMutableArray* words = [[phrase componentsSeparatedByCharactersInSet:[NSCharacterSet  whitespaceCharacterSet]] mutableCopy];
    
    if (!isCaseSensitive) {
        for (short i = 0; i < words.count; ++i) {
            words[i] = [words[i] lowercaseString];
        }
    }
    return words;
}

- (NSMutableArray*)uniqueTermsIn:(NSArray*)terms
                       termForms:(NSDictionary*)termForms
                          filter:(NSArray*)filter {
    
    NSMutableDictionary* extendForms = [NSMutableDictionary dictionary];
    NSMutableArray* termSet = [NSMutableArray array];
    NSMutableArray* tagTerms = [NSMutableArray array];
    
    for (id term in filter)
        [tagTerms addObject:term];
    
    for (id term in [termForms allKeys]) {
        for (id termForm in term) {
            extendForms[termForm] = term;
        }
    }
    for (id term in terms) {
        if ([termSet indexOfObject:term] == NSNotFound && [tagTerms indexOfObject:term] != NSNotFound) {
            [termSet addObject:term];
        } else if ([termSet indexOfObject:termSet] == NSNotFound && extendForms[term]) {
            [termSet addObject:extendForms[term]];
        }
    }
    
    return termSet;
}

- (NSDictionary*)computeNearest:(NSDictionary*)inputData {
    
    NSMutableArray* terms = nil;
    NSMutableDictionary* uniqueTerms = [NSMutableDictionary dictionary];
    
    for (NSString* fieldId in [self.tagClouds allKeys]) {
        
        BOOL isCaseSensitive = [self.termAnalysis[fieldId][@"case_sensitive"] boolValue];
        NSString* tokenMode = self.termAnalysis[fieldId][@"tokenMode"];
        NSString* inputDataField = inputData[fieldId];
        if (![tokenMode isEqualToString:TM_FULL_TERMS]) {
            terms = [self parsePhrase:inputDataField isCaseSensitive:isCaseSensitive];
        } else {
            terms = [NSMutableArray array];
        }
        if (![tokenMode isEqualToString:TM_TOKENS]) {
            [terms addObject:(isCaseSensitive ? inputDataField : [inputDataField lowercaseString])];
        }
        uniqueTerms[fieldId] = [self uniqueTermsIn:terms
                                         termForms:self.termForms[fieldId]
                                            filter: self.tagClouds[fieldId]];
    }
    
    NSDictionary* nearest = @{ @"centroidId":@"",
                               @"centroidName":@"",
                               @"distance":@(INFINITY) };
    
    for (PredictionCentroid* centroid in self.centroids) {
        
        float distance2 = [centroid distance2WithInputData:inputData
                                               uniqueTerms:uniqueTerms
                                                    scales:self.scales
                                           nearestDistance:[nearest[@"distance"] floatValue]];
        
        if (distance2 < [nearest[@"distance"] floatValue]) {
            
            nearest = @{ @"centroidId":@(centroid.centroidId),
                         @"centroidName":centroid.name,
                         @"distance":@(distance2) };
        }
    }
    
    return @{ @"centroidId":nearest[@"centroidId"],
              @"centroidName":nearest[@"centroidName"],
              @"distance":@(sqrt([nearest[@"distance"] floatValue])) };
}

- (id)makeCentroid:(NSDictionary*)inputData callback:(id(^)(NSError*, id))callback {
    
    id(^createLocalCentroid)(NSError*, NSDictionary*) = ^id(NSError* error, NSDictionary* inputData) {
        
        if (error) {
            return callback(error, nil);
        }
        return callback(nil, [self computeNearest:inputData]);
    };
    
    if (callback) {
        return [self validateInput:inputData callback:createLocalCentroid];
    } else {
        return [self computeNearest:[self validateInput:inputData callback:nil]];
    }

}

- (id)validateInput:(NSDictionary*)inputData callback:(id(^)(NSError*, NSDictionary*))createLocalCentroid {
    
    for (NSString* fieldId in [self.fields allKeys]) {
        
        NSDictionary* field = self.fields[fieldId];
        if ([field[@"optype"] isEqualToString:@"categorical"] &&
            ![field[@"optype"] isEqualToString:@"text"]) {
         
            NSAssert(inputData[fieldId] && inputData[field[@"name"]], @"Cluster validateInput: Should not be here");
            return nil;
        }
    }
    
    NSMutableDictionary* newInputData = [NSMutableDictionary dictionary];
    for (NSString* field in inputData) {

        id inputDataKey = field;
        newInputData[inputDataKey] = inputData[field];
    }
    
    NSError* error = nil;
    if (createLocalCentroid)
        return createLocalCentroid(error, inputData);
    else
        return inputData;
}


@end

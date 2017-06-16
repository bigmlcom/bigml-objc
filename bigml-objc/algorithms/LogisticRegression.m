//
//  LogisticRegression.m
//  bigml-objc
//
//  Created by sergio on 21/03/16.
//  Copyright © 2017 BigML Inc. All rights reserved.
//

#import "LogisticRegression.h"
#import "BMLUtils.h"
#import "BMLEnums.h"

@interface LogisticRegression ()

@property (nonatomic, strong) NSArray* optionalFields;
@property (nonatomic, strong) NSDictionary* expansionAttributes;

@property (nonatomic, strong) NSMutableDictionary* termForms;
@property (nonatomic, strong) NSMutableDictionary* tagClouds;
@property (nonatomic, strong) NSMutableDictionary* termAnalysis;
@property (nonatomic, strong) NSMutableDictionary* items;
@property (nonatomic, strong) NSMutableDictionary* itemAnalysis;


@property (nonatomic, strong) NSMutableDictionary* categories;
@property (nonatomic, strong) NSMutableDictionary* coefficients;
@property (nonatomic, strong) NSDictionary* scales;
@property (nonatomic, strong) NSDictionary* dataset_field_types;

@property (nonatomic, strong) NSString* c;
@property (nonatomic, strong) NSString* eps;
@property (nonatomic, strong) NSString* lrNormalize;
@property (nonatomic, strong) NSString* regularization;
@property (nonatomic) BOOL missingCoefficients;
@property (nonatomic) NSInteger bias;

@end

NSArray* getFirstFromTupleArray(NSArray* tuples) {
    
    NSMutableArray* result = [NSMutableArray array];
    for (NSArray* tuple in tuples) {
        [result addObject:tuple.firstObject];
    }
    return result;
}

NSArray* distributionFromArray(NSArray* tuples) {
    
    NSMutableArray* result = [NSMutableArray array];
    for (NSArray* tuple in tuples) {
        [result addObject:@{ @"category": tuple.firstObject, @"probability" : tuple.lastObject }];
    }
    return result;
}

@implementation LogisticRegression

- (instancetype)initWithLogisticRegression:(NSDictionary*)logisticRegression {
    
    NSDictionary* logisticRegressionInfo = logisticRegression[@"logistic_regression"];
    NSDictionary* fields = logisticRegressionInfo[@"fields"];

    NSAssert(fields && [fields count] > 0,
             @"LR constructor's contract unfulfilled: no fields");
    NSAssert([logisticRegression[@"dataset_field_types"] count] > 0,
             @"LR constructor's contract unfulfilled: no dataset_field_types");
    NSAssert([logisticRegression[@"status"][@"code"] intValue] == 5,
             @"LR constructor's contract unfulfilled: anomaly did not finish processing");
    
    id objectiveField = logisticRegression[@"objective_fields"];
    NSString* objectiveId = [FieldResource objectiveField:objectiveField];

    if (self = [super initWithFields:fields
                    objectiveFieldId:objectiveId
                              locale:nil
                       missingTokens:nil]) {
        
        self.optionalFields = @[@"categorical", @"text", @"items"];
        self.expansionAttributes = @{ @"categorical" : @"categories",
                                      @"text" : @"tag_cloud",
                                       @"items" : @"items" };
        self.missingCoefficients = true;
        self.dataset_field_types = logisticRegression[@"dataset_field_types"];
        self.coefficients = logisticRegressionInfo[@"coefficients"];
        self.bias = [logisticRegressionInfo[@"bias"] boolValue];
        self.c = logisticRegressionInfo[@"c"];
        self.eps = logisticRegressionInfo[@"eps"];
        self.lrNormalize = logisticRegressionInfo[@"normalize"];
        self.regularization = logisticRegressionInfo[@"regularization"];

        for (id fieldId in [fields allKeys]) {
            NSDictionary* field = fields[fieldId];
            if ([field[@"optype"] isEqualToString:@"text"]) {
                
                self.termForms[fieldId] = @{};
                self.termForms[fieldId] = field[@"summary"][@"term_forms"];
                self.tagClouds[fieldId] = getFirstFromTupleArray(field[@"summary"][@"tag_cloud"]);
                self.termAnalysis[fieldId] = field[@"term_analysis"];
                
            } else if ([field[@"optype"] isEqualToString:@"items"]) {
                
                self.items[fieldId] = getFirstFromTupleArray(field[@"summary"][@"items"]);
                self.itemAnalysis[fieldId] = field[@"item_analysis"];
            } else if ([field[@"optype"] isEqualToString:@"categorical"]) {
                self.categories[fieldId] =  getFirstFromTupleArray(field[@"summary"][@"categories"]);
            }
        }
        [self mapCoefficients];
    }
    return self;
}

+ (NSDictionary*)predictWithJSONLogisticRegression:(NSDictionary*)logisticRegression
                                  args:(NSDictionary*)inputData
                               options:(NSDictionary*)options {
    
    return [[[self alloc] initWithLogisticRegression:logisticRegression]
            predictWithData:inputData
            options:options];
}

- (NSDictionary*)predictWithData:(NSDictionary*)input options:(NSDictionary*)options {
    
    NSDictionary* inputData = [self filteredInputData:input byName:[options[@"byName"] boolValue]];
    for (id fieldId in [self.fields allKeys]) {
        NSDictionary* field = self.fields[fieldId];
        if ([self.optionalFields indexOfObject:field[@"optype"]] == NSNotFound &&
            [inputData.allKeys indexOfObject:fieldId] == NSNotFound) {
            NSAssert(NO, @"All input fields should be provided.");
        }
    }
    
    inputData = [BMLUtils cast:[self filteredInputData:inputData
                                                byName:[options[@"byName"] boolValue]]
                        fields:self.fields];

    NSDictionary* uniqueTerms = [self uniqueTerms:inputData];
    NSMutableDictionary* probabilities = [NSMutableDictionary dictionary];
    NSInteger total = 0;
    for (id category in self.categories[self.objectiveFieldId]) {
        
        NSArray* coefficients = self.coefficients[category];
        probabilities[category] = @([self categoryProbability:inputData
                                                uniqueTerms:uniqueTerms
                                               coefficients:coefficients]);
        total += [probabilities[category] intValue];
    }
    for (NSString* category in probabilities.allKeys) {
        probabilities[category] = @([probabilities[category] intValue] / total);
    }
    NSArray* predictions = [probabilities.allValues
                            sortedArrayUsingComparator:^NSComparisonResult(NSArray* a, NSArray* b) {
                                return [b.firstObject compare:a.firstObject];
                            }];

    return @{ @"prediction" : [predictions.firstObject firstObject],
              @"probability" : [predictions.firstObject lastObject],
              @"distribution" : distributionFromArray(predictions)};
}

- (double)categoryProbability:(NSDictionary*)inputData
                  uniqueTerms:(NSDictionary*)uniqueTerms
                 coefficients:(NSArray*)coefficients {
    
    double probability = 0.0;
    for (NSString* fieldId in inputData.allKeys) {
        NSNumber* shift = self.fields[fieldId][@"coefficients_shift"];
        probability += [coefficients[shift.intValue] doubleValue] * [inputData[fieldId] doubleValue];
    }
    for (NSString* fieldId in uniqueTerms) {
        NSInteger ocurrences = [uniqueTerms[fieldId] intValue];
        NSNumber* shift = self.fields[fieldId][@"coefficients_shift"];
        NSInteger index = 0;
        for (NSString* term in [uniqueTerms[fieldId] allKeys]) {
            if ([self.tagClouds.allKeys containsObject:fieldId]) {
                index = [self.tagClouds[fieldId] indexOfObject:term];
            } else if ([self.items.allKeys containsObject:fieldId]) {
                index = [self.items[fieldId] indexOfObject:term];
            } else if ([self.categories.allKeys containsObject:fieldId]) {
                index = [[self.categories[fieldId] allKeys] containsObject:term];
            }
            probability += [coefficients[shift.intValue] doubleValue] * ocurrences;
        }
    }
    if (self.missingCoefficients) {
        for (NSString* fieldId in self.tagClouds.allKeys) {
            if (![uniqueTerms.allKeys containsObject:fieldId] ||
                !uniqueTerms[fieldId]) {
                NSNumber* shift = self.fields[fieldId][@"coefficients_shift"];
                probability += [coefficients[shift.intValue + [self.tagClouds[fieldId] count]] doubleValue];
            }
        }
        for (NSString* fieldId in self.items.allKeys) {
            if (![uniqueTerms.allKeys containsObject:fieldId] ||
                !uniqueTerms[fieldId]) {
                NSNumber* shift = self.fields[fieldId][@"coefficients_shift"];
                probability += [coefficients[shift.intValue + [self.items[fieldId] count]] doubleValue];
            }
        }
        for (NSString* fieldId in self.categories.allKeys) {
            if (self.objectiveFieldId != fieldId && ![uniqueTerms.allKeys containsObject:fieldId]) {
                NSNumber* shift = self.fields[fieldId][@"coefficients_shift"];
                probability += [coefficients[shift.intValue + [self.categories[fieldId] count]] doubleValue];
            }
        }
    }
    probability += [coefficients.lastObject doubleValue];
    probability = 1 / (1 + exp(-probability));
    return probability;
}

- (NSDictionary*)uniqueTerms:(NSDictionary*)inputData {
    
    NSMutableDictionary* uniqueTerms = [NSMutableDictionary dictionary];
    for (NSString* fieldId in self.termForms.allKeys) {
        if ([inputData.allKeys containsObject:fieldId]) {
            id inputDataField = inputData[fieldId] ?: @"";
            if ([inputDataField isKindOfClass:[NSString class]]) {
                BOOL caseSensitive = [self.termAnalysis[fieldId][@"case_sensitive"] boolValue];
                NSString* tokenMode = self.termAnalysis[fieldId][@"token_mode"] ?: @"all";
                NSMutableArray* terms = [NSMutableArray array];
                if (![tokenMode isEqualToString:TM_FULL_TERMS]) {
                    terms = [[self parseTerms:inputDataField caseSensitive:caseSensitive] mutableCopy];
                }
                if (![tokenMode isEqualToString:TM_TOKENS]) {
                    [terms addObject:caseSensitive ? inputDataField :
                     [inputDataField lowercaseString]];
                }
                uniqueTerms[fieldId] = [self uniqueTermsIn:terms
                                                 termForms:self.termForms[fieldId]
                                                 tagClound:self.tagClouds[fieldId]];
            } else {
                uniqueTerms[fieldId] = @[@[inputDataField, @1]];
            }
            //-- REMOVING FIELD_ID ITEM FROM INPUT_DATA???
        }
    }
    for (NSString* fieldId in self.itemAnalysis.allKeys) {
        if ([inputData.allKeys containsObject:fieldId]) {
            id inputDataField = inputData[fieldId] ?: @"";
            if ([inputDataField isKindOfClass:[NSString class]]) {
                NSString* separator = self.itemAnalysis[fieldId][@"separator"] ?: @" ";
                NSString* regexp = self.itemAnalysis[fieldId][@"separator_regexp"] ?: separator;
                NSArray* terms = [self parseItems:inputDataField regexp:regexp];
                uniqueTerms[fieldId] = [self uniqueTermsIn:terms
                                                 termForms:@{}
                                                 tagClound:self.items[fieldId] ?: @{}];
            } else {
                uniqueTerms[fieldId] = @[@[inputDataField, @1]];
            }
            //-- REMOVING FIELD_ID ITEM FROM INPUT_DATA???
        }
    }
    for (NSString* fieldId in self.itemAnalysis.allKeys) {
        if ([inputData.allKeys containsObject:fieldId]) {
            id inputDataField = inputData[fieldId] ?: @"";
            uniqueTerms[fieldId] = @[@[inputDataField, @1]];
            //-- REMOVING FIELD_ID ITEM FROM INPUT_DATA???
        }
    }
    return uniqueTerms;
}

- (void)mapCoefficients {
    
    //-- TODO: Compare with logistic.py, which uses sorting
    NSMutableArray* fieldIds = [NSMutableArray array];
    NSInteger shift = 0;
    NSInteger length = 0;
    for (NSString* fieldId in fieldIds) {
        NSString* optype = self.fields[fieldId][@"optype"];
        if ([self.expansionAttributes.allKeys containsObject:optype]) {
            length = [self.fields[fieldId][@"summary"][self.expansionAttributes[optype]] count];
            if (self.missingCoefficients)
                length++;
        } else {
            length = 1;
        }
        self.fields[fieldId][@"coefficient_shift"] = @(shift);
        shift += length;
    }
}

- (NSArray*)parseTerms:(NSString*)text caseSensitive:(BOOL)caseSensitive {
    
    NSMutableArray* matches = [NSMutableArray array];
    if (text) {
        NSRange searchedRange = NSMakeRange(0, [text length]);
        NSString* pattern = @"(\\b|_)([^\\b_\\s]+?)(\\b|_)";
        NSError* error = nil;
        
        NSRegularExpression* regex = [NSRegularExpression
                                      regularExpressionWithPattern:pattern
                                      options:0
                                      error:&error];
        if (!error) {

            for (NSTextCheckingResult* match in
                    [regex matchesInString:text options:0 range:searchedRange]) {
                NSString* matchText = [text substringWithRange:[match range]];
                NSLog(@"match: %@", matchText);
                
                if (!caseSensitive) {
                    matchText = [matchText lowercaseString];
                }
                [matches addObject:matchText];
            }
        }
    }
    return matches;
}

- (NSArray*)parseItems:(NSString*)text regexp:(NSString*)regexp {

    return text ? [text componentsSeparatedByString:regexp] : @[];
}

- (NSMutableDictionary*)uniqueTermsIn:(NSArray*)terms
                            termForms:(NSDictionary*)termForms
                            tagClound:(NSArray*)tagCloud {
    
    NSMutableDictionary* extendForms = [NSMutableDictionary dictionary];
    NSMutableDictionary* termSet = [NSMutableDictionary dictionary];
    NSInteger termsLength = [terms count];
    
    for (id term in termForms) {
        if (termForms[term]) {
            NSInteger termFormsLengh = [term count];
            for (int i = 0; i < termFormsLengh; i++) {
                id termForm = term[i];
                extendForms[termForm] = term;
            }
        }
        
        for (int i = 0; i < termsLength; i++) {
            id term = terms[i];
            if ([tagCloud indexOfObject:term]) {
                if (!termSet[term]) {
                    termSet[term] = @(0);
                }
                termSet[term] = @([termSet[term] integerValue] + 1);
            } else if (extendForms[term]) {
                term = extendForms[term];
                if (!termSet[term]) {
                    termSet[term] = @(0);
                }
                termSet[term] = @([termSet[term] integerValue] + 1);
            }
        }
    }
    return termSet;
}



@end

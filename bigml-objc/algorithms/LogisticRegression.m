//
//  LogisticRegression.m
//  bigml-objc
//
//  Created by sergio on 21/03/16.
//  Copyright © 2017 BigML Inc. All rights reserved.
//

#import "LogisticRegression.h"

@interface LogisticRegression ()

@property (nonatomic, strong) NSDictionary* fields;
@property (nonatomic, strong) NSMutableDictionary* termForms;
@property (nonatomic, strong) NSMutableDictionary* tagClouds;
@property (nonatomic, strong) NSMutableDictionary* termAnalysis;
@property (nonatomic, strong) NSMutableDictionary* categories;
@property (nonatomic, strong) NSMutableArray* coefficients;
@property (nonatomic, strong) NSDictionary* scales;
@property (nonatomic, strong) NSDictionary* dataset_field_types;

@property (nonatomic, strong) NSString* c;
@property (nonatomic, strong) NSString* eps;
@property (nonatomic, strong) NSString* lrNormalize;
@property (nonatomic, strong) NSString* regularization;
@property (nonatomic) NSInteger bias;

@end

NSArray* getFirstFromTupleArray(NSArray* tuples) {
    
    NSMutableArray* result = [NSMutableArray array];
    for (NSArray* tuple in tuples) {
        [result addObject:tuple.firstObject];
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
                
                //-- TODO: iterate ovet the tag_cloud and get its first elements
                self.tagClouds[fieldId] = getFirstFromTupleArray(field[@"summary"][@"tag_cloud"]);
                self.termAnalysis[fieldId] = field[@"term_analysis"];
                
            } else if ([field[@"optype"] isEqualToString:@"categorical"]) {
                //-- TODO: iterate ovet the tag_cloud and get its first elements
                self.categories[fieldId] =  getFirstFromTupleArray(field[@"summary"][@"categories"]);
            }
        }
    }
    return self;
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
//                NSRange group1 = [match rangeAtIndex:1];
//                NSRange group2 = [match rangeAtIndex:2];
//                [text substringWithRange:group1]);
//                NSLog(@"group2: %@", [searchedString substringWithRange:group2]);
            }
        }
    }
    return matches;
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

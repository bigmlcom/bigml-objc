//
//  TopicModel.m
//  bigml-objc
//
//  Created by sergio on 30/06/16.
//  Copyright © 2017 BigML Inc. All rights reserved.
//

#import "TopicModel.h"

#define MAXIMUM_TERM_LENGTH 30
#define MIN_UPDATES 16
#define MAX_UPDATES 512
#define SAMPLES_PER_TOPIC 128

@interface TopicModel ()

@property (nonatomic, strong) NSDictionary* CodeName;

@property (nonatomic, strong) NSMutableDictionary* termToIndex;
@property (nonatomic, strong) NSArray* topics;
@property (nonatomic, strong) NSString* resourceId;

@property (nonatomic) NSInteger seed;
@property (nonatomic) BOOL caseSensitive;
@property (nonatomic) NSInteger ntopics;
@property (nonatomic) NSInteger ktimesalpha;
@property (nonatomic) NSInteger alpha;
@property (nonatomic, strong) NSArray* bigrams;
@property (nonatomic, strong) NSMutableArray* phi;
@property (nonatomic, strong) NSMutableArray* temp;

@end


@implementation TopicModel

+ (NSArray*)predictWithJSONTopicModel:(NSDictionary*)topicModel
                                 inputData:(NSString*)inputData
                                   options:(NSDictionary*)options {
    
    return [[[self alloc] initWithTopicModel:topicModel]
            distributionForText:inputData];
}

- (instancetype)initWithTopicModel:(NSDictionary*)topicModel {

    self.CodeName= @{ @"da" : @"danish",
                      @"nl" : @"dutch",
                      @"en" : @"english",
                      @"fi" : @"finnish",
                      @"fr" : @"french",
                      @"de" : @"deutsch",
                      @"hu" : @"hungarian",
                      @"it" : @"italian",
                      @"nn" : @"norwegian",
                      @"pt" : @"portuguese",
                      @"ro" : @"romanian",
                      @"ru" : @"russian",
                      @"es" : @"spanish",
                      @"sv" : @"swedish",
                      @"tr" : @"turkish" };
    
    
    self.resourceId = topicModel[@"resource"];
    topicModel = topicModel[@"object"];
    if ([topicModel[@"status"][@"code"] intValue] == 5) {
        NSDictionary* model = topicModel[@"topic_model"];
        
        if (self = [super initWithFields:model[@"fields"]]) {
            self.topics = model[@"topics"];
            if (model[@"language"]) {
                
                NSString* lang = model[@"language"];
                if ([self.CodeName.allKeys containsObject:lang]) {
                }
                self.termToIndex = [NSMutableDictionary dictionary];
                for (NSString* term in model[@"termset"]) {
                    self.termToIndex[term] = [self stem:term];
                }
                self.seed = abs([model[@"hashed_seed"] intValue]);
                self.caseSensitive = [model[@"hashed_seed"] boolValue];
                self.bigrams = model[@"hashed_seed"];
                
                self.ntopics = [[model[@"term_topic_assignments"] firstObject] count];
                self.alpha = [model[@"alpha"] intValue];
                self.ktimesalpha = self.ntopics * self.alpha;
                
                self.temp = [NSMutableArray array];
                for (int i = 0 ; i < self.ntopics; ++i) {
                    self.temp[i] = @0;
                }
                NSArray* assignments = model[@"term_topic_assignments"];
                NSInteger beta = [model[@"beta"] intValue];
                NSInteger nterms = [self.termToIndex count];
                
                NSMutableArray* sums = [NSMutableArray array];
                for (int i = 0; i < self.ntopics; ++i) {
                    NSInteger sum = 0;
                    for (NSDictionary* n in assignments) {
                        sum += [n[@"index"] intValue];
                    }
                    [sums addObject:@(sum)];
                }
                self.phi = [NSMutableArray array];
                for (int i = 0; i < nterms; ++i) {
                    [self.phi addObject:[NSMutableArray array]];
                    for (int j = 0; j < self.ntopics; ++j) {
                        [self.phi[i] addObject:@(0)];
                    }
                }
                for (int k = 0; k < self.ntopics; ++k) {
                    NSInteger norm = [sums[k] intValue] + nterms * beta;
                    for (int w = 0; w < nterms; ++w) {
                        self.phi[k][w] = @(([assignments[w][k] intValue] + beta) / norm);
                    }
                }
            }
        }
    } else {
        NSAssert(NO, @"The TopicModel is not ready yet");
    }
    return self;
}

- (NSArray*)distribution:(NSDictionary*)inputData byName:(BOOL)byName {
    inputData = [self filteredInputData:inputData byName:byName];
    return [self distributionForText:[inputData.allValues componentsJoinedByString:@"\n\n"]];
}

- (NSArray*)distributionForText:(NSString*)text {
    NSArray* doc = [self tokenize:text];
    NSArray* topicProbability = [self infer:doc];
    NSMutableArray* result = [NSMutableArray array];
    for (int i = 0 ; i < [topicProbability count]; ++i) {
        id probability = topicProbability[i];
        [result addObject:@{ @"name" : self.topics[i][@"name"],
                             @"probability" : probability }];
    }
    return result;
}

- (NSString*)stem:(NSString*)term {
    return term;
}

- (void)appendBigram:(NSMutableArray*)terms before:(NSString*)first last:(NSString*)second {
    
    if (self.bigrams && first && second) {
        NSString* bigram = [self stem:[NSString stringWithFormat:@"%@ %@", first, second]];
        if ([self.termToIndex.allKeys containsObject:bigram]) {
            [terms addObject:self.termToIndex[bigram]];
        }
    }
}

- (NSArray*)tokenize:(NSString*)text {

    NSMutableArray* outTerms = [NSMutableArray array];
    NSString* lastTerm = nil;
    NSString* termBefore = nil;
    
    BOOL spaceWasSep = NO;
    BOOL sawChar = NO;
    
    NSInteger index = 0;
    NSInteger length = [text length];
    
    BOOL (^isAlphaNumeric)(NSString*) = ^BOOL(NSString* s) {
        NSCharacterSet* alphaSet = [NSCharacterSet alphanumericCharacterSet];
        return [[s stringByTrimmingCharactersInSet:alphaSet] isEqualToString:@""];
    };
    
    NSInteger (^nextIndex)(NSString*, NSInteger) = ^NSInteger(NSString* t, NSInteger index) {
        if (index + 1 < length) {
            return index + 1;
        }
        return index;
    };
    
    while (index < length) {
        
        [self appendBigram:outTerms before:termBefore last:lastTerm];

        NSString* c = [text substringWithRange:NSMakeRange(index, 0)];
        NSString* buf = @"";
        sawChar = NO;
        
        if (!isAlphaNumeric(c)) {
            sawChar = YES;
        }
        while (!isAlphaNumeric(c) && index < length) {
            index = nextIndex(text, index);
            c = [text substringWithRange:NSMakeRange(index, 0)];
        }
        while (index < length && isAlphaNumeric(c) && buf.length < MAXIMUM_TERM_LENGTH) {
            buf = [buf stringByAppendingString:c];
            index = nextIndex(text, index);
            c = [text substringWithRange:NSMakeRange(index, 0)];
        }
        if (buf.length > 0) {
            NSString* termOut = buf;
            if (!self.caseSensitive) {
                termOut = [termOut lowercaseString];
            }
            if (spaceWasSep && !sawChar) {
                termBefore = lastTerm;
            } else {
                termBefore = nil;
            }
            lastTerm = termOut;
            if ([c isEqualToString:@" "] ||
                [c isEqualToString:@"\n"]) {
                spaceWasSep = YES;
            }
            NSString* tstem = [self stem:termOut];
            if ([self.termToIndex.allKeys containsObject:tstem]) {
                [outTerms addObject:tstem];
            }
        }
    }
    [self appendBigram:outTerms before:termBefore last:lastTerm];
    return outTerms;
}

- (NSArray*)sampleUniform:(NSArray*)document
                 updates:(NSInteger)updates
                     rng:(double)rng {
    
    NSMutableArray* counts = [NSMutableArray array];
    for (int i = 0 ; i < self.ntopics; ++i) {
        counts[i] = @0;
    }
    for (int i = 0 ; i < updates; ++i) {
        for (NSString* term in document) {
            for (int k = 0; k < self.ntopics; ++k) {
                self.temp[k] = self.phi[k][term];
            }
            for (int k = 0 ; k < self.ntopics; ++k) {
                self.temp[k] = @([self.temp[k] doubleValue] + [self.temp[k-1] doubleValue]);
            }
            double randomValue = rng * [self.temp.lastObject doubleValue];
            NSInteger topic = 0;
            while ([self.temp[topic] doubleValue] < randomValue && topic < self.ntopics) {
                ++topic;
            }
            counts[topic] = @([counts[topic] intValue] + 1);
        }
    }
    return counts;
}

- (NSArray*)sampleTopics:(NSArray*)document
             assignments:(NSArray*)assignments
              normalizer:(NSInteger)normalizer
                 updates:(NSInteger)updates
                     rng:(double)rng {
    
    NSMutableArray* counts = [NSMutableArray array];
    for (int i = 0 ; i < self.ntopics; ++i) {
        counts[i] = @0;
    }
    for (int i = 0 ; i < updates; ++i) {
        for (NSString* term in document) {
            for (int k = 0 ; k < self.ntopics; ++k) {
                NSInteger topicTerm = [self.phi[k][term] intValue];
                double topicDocument = ([assignments[k] doubleValue] + self.alpha) / normalizer;
                self.temp[k] = @(topicTerm * topicDocument);
            }
            for (int k = 0 ; k < self.ntopics; ++k) {
                self.temp[k] = @([self.temp[k] doubleValue] + [self.temp[k-1] doubleValue]);
            }
            double randomValue = rng * [self.temp.lastObject doubleValue];
            NSInteger topic = 0;
            while ([self.temp[topic] doubleValue] < randomValue && topic < self.ntopics) {
                ++topic;
            }
            counts[topic] = @([counts[topic] intValue] + 1);
        }
    }
    return counts;
}

- (NSArray*)infer:(NSArray*)indices {
    
    //-- TODO: doc should be sorted!!
    NSArray* doc = indices;
    NSInteger updates = 0;
    
    if ([doc count] > 0) {
        updates = SAMPLES_PER_TOPIC * self.ntopics / [doc count];
        updates = MIN(MAX_UPDATES, MAX(MIN_UPDATES, updates));
    }
    
    srand((unsigned int)self.seed);
    double rng = rand();
    NSInteger normalizer = ([doc count] * updates) * self.ktimesalpha;
    
    NSArray* uniformCounts = [self sampleUniform:doc updates:updates rng:rng];
    NSArray* burnCounts = [self sampleTopics:doc
                                 assignments:uniformCounts
                                  normalizer:normalizer
                                     updates:updates
                                         rng:rng];
    NSArray* sampleCounts = [self sampleTopics:doc
                                 assignments:burnCounts
                                  normalizer:normalizer
                                     updates:updates
                                         rng:rng];
    
    NSMutableArray* result = [NSMutableArray array];
    for (int i = 0 ; i < self.ntopics; ++i) {
        [result addObject:@(([sampleCounts[i] intValue] + self.alpha) / normalizer)];
    }
    return result;
}

@end
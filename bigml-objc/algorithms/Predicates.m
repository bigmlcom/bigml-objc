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

#import "Predicates.h"

NSString* plural(NSString* string, int multiplicity) {
    
    if (multiplicity == 1) {
        return string;
    }
    return [NSString stringWithFormat:@"%@s", string];
}

@implementation RegExHelper

+ (NSString*)firstRegexMatch:(NSString*)regex in:(NSString*)string {
    
    NSString* result = nil;
    NSError* error = nil;
    NSRegularExpression* r = [NSRegularExpression
                              regularExpressionWithPattern:regex
                              options:0
                              error:&error];
    NSAssert(!error, @"Error in regex: %@", [error localizedDescription]);
    if (!error) {
        NSRange range = [r rangeOfFirstMatchInString:string
                                             options:0
                                               range:NSMakeRange(0, [string length])];
        if (range.location != NSNotFound) {
            result = [string substringWithRange:range];
        }
    }
    return result;
}

+ (BOOL)isRegex:(NSString*)regex matching:(NSString*)string {
    return [self firstRegexMatch:regex in:string].length > 0;
}

+ (NSUInteger)countOfMatches:(NSString*)regex in:(NSString*)string {
    return [self firstRegexMatch:regex in:string].length;
}

@end


#define TM_TOKENS @"tokens_only"
#define TM_FULL_TERMS @"full_terms_only"
#define TM_ALL @"all"
#define FULL_TERM_PATTERN @"^.+\\b.+$"

@implementation Predicate {

    NSString* _op;
    NSString* _field;
    id _value;
    NSString* _term;
}

- (instancetype)initWithOperator:(NSString*)op
                         field:(NSString*)field
                         value:(id)value
                          term:(NSString*)term {

    if (self = [super init]) {
        _op = op;
        _field = field;
        _value = value;
        _term = term;
        _missing = NO;
        if ([RegExHelper isRegex:@"\\*$" matching:_op]) {
            _missing = YES;
            _op = [_op substringToIndex:_op.length - 1];
        }
        if ([_op length] == 0)
            NSLog(@"CONY");

    }
    return self;
}

/**
 * Returns a boolean showing if a term is considered as a full_term
 */
- (BOOL)isFullTermWithFields:(NSDictionary*)fields {
    
    if (_term && fields[self.field][@"term_analysis"]) {
    
        NSAssert([fields[self.field] isKindOfClass:[NSDictionary class]], @"Bad fields");
        NSAssert(!fields[self.field][@"term_analysis"] ||
                 [fields[self.field][@"term_analysis"] isKindOfClass:[NSDictionary class]],
                 @"Bad term_analysis");

        if ([fields[self.field][@"term_analysis"][@"token_mode"] isEqualToString:TM_FULL_TERMS]) {
            return YES;
        }
        if ([fields[self.field][@"term_analysis"][@"token_mode"] isEqualToString:TM_ALL]) {
            return [RegExHelper isRegex:FULL_TERM_PATTERN matching:_term];
        }
    }
    return NO;
}

/* build rule string from predicate
 */
- (NSString*)ruleWithFields:(NSDictionary*)fields label:(NSString*)label {
    
    NSAssert([fields[_field] isKindOfClass:[NSDictionary class]], @"Bad fields");

    label = label ?: @"name";
    
    if ([fields[_field][label] isKindOfClass:[NSString class]]) {
        NSString* name = fields[_field][label];
        BOOL isFullTerm = [self isFullTermWithFields:fields];
        NSString* relationMissing = _missing ? @" or missing " : @"";
        
        if (_term) {
            NSString* relationSuffix = @"";
            NSString* relationLiteral = @"";
            if (([_op isEqualToString:@"<"] && [_value intValue] <= 1) ||
                ([_op isEqualToString:@"<="] && [_value intValue] == 0)) {
                relationLiteral = isFullTerm ? @" is not equal to " : @" does not contain ";
            } else {
                relationLiteral = isFullTerm ? @" is equal to " : @" contains ";
                if (!isFullTerm) {
                    if ([_op isEqualToString:@">"] && [_value intValue] != 0) {
                        NSString* times = plural(@"time", [_value intValue]);
                        if ([_op isEqualToString:@">="]) {
                            relationSuffix = [NSString stringWithFormat:@"%@ %@ at most", _value, times];
                        } else if ([_op isEqualToString:@"<="]) {
                            relationSuffix = [NSString stringWithFormat:@"no more than %@ %@", _value, times];
                        } else if ([_op isEqualToString:@">"]) {
                            relationSuffix = [NSString stringWithFormat:@"more than %@ %@", _value, times];
                        } else if ([_op isEqualToString:@"<"]) {
                            relationSuffix = [NSString stringWithFormat:@"less than %@ %@", _value, times];
                        }
                    }
                }
            }
            return [NSString stringWithFormat:@"%@ %@ %@ %@%@", name, relationLiteral, _term, relationSuffix,
                    relationMissing];
        }
        if (!_value) {
            return [NSString stringWithFormat:@"%@ %@", name,
                    [_op isEqualToString:@"="] ? @"is None" : @"is not None"];
        } else {
            return [NSString stringWithFormat:@"%@ %@ %@ %@", name, _op, _value, relationMissing];
        }
    }
    return  _op;
}

- (NSInteger)fullTermCount:(NSString*)text
                  fullTerm:(NSString*)fullTerm
             caseSensitive:(BOOL)caseSensitive {
    
    return (caseSensitive ?
            ((text == fullTerm) ? 1 : 0) :
            ([RegExHelper isRegex:@"/^\(fullTerm)$/i" matching:text] ? 1 : 0));
}

- (NSInteger)tokenTermCount:(NSString*)text
                   forms:(NSArray*)forms
              caseSensitive:(BOOL)caseSensitive {

    NSString* fre = [forms componentsJoinedByString:@"(\\b|_)"];
    NSString* re = [NSString stringWithFormat:@"(\\b|_)%@(\\b|_)", fre];
    return [RegExHelper countOfMatches:re in:text];
}

- (NSInteger)termCount:(NSString*)text forms:(NSArray*)forms options:(NSDictionary*)options {
    
    NSString* tokenMode = TM_TOKENS;
    BOOL caseSensitive = YES;
    if (options && [options[@"token_mode"] isKindOfClass:[NSString class]]) {
        tokenMode = options[@"token_mode"];
    }
    if (options && [options[@"case_sensitive"] respondsToSelector:@selector(boolValue)]) {
        caseSensitive = [options[@"case_sensitive"] boolValue];
    }
    NSString* firstTerm = forms.firstObject;
    if ([tokenMode isEqualToString:TM_FULL_TERMS] ||
        ([tokenMode isEqualToString:TM_ALL] &&
         forms.count == 1 &&
         [RegExHelper isRegex:FULL_TERM_PATTERN matching:firstTerm])) {
            
        return [self fullTermCount:text fullTerm:firstTerm caseSensitive:caseSensitive];
    }
    return [self tokenTermCount:text forms:forms caseSensitive:caseSensitive];
}

- (BOOL)evalPredicate:(NSString*)predicate args:(NSDictionary*)args {
    
    if ([predicate isEqualToString:@"ls  rs"])
        NSLog(@"CONY");
    NSPredicate* p = [NSPredicate predicateWithFormat:predicate];
    return [p evaluateWithObject:args];
}

- (BOOL)apply:(NSDictionary*)input fields:(NSDictionary*)fields {
    
    if ([_op isEqualToString:@"TRUE"])
        return YES;
    
    if (!input[_field]) {
        return _missing || ([_op isEqualToString:@"="] && !_value);
    } else if ([_op isEqualToString:@"!="] && !_value) {
        return YES;
    }
    
    if ([_op isEqualToString:@"in"]) {
        return [self evalPredicate:[NSString stringWithFormat:@"ls %@ rs", _op]
                              args:@{ @"ls" : input[_field], @"rs" : _value ?: [NSNull null]}];
    }
    if (_term &&
        [input[_field] isKindOfClass:[NSString class]] &&
        [fields[_field] isKindOfClass:[NSString class]]) {
        
        NSArray* termForms = [NSArray new];
        if ([fields[@"summary"] isKindOfClass:[NSDictionary class]] &&
            [fields[@"summary"][@"term_forms"] isKindOfClass:[NSDictionary class]] &&
            [fields[@"summary"][@"term_forms"][_term] isKindOfClass:[NSArray class]]) {
            
            termForms = fields[@"summary"][@"term_forms"][_term];
        }
        NSArray* terms = [@[_term] arrayByAddingObjectsFromArray:termForms];
        NSDictionary* options = fields[_field][@"term_analysis"];
        
        return [self evalPredicate:[NSString stringWithFormat:@"ls %@ rs", _op]
                              args:@{@"ls" : @([self termCount:input[_field] forms:terms options:options]),
                                     @"rs" : _value ?: [NSNull null]}];
    }
    if (input[_field]) {
        return [self evalPredicate:[NSString stringWithFormat:@"ls %@ rs", _op]
                              args:@{ @"ls" : input[_field], @"rs" : _value ?: [NSNull null]}];
    }
    NSAssert(NO, @"Predicate apply: Should not be here!");
    return NO;
}

@end

@implementation Predicates {
    
    NSMutableArray* _predicates;
}

- (instancetype)initWithPredicates:(NSArray*)predicates {
    
    if (self = [super init]) {
        
        Predicate* predicate = nil;
        _predicates = [NSMutableArray new];
        for (id p in predicates) {
            if ([p isKindOfClass:[NSString class]] || [p isKindOfClass:[NSNumber class]]) {
                predicate = [[Predicate alloc] initWithOperator:@"TRUE" field:nil value:@YES term:nil];
            } else if ([p isKindOfClass:[NSDictionary class]]) {
                
                if ([p[@"op"] isKindOfClass:[NSString class]] &&
                    [p[@"field"] isKindOfClass:[NSString class]] &&
                    p[@"value"]) {
                    
                    predicate = [[Predicate alloc] initWithOperator:p[@"op"]
                                                              field:p[@"field"]
                                                              value:p[@"value"]
                                                               term:p[@"term"]];
                }
            }
            NSAssert(predicate, @"Could not create predicate %@", p);
            [_predicates addObject:predicate];
        }
    }
    return self;
}

- (NSString*)ruleWithFields:(NSDictionary*)fields label:(NSString*)label {

    NSMutableArray* rules = [@[] mutableCopy];
    for (Predicate* p in _predicates) {
        if ([p.op isEqualToString:@"TRUE"]) {
            [rules addObject:[p ruleWithFields:fields label:label]];
        }
    }
    return [rules componentsJoinedByString:@" and "];
}

- (BOOL)apply:(NSDictionary*)input fields:(NSDictionary*)fields {

    BOOL result = YES;
    for (Predicate* p in _predicates) {
        result = result && [p apply:input fields:fields];
    }
    return result;
}

@end

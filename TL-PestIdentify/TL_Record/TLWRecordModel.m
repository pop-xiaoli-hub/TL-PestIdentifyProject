//
//  TLWRecordModel.m
//  TL-PestIdentify
//
//  Created by Tommy on 2026/3/13.
//

#import "TLWRecordModel.h"
#import <math.h>

@implementation TLWRecordResult

+ (NSArray<TLWRecordResult *> *)resultsFromAgentResponse:(NSString *)agentResponse
                                             fallbackQuery:(NSString *)userQuery {
    NSArray<NSDictionary *> *rawResults = [self tl_resultsArrayFromResponseString:agentResponse];
    NSMutableArray<TLWRecordResult *> *results = [NSMutableArray array];

    NSInteger displayCount = MIN(rawResults.count, 3);
    for (NSInteger idx = 0; idx < displayCount; idx++) {
        NSDictionary *item = rawResults[idx];
        if (![item isKindOfClass:[NSDictionary class]]) {
            continue;
        }

        TLWRecordResult *result = [[TLWRecordResult alloc] init];
        result.title = [self tl_titleFromValue:item[@"title"] index:idx];
        result.pestName = [self tl_nameFromDictionary:item fallback:userQuery];
        result.reason = [self tl_stringFromValue:item[@"reason"]];
        result.solution = [self tl_solutionFromDictionary:item fallbackReason:result.reason];
        result.hasConfidence = [self tl_fillConfidenceForResult:result fromValue:item[@"confidence"]];
        [results addObject:result];
    }

    if (results.count == 0) {
        TLWRecordResult *fallback = [[TLWRecordResult alloc] init];
        fallback.title = @"结果一";
        fallback.pestName = [self tl_fallbackPestNameFromResponse:agentResponse userQuery:userQuery];
        fallback.reason = @"";
        fallback.solution = [self tl_fallbackSolutionFromResponse:agentResponse];
        fallback.hasConfidence = NO;
        [results addObject:fallback];
    }

    return results.copy;
}

- (NSString *)displayConfidenceText {
    if (!self.hasConfidence) {
        return @"--";
    }
    return [NSString stringWithFormat:@"%.0f%%", self.confidence * 100.0f];
}

+ (NSArray<NSDictionary *> *)tl_resultsArrayFromResponseString:(NSString *)responseString {
    id jsonObject = [self tl_JSONObjectFromPossibleJSONString:responseString];
    return [self tl_resultsArrayFromJSONObject:jsonObject];
}

+ (id)tl_JSONObjectFromPossibleJSONString:(NSString *)responseString {
    if (![responseString isKindOfClass:[NSString class]]) {
        return nil;
    }

    NSString *trimmed = [responseString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return nil;
    }

    NSArray<NSString *> *candidates = [self tl_JSONCandidatesFromString:trimmed];
    for (NSString *candidate in candidates) {
        NSData *data = [candidate dataUsingEncoding:NSUTF8StringEncoding];
        if (!data) {
            continue;
        }

        NSError *error = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        if (error || !jsonObject) {
            continue;
        }

        if ([jsonObject isKindOfClass:[NSString class]] && ![(NSString *)jsonObject isEqualToString:candidate]) {
            id nestedObject = [self tl_JSONObjectFromPossibleJSONString:(NSString *)jsonObject];
            if (nestedObject) {
                return nestedObject;
            }
        }
        return jsonObject;
    }

    return nil;
}

+ (NSArray<NSString *> *)tl_JSONCandidatesFromString:(NSString *)string {
    NSMutableArray<NSString *> *candidates = [NSMutableArray array];
    if (string.length == 0) {
        return candidates.copy;
    }

    [candidates addObject:string];

    NSRange firstBraceRange = [string rangeOfString:@"{"];
    NSRange lastBraceRange = [string rangeOfString:@"}" options:NSBackwardsSearch];
    if (firstBraceRange.location != NSNotFound &&
        lastBraceRange.location != NSNotFound &&
        lastBraceRange.location > firstBraceRange.location) {
        NSString *braceCandidate = [string substringWithRange:NSMakeRange(firstBraceRange.location,
                                                                          lastBraceRange.location - firstBraceRange.location + 1)];
        if (![braceCandidate isEqualToString:string]) {
            [candidates addObject:braceCandidate];
        }
    }

    NSRange firstBracketRange = [string rangeOfString:@"["];
    NSRange lastBracketRange = [string rangeOfString:@"]" options:NSBackwardsSearch];
    if (firstBracketRange.location != NSNotFound &&
        lastBracketRange.location != NSNotFound &&
        lastBracketRange.location > firstBracketRange.location) {
        NSString *bracketCandidate = [string substringWithRange:NSMakeRange(firstBracketRange.location,
                                                                            lastBracketRange.location - firstBracketRange.location + 1)];
        if (![candidates containsObject:bracketCandidate]) {
            [candidates addObject:bracketCandidate];
        }
    }

    return candidates.copy;
}

+ (NSArray<NSDictionary *> *)tl_resultsArrayFromJSONObject:(id)jsonObject {
    if (!jsonObject) {
        return @[];
    }

    if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSMutableArray<NSDictionary *> *results = [NSMutableArray array];
        for (id item in (NSArray *)jsonObject) {
            if ([item isKindOfClass:[NSDictionary class]] && [self tl_isResultDictionary:item]) {
                [results addObject:item];
            }
        }
        return results.copy;
    }

    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        return @[];
    }

    NSDictionary *dictionary = (NSDictionary *)jsonObject;
    id resultsObject = dictionary[@"results"];
    if ([resultsObject isKindOfClass:[NSArray class]]) {
        return [self tl_resultsArrayFromJSONObject:resultsObject];
    }

    if ([resultsObject isKindOfClass:[NSString class]]) {
        NSArray<NSDictionary *> *nestedResults = [self tl_resultsArrayFromResponseString:(NSString *)resultsObject];
        if (nestedResults.count > 0) {
            return nestedResults;
        }
    }

    if ([self tl_isResultDictionary:dictionary]) {
        return @[dictionary];
    }

    NSArray<NSString *> *nestedKeys = @[@"data", @"result", @"response", @"content", @"message"];
    for (NSString *key in nestedKeys) {
        id value = dictionary[key];
        NSArray<NSDictionary *> *nestedResults = [self tl_resultsArrayFromJSONObject:value];
        if (nestedResults.count > 0) {
            return nestedResults;
        }
        if ([value isKindOfClass:[NSString class]]) {
            nestedResults = [self tl_resultsArrayFromResponseString:(NSString *)value];
            if (nestedResults.count > 0) {
                return nestedResults;
            }
        }
    }

    return @[];
}

+ (BOOL)tl_isResultDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    return dictionary[@"name"] != nil ||
           dictionary[@"names"] != nil ||
           dictionary[@"confidence"] != nil ||
           dictionary[@"advice"] != nil ||
           dictionary[@"solution"] != nil ||
           dictionary[@"reason"] != nil;
}

+ (NSString *)tl_titleFromValue:(id)value index:(NSInteger)index {
    NSString *title = [self tl_stringFromValue:value];
    if (title.length > 0) {
        return title;
    }

    NSArray<NSString *> *titles = @[@"结果一", @"结果二", @"结果三"];
    if (index >= 0 && index < titles.count) {
        return titles[index];
    }
    return [NSString stringWithFormat:@"结果%ld", (long)index + 1];
}

+ (NSString *)tl_nameFromDictionary:(NSDictionary *)dictionary fallback:(NSString *)fallback {
    NSString *name = [self tl_stringFromValue:dictionary[@"name"]];
    if (name.length > 0) {
        return name;
    }

    id namesObject = dictionary[@"names"];
    if ([namesObject isKindOfClass:[NSArray class]]) {
        for (id item in (NSArray *)namesObject) {
            NSString *candidate = [self tl_stringFromValue:item];
            if (candidate.length > 0) {
                return candidate;
            }
        }
    }

    NSString *fallbackName = [self tl_stringFromValue:fallback];
    return fallbackName.length > 0 ? fallbackName : @"待确认";
}

+ (NSString *)tl_solutionFromDictionary:(NSDictionary *)dictionary fallbackReason:(NSString *)reason {
    NSString *solution = [self tl_stringFromValue:dictionary[@"advice"]];
    if (solution.length == 0) {
        solution = [self tl_stringFromValue:dictionary[@"solution"]];
    }
    if (solution.length == 0) {
        solution = reason;
    }
    if (solution.length == 0) {
        solution = @"建议补拍叶片近景、病斑局部、叶背或虫体细节后再次识别。";
    }
    return solution;
}

+ (BOOL)tl_fillConfidenceForResult:(TLWRecordResult *)result fromValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [self tl_applyConfidenceValue:[(NSNumber *)value floatValue] hasPercentHint:NO toResult:result];
    }

    NSString *text = [self tl_stringFromValue:value];
    if (text.length == 0) {
        return NO;
    }

    BOOL hasPercentSign = [text containsString:@"%"];
    NSString *normalized = [[text stringByReplacingOccurrencesOfString:@"％" withString:@"%"]
                                 stringByReplacingOccurrencesOfString:@"%" withString:@""];
    NSScanner *scanner = [NSScanner scannerWithString:normalized];
    float numericValue = 0.0f;
    if (![scanner scanFloat:&numericValue]) {
        return NO;
    }

    return [self tl_applyConfidenceValue:numericValue hasPercentHint:hasPercentSign toResult:result];
}

+ (BOOL)tl_applyConfidenceValue:(float)value hasPercentHint:(BOOL)hasPercentHint toResult:(TLWRecordResult *)result {
    if (!result || isnan(value) || isinf(value) || value < 0.0f) {
        return NO;
    }

    float normalizedValue = value;
    if (hasPercentHint || value > 1.0f) {
        normalizedValue = value / 100.0f;
    }
    normalizedValue = MAX(0.0f, MIN(normalizedValue, 1.0f));
    result.confidence = normalizedValue;
    return YES;
}

+ (NSString *)tl_fallbackPestNameFromResponse:(NSString *)response userQuery:(NSString *)userQuery {
    NSString *trimmedResponse = [self tl_stringFromValue:response];
    if (trimmedResponse.length > 0) {
        NSString *firstLine = [[trimmedResponse componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] firstObject];
        firstLine = [self tl_stringFromValue:firstLine];
        if (firstLine.length > 0 &&
            ![firstLine containsString:@"{\""] &&
            ![firstLine containsString:@"\"results\""] &&
            ![firstLine hasPrefix:@"{"]) {
            return firstLine;
        }
    }

    NSString *fallbackName = [self tl_stringFromValue:userQuery];
    return fallbackName.length > 0 ? fallbackName : @"待确认";
}

+ (NSString *)tl_fallbackSolutionFromResponse:(NSString *)response {
    NSString *text = [self tl_stringFromValue:response];
    if (text.length == 0 || [text hasPrefix:@"{"] || [text containsString:@"\"results\""]) {
        return @"建议补拍叶片近景、病斑局部、叶背或虫体细节后再次识别。";
    }
    return text;
}

+ (NSString *)tl_stringFromValue:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        return [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [[(NSNumber *)value stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return @"";
}
@end

@implementation TLWRecordItem

- (NSString *)topPestName {
    NSString *topName = self.results.firstObject.pestName;
    return topName.length > 0 ? topName : @"待确认";
}

@end

@implementation TLWRecordSection
@end

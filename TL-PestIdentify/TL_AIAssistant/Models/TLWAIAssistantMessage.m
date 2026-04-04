//
//  TLWAIAssistantMessage.m
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：定义AI助手数据模型。
//
#import "TLWAIAssistantMessage.h"

@implementation TLWAIAssistantMessage

+ (instancetype)messageWithRole:(TLWAIAssistantMessageRole)role
                           text:(NSString *)text {
    return [self messageWithRole:role text:text localImages:nil remoteImageURLs:nil];
}

+ (instancetype)messageWithRole:(TLWAIAssistantMessageRole)role
                           text:(NSString *)text
                    localImages:(NSArray<UIImage *> *)localImages
                remoteImageURLs:(NSArray<NSString *> *)remoteImageURLs {
    TLWAIAssistantMessage *message = [[self alloc] init];
    message.role = role;
    message.status = TLWAIAssistantMessageStatusIdle;
    message.text = text ?: @"";
    message.localImages = localImages ?: @[];
    message.remoteImageURLs = remoteImageURLs ?: @[];
    message.createdAt = [NSDate date];
    return message;
}

@end

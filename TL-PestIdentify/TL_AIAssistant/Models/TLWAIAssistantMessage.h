//
//  TLWAIAssistantMessage.h
//  TL-PestIdentify
//
//  Created by Northern Lights on 2026/4/3.
//  职责：定义AI助手数据模型。
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TLWAIAssistantMessageRole) {
    TLWAIAssistantMessageRoleUser = 0,
    TLWAIAssistantMessageRoleAssistant,
    TLWAIAssistantMessageRoleSystem,
};

typedef NS_ENUM(NSInteger, TLWAIAssistantMessageStatus) {
    TLWAIAssistantMessageStatusIdle = 0,
    TLWAIAssistantMessageStatusSending,
    TLWAIAssistantMessageStatusFailed,
};

@interface TLWAIAssistantMessage : NSObject

@property (nonatomic, assign) TLWAIAssistantMessageRole role;
@property (nonatomic, assign) TLWAIAssistantMessageStatus status;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSArray<UIImage *> *localImages;
@property (nonatomic, copy) NSArray<NSString *> *remoteImageURLs;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, copy, nullable) NSString *errorMessage;

+ (instancetype)messageWithRole:(TLWAIAssistantMessageRole)role
                           text:(nullable NSString *)text;

+ (instancetype)messageWithRole:(TLWAIAssistantMessageRole)role
                           text:(nullable NSString *)text
                    localImages:(nullable NSArray<UIImage *> *)localImages
                remoteImageURLs:(nullable NSArray<NSString *> *)remoteImageURLs;

@end

NS_ASSUME_NONNULL_END

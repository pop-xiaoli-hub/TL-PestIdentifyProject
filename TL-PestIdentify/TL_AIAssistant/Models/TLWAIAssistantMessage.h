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
/// 高清原图，仅用于点击放大全屏预览；localImages 存的是 120px 缩略图给气泡渲染。
@property (nonatomic, copy, nullable) NSArray<UIImage *> *previewImages;
@property (nonatomic, copy) NSArray<NSString *> *remoteImageURLs;
/// 第一张图片的原始尺寸，用于 cell 按比例显示。CGSizeZero 表示未知，fallback 正方形。
@property (nonatomic, assign) CGSize imageDisplaySize;
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

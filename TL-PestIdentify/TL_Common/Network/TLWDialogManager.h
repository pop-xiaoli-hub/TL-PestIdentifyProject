//
//  TLWDialogManager.h
//  TL-PestIdentify
//
//  火山引擎 Dialog 语音对话 SDK 管理器

#import <Foundation/Foundation.h>
#import <SpeechEngineToB/SpeechEngine.h>

NS_ASSUME_NONNULL_BEGIN

@interface TLWDialogManager : NSObject

+ (instancetype)shared;

/// 语音引擎实例
@property (nonatomic, strong, readonly) SpeechEngine *engine;

/// 创建并配置引擎（传入 delegate 接收回调）
- (void)setupEngineWithDelegate:(id<SpeechEngineDelegate>)delegate;

/// 初始化引擎（配置完参数后调用）
- (SEEngineErrorCode)startEngine;

/// 停止引擎
- (void)stopEngine;

/// 销毁引擎
- (void)destroyEngine;

@end

NS_ASSUME_NONNULL_END

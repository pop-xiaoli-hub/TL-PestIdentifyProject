//
//  TWLSpeechManager.h
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/16.
//

#import <Speech/Speech.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TWLSpeechManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, copy, nullable) void (^resultHandler)(NSString *text, BOOL isFinal);
/// 权限被拒或识别出错时回调，message 可直接用于 Toast 展示
@property (nonatomic, copy, nullable) void (^errorHandler)(NSString *errorMessage);
/// 当前是否正在录音（可用于外部判断状态）
@property (nonatomic, assign, readonly) BOOL isRecording;

- (void)startRecording;
- (void)stopRecording;

@end

NS_ASSUME_NONNULL_END

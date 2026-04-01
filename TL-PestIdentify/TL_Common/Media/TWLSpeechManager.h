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
@property (nonatomic, copy) void (^resultHandler)(NSString *text, BOOL isFinal);

- (void)startRecording;
- (void)stopRecording;

@end

NS_ASSUME_NONNULL_END

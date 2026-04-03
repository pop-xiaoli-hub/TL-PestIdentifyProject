//
//  TWLSpeechManager.m
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/16.
//

#import "TWLSpeechManager.h"


@interface TWLSpeechManager ()
@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *request;
@property (nonatomic, strong) SFSpeechRecognitionTask *task;
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, assign, readwrite) BOOL isRecording;
@end

@implementation TWLSpeechManager

+ (instancetype)sharedManager {
    static TWLSpeechManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TWLSpeechManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh-CN"];
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return self;
}

- (void)startRecording {
    self.isRecording = YES;

    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (!granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.isRecording = NO;
                [self tl_reportError:@"麦克风权限未开启，请在系统设置中允许访问麦克风"];
            });
            return;
        }
        [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status != SFSpeechRecognizerAuthorizationStatusAuthorized) {
                    self.isRecording = NO;
                    [self tl_reportError:@"语音识别权限未开启，请在系统设置中允许语音识别"];
                    return;
                }
                // 权限通过后检查：如果用户已松手（stopRecording 被调用），不再启动
                if (!self.isRecording) return;
                [self startAudio];
            });
        }];
    }];
}

- (void)startAudio {
    if (self.audioEngine.isRunning) return;

    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryRecord error:&sessionError];
    [session setMode:AVAudioSessionModeMeasurement error:nil];
    [session setActive:YES
           withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                 error:&sessionError];

    if (sessionError) {
        NSLog(@"AVAudioSession error: %@", sessionError);
        self.isRecording = NO;
        [self tl_reportError:@"音频会话启动失败，请重试"];
        return;
    }

    self.request = [[SFSpeechAudioBufferRecognitionRequest alloc] init];

    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    AVAudioFormat *format = [inputNode outputFormatForBus:0];

    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0
                    bufferSize:1024
                        format:format
                         block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        [self.request appendAudioPCMBuffer:buffer];
    }];

    [self.audioEngine prepare];

    NSError *error;
    [self.audioEngine startAndReturnError:&error];
    if (error) {
        NSLog(@"audio start error: %@", error);
        self.isRecording = NO;
        [self tl_reportError:@"录音启动失败，请重试"];
        return;
    }

    __weak typeof(self) weakSelf = self;
    self.task = [self.speechRecognizer recognitionTaskWithRequest:self.request
                                                   resultHandler:^(SFSpeechRecognitionResult *result,
                                                                   NSError *error) {
        if (result) {
            NSString *text = result.bestTranscription.formattedString;
            if (weakSelf.resultHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.resultHandler(text, result.isFinal);
                });
            }
        }

        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // 用户主动停止导致的 cancel 错误不提示
                if (error.code != 216 && error.code != 209) {
                    [weakSelf tl_reportError:[NSString stringWithFormat:@"语音识别出错: %@", error.localizedDescription]];
                }
                [weakSelf stopRecording];
            });
        } else if (result.isFinal) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf stopRecording];
            });
        }
    }];
}

#pragma mark - 停止录音

- (void)stopRecording {
    self.isRecording = NO;

    if (self.audioEngine.isRunning) {
        [self.audioEngine stop];
        [self.request endAudio];
        [[AVAudioSession sharedInstance] setActive:NO
                                       withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                             error:nil];
    }

    [self.task cancel];
    self.task = nil;
}

#pragma mark - Private

- (void)tl_reportError:(NSString *)message {
    if (self.errorHandler) {
        self.errorHandler(message);
    }
}

@end

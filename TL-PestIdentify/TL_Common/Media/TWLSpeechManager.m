//
//  TWLSpeechManager.m
//  TL-PestIdentify
//
//  Created by 吴桐 on 2026/3/16.
//

#import "TWLSpeechManager.h"


@interface TWLSpeechManager ()
@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;// 语音识别引擎
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *request;// 把音频数据发送给识别引擎
// 流程是麦克风->PCM音频buffer->request->识别引擎
@property (nonatomic, strong) SFSpeechRecognitionTask *task;    //管理一次性识别任务，任务负责实时返回识别结果
@property (nonatomic, strong) AVAudioEngine *audioEngine;   //采集麦克风音频
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

- (instancetype) init {
    self = [super init];
    if (self) {
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh-CN"];

        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return self;
}

- (void) startRecording {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (!granted) return;
        [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
            if (status != SFSpeechRecognizerAuthorizationStatusAuthorized) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self startAudio];
            });
        }];
    }];
}


- (void)startAudio {
    // 防重入
    if (self.audioEngine.isRunning) return;

    // 配置 AVAudioSession
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryRecord error:&sessionError];
    [session setMode:AVAudioSessionModeMeasurement error:nil];
    [session setActive:YES
           withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                 error:&sessionError];

    if (sessionError) {
        NSLog(@"AVAudioSession error: %@", sessionError);
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

        if (error || result.isFinal) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf stopRecording];
            });
        }
    }];
}

#pragma mark - 停止录音

- (void)stopRecording {
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
@end

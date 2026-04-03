//
//  TLWDialogManager.m
//  TL-PestIdentify
//
//  火山引擎 Dialog 语音对话 SDK 管理器

#import "TLWDialogManager.h"

// ── 凭证信息从 Info.plist 读取 ──
// 在 Info.plist 中添加以下 key：
//   VolcEngineAppId       -> String
//   VolcEngineAccessToken -> String
//   VolcEngineAppKey      -> String
static NSString * _Nullable TLWDialogPlistValue(NSString *key) {
    NSString *value = [[NSBundle mainBundle] objectForInfoDictionaryKey:key];
    NSCAssert(value.length > 0, @"[TLWDialogManager] Info.plist 缺少必需配置项: %@", key);
    return value;
}

// ── 服务配置 ──
static NSString * const kResourceId    = @"volc.speech.dialog";
static NSString * const kDialogAddress = @"wss://openspeech.bytedance.com";
static NSString * const kDialogUri     = @"/api/v3/realtime/dialogue";

@interface TLWDialogManager ()
@property (nonatomic, strong, readwrite) SpeechEngine *engine;
@end

@implementation TLWDialogManager

+ (instancetype)shared {
    static TLWDialogManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TLWDialogManager alloc] init];
    });
    return instance;
}

- (void)setupEngineWithDelegate:(id<SpeechEngineDelegate>)delegate {
    if (_engine) {
        [_engine destroyEngine];
        _engine = nil;
    }

    _engine = [[SpeechEngine alloc] init];
    [_engine createEngineWithDelegate:delegate];

    // ── 必需参数 ──
    [_engine setStringParam:SE_DIALOG_ENGINE forKey:SE_PARAMS_KEY_ENGINE_NAME_STRING];
    [_engine setStringParam:TLWDialogPlistValue(@"VolcEngineAppId")       forKey:SE_PARAMS_KEY_APP_ID_STRING];
    [_engine setStringParam:TLWDialogPlistValue(@"VolcEngineAppKey")      forKey:SE_PARAMS_KEY_APP_KEY_STRING];
    [_engine setStringParam:TLWDialogPlistValue(@"VolcEngineAccessToken") forKey:SE_PARAMS_KEY_APP_TOKEN_STRING];
    [_engine setStringParam:kResourceId      forKey:SE_PARAMS_KEY_RESOURCE_ID_STRING];
    [_engine setStringParam:kDialogAddress   forKey:SE_PARAMS_KEY_DIALOG_ADDRESS_STRING];
    [_engine setStringParam:kDialogUri       forKey:SE_PARAMS_KEY_DIALOG_URI_STRING];

    // UID 使用当前设备标识
    NSString *uid = [[[UIDevice currentDevice] identifierForVendor] UUIDString] ?: @"default_uid";
    [_engine setStringParam:uid forKey:SE_PARAMS_KEY_UID_STRING];

    // ── 录音机配置（使用设备麦克风）──
    [_engine setStringParam:SE_RECORDER_TYPE_RECORDER forKey:SE_PARAMS_KEY_RECORDER_TYPE_STRING];

    // ── 播放器配置（启用内置播放器）──
    [_engine setBoolParam:YES forKey:SE_PARAMS_KEY_DIALOG_ENABLE_PLAYER_BOOL];

    // 同时启用录音和播放时，按火山文档开启 SDK AEC，并尽量从 Bundle 自动寻找 aec.model。
    [_engine setBoolParam:YES forKey:SE_PARAMS_KEY_ENABLE_AEC_BOOL];
    NSString *aecModelPath = [self tl_aecModelPath];
    if (aecModelPath.length > 0) {
        [_engine setStringParam:aecModelPath forKey:SE_PARAMS_KEY_AEC_MODEL_PATH_STRING];
    } else {
        NSLog(@"⚠️ [TLWDialogManager] 未在 App Bundle 中找到 aec.model，AEC 功能将不可用。请把 aec.model 加入工程资源。");
        // aec.model 缺失时关闭 AEC，避免引擎行为异常
        [_engine setBoolParam:NO forKey:SE_PARAMS_KEY_ENABLE_AEC_BOOL];
    }

    // ── 日志级别 ──
    [_engine setStringParam:SE_LOG_LEVEL_DEBUG forKey:SE_PARAMS_KEY_LOG_LEVEL_STRING];
}

- (SEEngineErrorCode)startEngine {
    if (!_engine) return -1;
    SEEngineErrorCode ret = [_engine initEngine];
    if (ret != SENoError) {
        NSLog(@"[TLWDialogManager] initEngine 失败，错误码: %d", (int)ret);
        return ret;
    }
    [_engine sendDirective:SEDirectiveSyncStopEngine];
    ret = [_engine sendDirective:SEDirectiveStartEngine
                            data:@"{\"dialog\":{\"bot_name\":\"植小保\"}}"];
    if (ret != SENoError) {
        NSLog(@"[TLWDialogManager] startEngine 失败，错误码: %d", (int)ret);
    }
    return ret;
}

- (void)stopEngine {
    if (_engine) {
        [_engine sendDirective:SEDirectiveSyncStopEngine];
    }
}

- (void)destroyEngine {
    if (_engine) {
        [_engine destroyEngine];
        _engine = nil;
    }
}

- (NSString *)tl_aecModelPath {
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"aec" ofType:@"model"];
    if (modelPath.length > 0) {
        return modelPath;
    }

    NSArray<NSURL *> *candidateURLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"model" subdirectory:nil];
    for (NSURL *url in candidateURLs) {
        if ([url.lastPathComponent isEqualToString:@"aec.model"]) {
            return url.path;
        }
    }

    return nil;
}

@end

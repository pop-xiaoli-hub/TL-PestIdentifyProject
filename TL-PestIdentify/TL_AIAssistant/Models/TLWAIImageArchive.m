#import "TLWAIImageArchive.h"

@implementation TLWAIImageArchive

static NSInteger TLWAIActiveUserIdentifier = 0;
static NSString *TLWAIActiveRoot = nil;

+ (void)activateUserIdentifier:(NSInteger)userIdentifier root:(NSString *)root {
    TLWAIActiveUserIdentifier = userIdentifier;
    TLWAIActiveRoot = [root copy];
}
+ (UIImage *)activeImageForRelativePath:(NSString *)relativePath {
    return [self imageForRelativePath:relativePath userIdentifier:TLWAIActiveUserIdentifier root:TLWAIActiveRoot];
}
+ (NSString *)directoryForUserIdentifier:(NSInteger)userIdentifier root:(NSString *)root {
    NSString *base = root;
    if (!base.length) {
        base = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
        base = [base stringByAppendingPathComponent:@"TLWAIAssistant"];
    }
    return [base stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)userIdentifier]];
}

+ (NSString *)absolutePathForRelativePath:(NSString *)relativePath userIdentifier:(NSInteger)userIdentifier root:(NSString *)root {
    if (!relativePath.length) return @"";
    return [[self directoryForUserIdentifier:userIdentifier root:root] stringByAppendingPathComponent:relativePath];
}

+ (BOOL)fileExistsForRelativePath:(NSString *)relativePath userIdentifier:(NSInteger)userIdentifier root:(NSString *)root {
    NSString *path = [self absolutePathForRelativePath:relativePath userIdentifier:userIdentifier root:root];
    return path.length && [NSFileManager.defaultManager fileExistsAtPath:path];
}

+ (UIImage *)imageForRelativePath:(NSString *)relativePath userIdentifier:(NSInteger)userIdentifier root:(NSString *)root {
    NSString *path = [self absolutePathForRelativePath:relativePath userIdentifier:userIdentifier root:root];
    return path.length ? [UIImage imageWithContentsOfFile:path] : nil;
}

+ (NSString *)writeImage:(UIImage *)image userIdentifier:(NSInteger)userIdentifier root:(NSString *)root messageIdentifier:(NSString *)messageIdentifier index:(NSUInteger)index {
    if (!image || !messageIdentifier.length) return nil;
    NSData *data = UIImageJPEGRepresentation(image, 0.82);
    if (!data.length) return nil;
    NSString *directory = [self directoryForUserIdentifier:userIdentifier root:root];
    NSError *error = nil;
    if (![NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error]) return nil;
    NSString *relative = [NSString stringWithFormat:@"%@-%lu.jpg", messageIdentifier, (unsigned long)index];
    NSString *path = [directory stringByAppendingPathComponent:relative];
    return [data writeToFile:path options:NSDataWritingAtomic error:&error] ? relative : nil;
}

@end

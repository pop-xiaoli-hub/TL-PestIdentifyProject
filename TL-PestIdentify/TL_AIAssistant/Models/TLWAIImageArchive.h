#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/// 助手图片只写沙盒文件并返回相对路径。没有删除接口；内存裁剪不得删文件。
@interface TLWAIImageArchive : NSObject
+ (void)activateUserIdentifier:(NSInteger)userIdentifier root:(nullable NSString *)root;
+ (nullable UIImage *)activeImageForRelativePath:(NSString *)relativePath;
+ (NSString *)directoryForUserIdentifier:(NSInteger)userIdentifier root:(nullable NSString *)root;
+ (nullable NSString *)writeImage:(UIImage *)image
                   userIdentifier:(NSInteger)userIdentifier
                             root:(nullable NSString *)root
                messageIdentifier:(NSString *)messageIdentifier
                            index:(NSUInteger)index;
+ (NSString *)absolutePathForRelativePath:(NSString *)relativePath userIdentifier:(NSInteger)userIdentifier root:(nullable NSString *)root;
+ (BOOL)fileExistsForRelativePath:(NSString *)relativePath userIdentifier:(NSInteger)userIdentifier root:(nullable NSString *)root;
+ (nullable UIImage *)imageForRelativePath:(NSString *)relativePath userIdentifier:(NSInteger)userIdentifier root:(nullable NSString *)root;
@end
NS_ASSUME_NONNULL_END

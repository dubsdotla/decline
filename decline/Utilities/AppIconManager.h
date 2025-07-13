//  AppIconManager.h

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppIconManager : NSObject

/// Change only the Dock/⌘+Tab icon (no privileges needed)
+ (void)updateDockIconToImageNamed:(NSString *)imageName;
+ (void)updateDockIconToMatchCurrentAppearance;

@end

NS_ASSUME_NONNULL_END

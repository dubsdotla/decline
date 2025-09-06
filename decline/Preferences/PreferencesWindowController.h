// PreferencesWindowController.h
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PreferencesWindowController : NSWindowController <NSToolbarDelegate>
+ (instancetype)sharedController;
- (void)showGeneralPane;        // convenience if you want to jump directly
@end

NS_ASSUME_NONNULL_END

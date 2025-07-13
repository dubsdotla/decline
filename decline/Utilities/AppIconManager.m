//  AppIconManager.m

#import "AppIconManager.h"
#import <Security/Security.h>
#import <unistd.h>    // for sleep()
#import <Foundation/Foundation.h>

@implementation AppIconManager

#pragma mark – Dock Icon (no privileges)

+ (void)updateDockIconToImageNamed:(NSString *)imageName {
    NSImage *newDockIcon = [NSImage imageNamed:imageName];
    if (newDockIcon) {
        [NSApp setApplicationIconImage:newDockIcon];
    } else {
        NSLog(@"[AppIconManager] ERROR: Unable to find image named '%@' for Dock icon.", imageName);
    }
}

+ (void)updateDockIconToMatchCurrentAppearance {
    NSAppearance *appearance = NSApp.effectiveAppearance;
            BOOL isDark = [appearance.name isEqualToString:NSAppearanceNameDarkAqua] ||
                          [appearance.name isEqualToString:NSAppearanceNameVibrantDark];
            
    NSString *iconName = isDark ? @"AppIconDark" : @"AppIconLight";
        
    [AppIconManager updateDockIconToImageNamed:iconName];
}

@end

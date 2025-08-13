//
//  CustomNotificationManager.m
//  decline
//
//  Created by Derek Scott on 8/3/25.
//

#import "CustomNotificationManager.h"

@implementation CustomNotificationManager

static const CGFloat kVerticalSpacing = 4.0;

+ (instancetype)sharedManager {
    static CustomNotificationManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        sharedManager.activeNotifications = [NSMutableArray array];
        sharedManager.stackIndices  = [NSMutableDictionary dictionary];
    });
    return sharedManager;
}

-  (void)showNotificationWithMessage:(NSString *)message
                          textSize:(NotificationTextSize)textSize
                          position:(NotificationPosition)position
                            sticky:(BOOL)sticky
{
    CustomNotification *note = [CustomNotification new];
    
    note.window.delegate = note;
    
    // Measure needed size
      CGSize winSize = [CustomNotification sizeForMessage:message textSize:textSize];
      CGFloat notifH = winSize.height;

      // Compute anchorY and offsetY just once
      NSRect screen = NSScreen.mainScreen.visibleFrame;
      BOOL isBottom = (position == NotificationPositionBottomLeft ||
                       position == NotificationPositionBottomCenter ||
                       position == NotificationPositionBottomRight);

    CGFloat anchorY;
    if (isBottom) {
        anchorY = screen.origin.y + 20.0;
    } else if (position == NotificationPositionCenter) {
        anchorY = (screen.size.height - notifH) / 2.0;
    } else { // LeftCenter or RightCenter
        anchorY = (screen.size.height - notifH) / 2.0;
    }
    
    // Compute stack index for this position
    NSNumber *key   = @(position);
    NSUInteger idx  = [self.stackIndices[key] unsignedIntegerValue];
    
    CGFloat offsetY;
    if (isBottom) {
        // stack upward
        // find highest top edge among same‐position stickies
        CGFloat highestTop = anchorY;
        for (CustomNotification *ex in self.activeNotifications) {
            if (ex.position == position) {
                NSRect f = ex.window.frame;
                highestTop = MAX(highestTop, f.origin.y + f.size.height);
            }
        }
        offsetY = (highestTop - anchorY) + kVerticalSpacing;
    } else {
        // stack downward
        offsetY = - (idx * (notifH + kVerticalSpacing));
        CGFloat candidateY = anchorY + offsetY;
        // if this would go below bottom+20, wrap
        if (candidateY < screen.origin.y + 20.0) {
            idx     = 0;
            offsetY = 0;
        }
    }
        
    // Show notification at computed offset
    [note showNotificationWithMessage:message
                            textSize:textSize
                           position:position
                            offsetY:offsetY
                             sticky:sticky];
    
    [self.activeNotifications addObject:note];
    
    if (!isBottom) {
        // for center positions, increment idx only after placing
        idx++;
        self.stackIndices[key] = @(idx);
    }
}

-  (void)notificationDidClose:(CustomNotification *)notification {
    [self.activeNotifications removeObject:notification];
}

@end

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

- (NSString *)textSizeStringFromEnum:(NSUInteger)integer {
    if(integer == NotificationTextSizeSmall) {
        return @"Small";
    }
    
    else if(integer == NotificationTextSizeMedium) {
        return @"Medium";
    }
    
    else {
        return @"Large";
    }
}

- (NSUInteger)textSizeEnumFromString:(NSString *)string {
    if([string isEqualToString:@"Small"]) {
        return NotificationTextSizeSmall;
    }
    
    else if([string isEqualToString:@"Medium"]) {
        return NotificationTextSizeMedium;
    }
    
    else {
        return NotificationTextSizeLarge;
    }
}

- (NSString *)positionStringFromEnum:(NSUInteger)integer {
    if(integer == NotificationPositionTopLeft) {
        return @"Top Left";
    }
    
    else if(integer == NotificationPositionTopCenter) {
        return @"Top Center";
    }
    
    else if(integer == NotificationPositionTopRight) {
        return @"Top Right";
    }
    
    else if(integer == NotificationPositionLeftCenter) {
        return @"Left Center";
    }
    
    else if(integer == NotificationPositionCenter) {
        return @"Center";
    }
    
    else if(integer == NotificationPositionRightCenter) {
        return @"Right Center";
    }
    
    else if(integer == NotificationPositionBottomLeft) {
        return @"Bottom Left";
    }
    
    else if(integer == NotificationPositionBottomCenter) {
        return @"Bottom Center";
    }
    
    else {
        return @"Bottom Right";
    }
}

- (NSUInteger)positionEnumFromString:(NSString *)string {
    if([string isEqualToString:@"Top Left"]) {
        return NotificationPositionTopLeft;
    }
    
    else if([string isEqualToString:@"Top Center"]) {
        return NotificationPositionTopCenter;
    }
    
    else if([string isEqualToString:@"Top Right"]) {
        return NotificationPositionTopRight;
    }
    
    else if([string isEqualToString:@"Left Center"]) {
        return NotificationPositionLeftCenter;
    }
    
    else if([string isEqualToString:@"Center"]) {
        return NotificationPositionCenter;
    }
    
    else if([string isEqualToString:@"Right Center"]) {
        return NotificationPositionRightCenter;
    }
    
    else if([string isEqualToString:@"Bottom Left"]) {
        return NotificationPositionBottomLeft;
    }
    
    else if([string isEqualToString:@"Bottom Center"]) {
        return NotificationPositionBottomCenter;
    }
    
    else {
        return NotificationPositionBottomRight;
    }
}

-  (void)notificationDidClose:(CustomNotification *)notification {
    [self.activeNotifications removeObject:notification];
}

@end

//
//  CustomNotification.h
//  decline
//
//  Created by Derek Scott on 7/31/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NotificationTextSize) {
    NotificationTextSizeSmall,
    NotificationTextSizeMedium,
    NotificationTextSizeLarge,
};

typedef NS_ENUM(NSUInteger, NotificationPosition) {
    NotificationPositionTopLeft,
    NotificationPositionTopCenter,
    NotificationPositionTopRight,
    NotificationPositionLeftCenter,
    NotificationPositionCenter,
    NotificationPositionRightCenter,
    NotificationPositionBottomLeft,
    NotificationPositionBottomCenter,
    NotificationPositionBottomRight,
};

@interface CustomNotification : NSWindowController <NSWindowDelegate>

// Expose these so the manager can track position and offsets
@property (nonatomic, assign) NotificationPosition position;
@property (nonatomic, assign) CGFloat offsetX;
@property (nonatomic, assign) CGFloat offsetY;

/// Returns the frame size (width, height) needed to display `message` at `textSize`
+ (CGSize)sizeForMessage:(NSString*)message textSize:(NotificationTextSize)textSize;

-  (void)showNotificationWithMessage:(NSString *)message
                          textSize:(NotificationTextSize)textSize
                         position:(NotificationPosition)position
                          offsetY:(CGFloat)offsetY
                              sticky:(BOOL)sticky;
@end

NS_ASSUME_NONNULL_END

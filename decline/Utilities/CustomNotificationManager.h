//
//  CustomNotificationManager.h
//  decline
//
//  Created by Derek Scott on 8/3/25.
//

#import <Foundation/Foundation.h>
#import "CustomNotification.h"

NS_ASSUME_NONNULL_BEGIN

@interface CustomNotificationManager : NSObject

@property (nonatomic, strong) NSMutableArray<CustomNotification *> *activeNotifications;
// track stack indices per position
@property (nonatomic,strong) NSMutableDictionary<NSNumber*, NSNumber*> *stackIndices;

+ (instancetype)sharedManager;
-  (void)showNotificationWithMessage:(NSString *)message
                          textSize:(NotificationTextSize)textSize
                            position:(NotificationPosition)position
                              sticky:(BOOL)sticky;

-  (void)notificationDidClose:(CustomNotification *)notification;

@end

NS_ASSUME_NONNULL_END

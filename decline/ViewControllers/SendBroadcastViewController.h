//
//  SendBroadcastViewController.h
//  decline
//
//  Created by Derek Scott on 5/21/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SendBroadcastViewController : NSViewController

@property (nonatomic, copy) void (^completionHandler)(NSString *broadcastText);

@end

NS_ASSUME_NONNULL_END

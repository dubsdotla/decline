//
//  ChangeNickIconViewController.h
//  decline
//
//  Created by Derek Scott on 5/21/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChangeNickIconViewController : NSViewController

@property (nonatomic, copy) void (^completionHandler)(NSString *nickname, uint32_t iconNumber);

/// Designated initializer
- (instancetype)initWithNickname:(NSString*)nick
                      iconNumber:(uint32_t)icon;

@end

NS_ASSUME_NONNULL_END

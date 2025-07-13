//
//  ShowAgreementViewController.h
//  decline
//
//  Created by Derek Scott on 5/21/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShowAgreementViewController : NSViewController

@property (nonatomic, copy) void (^completionHandler)(NSString *agreeText);

- (instancetype)initWithAgreement:(NSString*)agreement;

@end

NS_ASSUME_NONNULL_END

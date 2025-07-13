//
//  SendNewsPostViewController.h
//  decline
//
//  Created by Derek Scott on 5/21/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SendNewsPostViewController : NSViewController

@property (nonatomic, copy) void (^completionHandler)(NSString *newsText);

@end

NS_ASSUME_NONNULL_END

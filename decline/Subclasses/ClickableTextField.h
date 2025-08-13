//
//  ClickableTextField.h
//  decline
//
//  Created by Derek Scott on 8/1/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// Subclass NSTextField to also respond to mouse events
@interface ClickableTextField : NSTextField
@property (weak, nonatomic) NSWindow *attachedWindow; // Reference to the notification window
@end

NS_ASSUME_NONNULL_END

//
//  ClickableView.h
//  decline
//
//  Created by Derek Scott on 8/1/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// Subclassing NSView to handle mouseDown
@interface ClickableView : NSView
@property (weak, nonatomic) NSWindow *attachedWindow; // Reference to the notification window
-  (void)fadeOutAndClose;
@end

NS_ASSUME_NONNULL_END

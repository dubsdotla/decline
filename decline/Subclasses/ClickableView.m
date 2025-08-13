//
//  ClickableView.m
//  decline
//
//  Created by Derek Scott on 8/1/25.
//

#import "ClickableView.h"

@implementation ClickableView

-  (void)mouseDown:(NSEvent *)event {
    [self fadeOutAndClose];
}

-  (void)fadeOutAndClose {
    NSView *contentView = self.attachedWindow.contentView;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.25; // Set the duration of the fade-out animation
        contentView.animator.alphaValue = 0.5; // Apply to entire content view
    } completionHandler:^{
        [self.attachedWindow close];
    }];
}

@end

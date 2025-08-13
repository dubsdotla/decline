//
//  ClickableTextField.m
//  decline
//
//  Created by Derek Scott on 8/1/25.
//

#import "ClickableTextField.h"
#import "ClickableView.h"

@implementation ClickableTextField

-  (void)mouseDown:(NSEvent *)event {
    ClickableView *backgroundView = (ClickableView *)self.superview.subviews.firstObject;
    [backgroundView fadeOutAndClose];
}

@end

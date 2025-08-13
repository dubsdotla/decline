//
//  CustomNotification.m
//  decline
//
//  Created by Derek Scott on 7/31/25.
//

#import "CustomNotification.h"
#import "ClickableView.h"
#import "ClickableTextField.h"
#import "CustomNotificationManager.h"

@implementation CustomNotification

-  (instancetype)init {
    NSRect frame = NSMakeRect(0, 0, 300, 100);
    NSPanel *panel = [[NSPanel alloc] initWithContentRect:frame
                                                 styleMask:(NSWindowStyleMaskNonactivatingPanel | NSWindowStyleMaskBorderless)
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
    [panel setLevel:NSFloatingWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    [panel setMovableByWindowBackground:YES];
    [panel setIgnoresMouseEvents:NO]; // Ensure mouse events are processed
            
    self = [super initWithWindow:panel];
    if (self) {
        // Use ClickableView for direct event handling
        ClickableView *backgroundView = [[ClickableView alloc] initWithFrame:frame];
        backgroundView.wantsLayer = YES;
        backgroundView.layer.backgroundColor = [[NSColor blackColor] colorWithAlphaComponent:0.7].CGColor;
        backgroundView.layer.cornerRadius = 15.0;
        backgroundView.attachedWindow = self.window;
        [[[self window] contentView] addSubview:backgroundView];
        
        ClickableTextField *label = [[ClickableTextField alloc] initWithFrame:NSZeroRect];
        [label setBezeled:NO];
        [label setEditable:NO];
        [label setBackgroundColor:[NSColor clearColor]];
        [label setTextColor:[NSColor whiteColor]];
        [label setTranslatesAutoresizingMaskIntoConstraints:NO];
        label.attachedWindow = self.window;
        [[[self window] contentView] addSubview:label];
        
        [NSLayoutConstraint activateConstraints:@[
            [label.leadingAnchor constraintEqualToAnchor:self.window.contentView.leadingAnchor constant:20],
            [label.trailingAnchor constraintEqualToAnchor:self.window.contentView.trailingAnchor constant:-20],
            [label.centerYAnchor constraintEqualToAnchor:self.window.contentView.centerYAnchor]
        ]];
    }
    return self;
}

+ (CGSize)sizeForMessage:(NSString*)message textSize:(NotificationTextSize)textSize {
  // Create a temporary attributed string with the system font
  CGFloat fontSize = (textSize == NotificationTextSizeSmall ? 12 :
                     (textSize == NotificationTextSizeMedium ? 16 : 20));
  NSDictionary *attrs = @{ NSFontAttributeName: [NSFont systemFontOfSize:fontSize] };
  NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:message
                                                                attributes:attrs];
  // Measure
  NSSize textSizeMeasured = [attrStr boundingRectWithSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)
                                                  options:NSStringDrawingUsesLineFragmentOrigin].size;
  // Add horizontal + vertical padding
  return NSMakeSize(textSizeMeasured.width + 40.0, textSizeMeasured.height + 20.0);
}

-  (void)showNotificationWithMessage:(NSString *)message
                          textSize:(NotificationTextSize)textSize
                         position:(NotificationPosition)position
                          offsetY:(CGFloat)offsetY
                           sticky:(BOOL)sticky
{
    
    // Store for manager reference
    self.position = position;
    self.offsetY  = offsetY;
    
    // Configure label
    ClickableTextField *label = (ClickableTextField *)self.window.contentView.subviews.lastObject;
    label.stringValue = message;
    
    CGFloat fontSize = (textSize == NotificationTextSizeSmall ? 12 :
                       (textSize == NotificationTextSizeMedium ? 16 : 20));
    label.font = [NSFont systemFontOfSize:fontSize];
    
    [label sizeToFit];
    NSRect labelFrame = label.frame;
    CGFloat windowWidth  = labelFrame.size.width  + 40;
    CGFloat windowHeight = labelFrame.size.height + 20;
    
    // Base position based on enum
    NSRect screenFrame = NSScreen.mainScreen.visibleFrame;
    CGFloat x=0, y=0;
    switch(position) {
        case NotificationPositionTopLeft:
            x = 20; y = NSMaxY(screenFrame) - windowHeight - 20; break;
        case NotificationPositionTopCenter:
            x = (screenFrame.size.width - windowWidth)/2; y = NSMaxY(screenFrame) - windowHeight - 20; break;
        case NotificationPositionTopRight:
            x = NSMaxX(screenFrame) - windowWidth - 20; y = NSMaxY(screenFrame) - windowHeight - 20; break;
        case NotificationPositionLeftCenter:
            x = 20; y = (screenFrame.size.height - windowHeight)/2; break;
        case NotificationPositionCenter:
            x = (screenFrame.size.width - windowWidth)/2; y = (screenFrame.size.height - windowHeight)/2; break;
        case NotificationPositionRightCenter:
            x = NSMaxX(screenFrame) - windowWidth - 20; y = (screenFrame.size.height - windowHeight)/2; break;
        case NotificationPositionBottomLeft:
            x = 20; y = screenFrame.origin.y + 20; break;
        case NotificationPositionBottomCenter:
            x = (screenFrame.size.width - windowWidth)/2; y = screenFrame.origin.y + 20; break;
        case NotificationPositionBottomRight:
        default:
            x = NSMaxX(screenFrame) - windowWidth - 20; y = screenFrame.origin.y + 20; break;
    }
    
    // Apply offsets and clamp to screen bounds
    CGFloat newY = y + offsetY;
    if (
        newY < screenFrame.origin.y ||
        newY + windowHeight > NSMaxY(screenFrame))
    {
        newY = y;
    }
    
    // Layout and present
    [self.window setFrame:NSMakeRect(x, newY, windowWidth, windowHeight) display:YES];
    //NSLog(@"OffsetY: %f", offsetY);
    
    ClickableView *bgView = self.window.contentView.subviews.firstObject;
    [bgView setFrame:NSMakeRect(0, 0, windowWidth, windowHeight)];
    [self.window orderFrontRegardless];
    
    // Auto-dismiss non-sticky
    if (!sticky) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
                        
            [bgView fadeOutAndClose];
        });
    }
}

// NSWindowDelegate
-  (void)windowWillClose:(NSNotification *)notification {
  [[CustomNotificationManager sharedManager] notificationDidClose:self];
}

@end

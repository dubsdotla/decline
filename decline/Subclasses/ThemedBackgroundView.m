//
//  ThemedBackgroundView.m
//  decline
//
//  Created by Derek Scott on 5/20/25.
//

#import "ThemedBackgroundView.h"

@implementation ThemedBackgroundView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // we’ll paint via layer
        self.wantsLayer = YES;
        // initial color
        self.layer.backgroundColor = [NSColor controlBackgroundColor].CGColor;
        
        /*self.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        self.state = NSVisualEffectStateActive;
        self.material = NSVisualEffectMaterialUnderWindowBackground;*/
    }
    return self;
}

// Called automatically when this view’s effectiveAppearance changes
- (void)viewDidChangeEffectiveAppearance {
    [NSAppearance setCurrentAppearance:self.effectiveAppearance];
    
    [super viewDidChangeEffectiveAppearance];
    // re-fetch the dynamic system color and apply it
    
    self.layer.backgroundColor = [NSColor controlBackgroundColor].CGColor;
}

@end

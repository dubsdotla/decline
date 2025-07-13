//
//  ConnectingViewController.m
//  decline
//
//  Created by Derek Scott on 6/27/25.
//

#import "ConnectingViewController.h"

@interface ConnectingViewController ()
@property (nonatomic, strong) NSString              *message;
@property (nonatomic, strong, readwrite) NSProgressIndicator *progressIndicator;
@end

@implementation ConnectingViewController

- (instancetype)initWithMessage:(NSString*)message {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _message = [message copy];
    }
    return self;
}

- (void)loadView {
    // Build a simple view: a label + progress indicator stacked vertically
    NSView *v = [[NSView alloc] initWithFrame:NSMakeRect(0,0,325,80)];
    v.translatesAutoresizingMaskIntoConstraints = NO;

    // 1) Label
    NSTextField *label = [NSTextField labelWithString:self.message];
    label.font = [NSFont systemFontOfSize:13];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [v addSubview:label];

    // 2) Indeterminate progress bar
    NSProgressIndicator *spinner = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    spinner.indeterminate = YES;
    spinner.style = NSProgressIndicatorStyleSpinning;
    [spinner startAnimation:nil];
    [v addSubview:spinner];
    _progressIndicator = spinner;

    // Auto-layout
    [NSLayoutConstraint activateConstraints:@[
      // label centered horizontally, 16pt from top
      [label.centerXAnchor       constraintEqualToAnchor:v.centerXAnchor],
      [label.topAnchor           constraintEqualToAnchor:v.topAnchor constant:16],

      // spinner below label
      [spinner.centerXAnchor     constraintEqualToAnchor:v.centerXAnchor],
      [spinner.topAnchor         constraintEqualToAnchor:label.bottomAnchor constant:12],
    ]];

    self.view = v;
}

@end

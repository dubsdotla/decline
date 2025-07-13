//
//  SendBroadcastViewController.m
//  decline
//
//  Created by Derek Scott on 5/21/25.
//

#import "SendBroadcastViewController.h"

@interface SendBroadcastViewController ()
@property (nonatomic, strong) NSTextField             *textField;
@property (nonatomic, strong) NSButton                *okayButton;
@property (nonatomic, strong) NSButton                *cancelButton;
@end

@implementation SendBroadcastViewController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 130)];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Label
    NSTextField *lbl = [[NSTextField alloc] initWithFrame:NSZeroRect];
    lbl.stringValue = @"Enter a broadcast message";
    lbl.bezeled      = NO;
    lbl.drawsBackground = NO;
    lbl.editable    = NO;
    lbl.selectable  = NO;
    lbl.font = [NSFont boldSystemFontOfSize:14];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:lbl];

    // Single‐line text field
    self.textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    self.textField.placeholderString = @"";
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.textField];

    // Buttons
    self.cancelButton = [NSButton buttonWithTitle:@"Cancel"
                                          target:self
                                          action:@selector(cancelPressed)];
    self.cancelButton.bezelStyle = NSBezelStyleRounded;
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.okayButton = [NSButton buttonWithTitle:@"Send"
                                      target:self
                                      action:@selector(okPressed)];
    self.okayButton.bezelStyle = NSBezelStyleRounded;
    self.okayButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.okayButton setKeyEquivalent:@"\r"]; // Return key triggers OK
    
    [self.view addSubview:self.cancelButton];
    [self.view addSubview:self.okayButton];


    // Auto Layout
    [NSLayoutConstraint activateConstraints:@[
        // Label top‐left
        [lbl.topAnchor    constraintEqualToAnchor:self.view.topAnchor    constant:20],
        [lbl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        // TextField below label
        [self.textField.topAnchor      constraintEqualToAnchor:lbl.bottomAnchor constant:8],
        [self.textField.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.textField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.textField.heightAnchor   constraintEqualToConstant:24],
        // OK/Cancel buttons
        [self.cancelButton.leadingAnchor  constraintEqualToAnchor:self.view.centerXAnchor constant:-70],
        [self.cancelButton.bottomAnchor   constraintEqualToAnchor:self.view.bottomAnchor constant:-20],
        
        // ok button
        [self.okayButton.leadingAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:10],
        [self.okayButton.centerYAnchor      constraintEqualToAnchor:self.cancelButton.centerYAnchor],
    ]];
}

/*- (void)viewDidAppear
{
    [super viewDidAppear];
    [self.view.window makeFirstResponder:_okayButton];
}*/

- (void)okPressed {
    if (self.completionHandler) {
        NSString *broadcastText = self.textField.stringValue;
        self.completionHandler(broadcastText);
    }
    [self.view.window.sheetParent endSheet:self.view.window returnCode:NSModalResponseOK];
}

- (void)cancelPressed {
    [self.view.window.sheetParent endSheet:self.view.window returnCode:NSModalResponseCancel];
}

@end

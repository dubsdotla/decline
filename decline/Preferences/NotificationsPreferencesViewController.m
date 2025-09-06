//
//  NotificationsPreferencesViewController.m
//  decline
//
//  Created by Derek Scott on 8/26/25.
//

#import "NotificationsPreferencesViewController.h"
#import "CustomNotification.h"
#import "AppDelegate.h"

@interface NotificationsPreferencesViewController ()
@property (nonatomic, strong) NSButton      *enableNotificationsCheckbox;
@property (nonatomic, strong) NSPopUpButton *textSizePopup;
@property (nonatomic, strong) NSPopUpButton *positionPopup;
@property (nonatomic, strong) NSButton      *enableStickyCheckbox;
@property (nonatomic, strong) NSTextField *previewTextField;
@property (nonatomic, strong) NSButton    *previewButton;
@end

@implementation NotificationsPreferencesViewController

- (instancetype)init {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.title = @"Notifications";
    }
    return self;
}

- (void)viewDidLayout {
    [super viewDidLayout];

    // Compute once the view has a real layout
    NSView *v = self.view;
    NSSize s = v.translatesAutoresizingMaskIntoConstraints ? v.bounds.size : v.fittingSize;
    if (s.width  < 400) s.width  = 400;   // optional floor
    if (s.height < 250) s.height = 250;   // optional floor

    // Only update if it actually changed (prevents resize loops)
    if (!NSEqualSizes(self.preferredContentSize, s)) {
        self.preferredContentSize = s;    // <-- use the property, don't override the method
    }
}

- (void)loadView {
    NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 250)];
    self.view = root;

    // ===== Vertical stack (Safari/Xcode prefs look) =====
    NSStackView *vstack = [NSStackView stackViewWithViews:@[]];
    vstack.orientation = NSUserInterfaceLayoutOrientationVertical;
    vstack.alignment   = NSLayoutAttributeCenterX;   // center title only
    vstack.spacing     = 12.0;
    vstack.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:vstack];

    [NSLayoutConstraint activateConstraints:@[
        [vstack.topAnchor constraintEqualToAnchor:root.topAnchor constant:8.0],
        [vstack.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:20.0],
        [vstack.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-20.0],
    ]];

    // --- Form container (left aligned)
    NSView *form = [NSView new];
    form.translatesAutoresizingMaskIntoConstraints = NO;
    [vstack addArrangedSubview:form];

    NSTextField *(^Label)(NSString *) = ^NSTextField *(NSString *s) {
        NSTextField *l = [NSTextField labelWithString:s];
        l.translatesAutoresizingMaskIntoConstraints = NO;
        return l;
    };

    // Enable notifications
    self.enableNotificationsCheckbox =
    [NSButton checkboxWithTitle:@"Enable Notifications"
                         target:self
                         action:@selector(onToggleEnable:)];
    self.enableNotificationsCheckbox.translatesAutoresizingMaskIntoConstraints = NO;
    self.enableNotificationsCheckbox.state = [defaults boolForKey:@"NotificationsEnabled"]
                                           ? NSControlStateValueOn
                                           : NSControlStateValueOff;
    [form addSubview:self.enableNotificationsCheckbox];

    // Notification Text Size
    NSTextField *textSizeLabel = Label(@"Notification Text Size:");
    [form addSubview:textSizeLabel];

    self.textSizePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    self.textSizePopup.translatesAutoresizingMaskIntoConstraints = NO;
    [self.textSizePopup addItemsWithTitles:@[@"Small", @"Medium", @"Large"]];
    {
        NotificationPosition textSize = [defaults integerForKey:@"NotificationTextSize"];
        NSString *textSizeString = [[CustomNotificationManager sharedManager] textSizeStringFromEnum:textSize];
        [self.textSizePopup selectItemWithTitle:textSizeString];
    }
    self.textSizePopup.target = self;
    self.textSizePopup.action = @selector(onTextSizeChanged:);
    [form addSubview:self.textSizePopup];

    // Notification Position
    NSTextField *posLabel = Label(@"Notification Base Position:");
    [form addSubview:posLabel];

    self.positionPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    self.positionPopup.translatesAutoresizingMaskIntoConstraints = NO;
    [self.positionPopup addItemsWithTitles:@[
        @"Top Left", @"Top Center", @"Top Right",
        @"Left Center", @"Center", @"Right Center",
        @"Bottom Left", @"Bottom Center", @"Bottom Right"
    ]];
    {
        NotificationPosition position = [defaults integerForKey:@"NotificationPosition"];
        NSString *positionString = [[CustomNotificationManager sharedManager] positionStringFromEnum:position];
        [self.positionPopup selectItemWithTitle:positionString];
    }
    self.positionPopup.target = self;
    self.positionPopup.action = @selector(onPositionChanged:);
    [form addSubview:self.positionPopup];
    
    self.enableStickyCheckbox =
    [NSButton checkboxWithTitle:@"Make Notifications Sticky"
                         target:self
                         action:@selector(onToggleSticky:)];
    self.enableStickyCheckbox.translatesAutoresizingMaskIntoConstraints = NO;
    self.enableStickyCheckbox.state = [defaults boolForKey:@"NotificationSticky"]
                                           ? NSControlStateValueOn
                                           : NSControlStateValueOff;
    [form addSubview:self.enableStickyCheckbox];
    
    // --- Preview row (text field + button on one line) ---
    self.previewTextField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    self.previewTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.previewTextField.placeholderString = @"Notification text";
    self.previewTextField.stringValue =
        [NSUserDefaults.standardUserDefaults stringForKey:@"NotificationPreviewText"] ?: @"testing";
    [form addSubview:self.previewTextField];

    self.previewButton = [NSButton buttonWithTitle:@"Preview Notification"
                                            target:self
                                            action:@selector(onPreview:)];
    self.previewButton.translatesAutoresizingMaskIntoConstraints = NO;
    [form addSubview:self.previewButton];

    [self enableOrDisableOtherControls];

    // ===== Layout (clean rows & spacing) =====
    const CGFloat vGap = 20.0;
    const CGFloat hGap = 12.0;

    [NSLayoutConstraint activateConstraints:@[
        // Row 0: checkbox
        [self.enableNotificationsCheckbox.topAnchor constraintEqualToAnchor:form.topAnchor  constant:vGap],
        [self.enableNotificationsCheckbox.leadingAnchor constraintEqualToAnchor:form.leadingAnchor],

        // Row 1: Text Size
        [textSizeLabel.topAnchor constraintEqualToAnchor:self.enableNotificationsCheckbox.bottomAnchor constant:vGap],
        [textSizeLabel.leadingAnchor constraintEqualToAnchor:form.leadingAnchor],

        [self.textSizePopup.centerYAnchor constraintEqualToAnchor:textSizeLabel.centerYAnchor],
        [self.textSizePopup.leadingAnchor constraintEqualToAnchor:textSizeLabel.trailingAnchor constant:hGap],

        // Row 2: Position
        [posLabel.topAnchor constraintEqualToAnchor:textSizeLabel.bottomAnchor constant:vGap],
        [posLabel.leadingAnchor constraintEqualToAnchor:form.leadingAnchor],

        [self.positionPopup.centerYAnchor constraintEqualToAnchor:posLabel.centerYAnchor],
        [self.positionPopup.leadingAnchor constraintEqualToAnchor:posLabel.trailingAnchor constant:hGap],
        
        // Row 3: Sticky checkbox (already present)
        [self.enableStickyCheckbox.topAnchor constraintEqualToAnchor:posLabel.bottomAnchor  constant:vGap],
        [self.enableStickyCheckbox.leadingAnchor constraintEqualToAnchor:form.leadingAnchor],

        // Row 4: Preview row (textfield + button, same line)
        [self.previewTextField.topAnchor constraintEqualToAnchor:self.enableStickyCheckbox.bottomAnchor constant:vGap],
        [self.previewTextField.leadingAnchor constraintEqualToAnchor:form.leadingAnchor],
        [self.previewTextField.widthAnchor constraintGreaterThanOrEqualToConstant:220.0],

        [self.previewButton.centerYAnchor constraintEqualToAnchor:self.previewTextField.centerYAnchor],
        [self.previewButton.leadingAnchor constraintEqualToAnchor:self.previewTextField.trailingAnchor constant:hGap],

        // trailing hug + form bottom
        [form.trailingAnchor constraintGreaterThanOrEqualToAnchor:self.previewButton.trailingAnchor],
        [form.bottomAnchor constraintEqualToAnchor:self.previewTextField.bottomAnchor],
    ]];
}

#pragma mark - Persist & sizing

- (void)onToggleEnable:(NSButton *)sender {
    
    [self enableOrDisableOtherControls];
    
    [defaults setBool:(sender.state == NSControlStateValueOn) forKey:@"NotificationsEnabled"];
}

- (void)onTextSizeChanged:(NSPopUpButton *)sender {
    NSString *string = sender.titleOfSelectedItem ?: @"Medium";
    NSUInteger integer = [[CustomNotificationManager sharedManager] textSizeEnumFromString:string];
    
    [defaults setInteger:integer forKey:@"NotificationTextSize"];
}

- (void)onPositionChanged:(NSPopUpButton *)sender {
    NSString *string = sender.titleOfSelectedItem ?: @"Center";
    NSUInteger integer = [[CustomNotificationManager sharedManager] positionEnumFromString:string];
    
    [defaults setInteger:integer forKey:@"NotificationPosition"];
}

- (void)onToggleSticky:(NSButton *)sender {
    [defaults setBool:(sender.state == NSControlStateValueOn) forKey:@"NotificationSticky"];
}

- (void)onPreview:(id)sender {
    NSString *text = self.previewTextField.stringValue.length
    ? self.previewTextField.stringValue
    : @"testing";
    
    if([text isEqualToString:@"testing"]) {
        self.previewTextField.stringValue = @"testing";
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NotificationTextSize textsize = [defaults integerForKey:@"NotificationTextSize"];
        NotificationPosition position = [defaults integerForKey:@"NotificationPosition"];
        BOOL sticky = [defaults boolForKey:@"NotificationSticky"];
        
        [[CustomNotificationManager sharedManager] showNotificationWithMessage:text textSize:textsize position:position sticky:sticky];
    });
}

- (void)enableOrDisableOtherControls {
    //if enableNotificationsCheckbox is checked other controls are enabled, else they are disabled
    
    if(self.enableNotificationsCheckbox.state == NSControlStateValueOn) {
        self.textSizePopup.enabled = YES;
        self.positionPopup.enabled = YES;
        self.enableStickyCheckbox.enabled = YES;
        self.previewTextField.enabled = YES;
        self.previewButton.enabled = YES;
    }
    
    else {
        self.textSizePopup.enabled = NO;
        self.positionPopup.enabled = NO;
        self.enableStickyCheckbox.enabled = NO;
        self.previewTextField.enabled = NO;
        self.previewButton.enabled = NO;
    }
}

@end

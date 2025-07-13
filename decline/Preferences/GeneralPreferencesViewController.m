// GeneralPreferencesViewController.m
#import "GeneralPreferencesViewController.h"
#import "AppDelegate.h"

@interface GeneralPreferencesViewController ()
@property (nonatomic, strong) NSButton                *joinLeaveCheckbox;
@property (nonatomic, strong) NSButton                *nickChangeCheckbox;
@property (nonatomic, strong) NSButton                *showUserlistRightCheckbox;
@property (nonatomic, strong) NSButton                *showChatSendButtonCheckbox;
@end

@implementation GeneralPreferencesViewController

- (void)loadView {
    NSView *v = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 250)];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    self.view = v;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // ensure defaults are registered (in case showPreferences called first)

    // --- Default Nick ---
    NSTextField *nickLabel = [NSTextField labelWithString:@"Default Nick:"];
    nickLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [v addSubview:nickLabel];

    NSTextField *nickField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    nickField.translatesAutoresizingMaskIntoConstraints = NO;
    nickField.placeholderString = @"Enter default nickname";
    nickField.stringValue = [defaults stringForKey:@"DefaultNick"];
    nickField.target = self;
    nickField.action = @selector(defaultNickChanged:);
    [v addSubview:nickField];

    // --- Default Icon ---
    NSTextField *iconLabel = [NSTextField labelWithString:@"Default Icon:"];
    iconLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [v addSubview:iconLabel];

    NSTextField *iconField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    iconField.translatesAutoresizingMaskIntoConstraints = NO;
    iconField.placeholderString = @"Enter default icon number";
    iconField.stringValue = [defaults stringForKey:@"DefaultIcon"];
    iconField.target = self;
    iconField.action = @selector(defaultIconChanged:);
    [v addSubview:iconField];
    
    self.joinLeaveCheckbox = [[NSButton alloc] initWithFrame:NSZeroRect];
    self.joinLeaveCheckbox.buttonType = NSButtonTypeSwitch;
    self.joinLeaveCheckbox.title      = @"Show Join/Leave messages in Chat";
    self.joinLeaveCheckbox.translatesAutoresizingMaskIntoConstraints = NO;
    [self.joinLeaveCheckbox setTarget:self];
    [self.joinLeaveCheckbox setAction:@selector(toggleJoinLeave:)];
    [v addSubview:self.joinLeaveCheckbox];
    
    self.nickChangeCheckbox = [[NSButton alloc] initWithFrame:NSZeroRect];
    self.nickChangeCheckbox.buttonType = NSButtonTypeSwitch;
    self.nickChangeCheckbox.title      = @"Show nickname changes in Chat";
    self.nickChangeCheckbox.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nickChangeCheckbox setTarget:self];
    [self.nickChangeCheckbox setAction:@selector(toggleNickChange:)];
    [v addSubview:self.nickChangeCheckbox];
    
    self.showUserlistRightCheckbox = [[NSButton alloc] initWithFrame:NSZeroRect];
    self.showUserlistRightCheckbox.buttonType = NSButtonTypeSwitch;
    self.showUserlistRightCheckbox.title      = @"Show Userlist on the Right Side of Chat View";
    self.showUserlistRightCheckbox.translatesAutoresizingMaskIntoConstraints = NO;
    [self.showUserlistRightCheckbox setTarget:self];
    [self.showUserlistRightCheckbox setAction:@selector(toggleUserlistSide:)];
    [v addSubview:self.showUserlistRightCheckbox];
    
    self.showChatSendButtonCheckbox = [[NSButton alloc] initWithFrame:NSZeroRect];
    self.showChatSendButtonCheckbox.buttonType = NSButtonTypeSwitch;
    self.showChatSendButtonCheckbox.title      = @"Show the Chat View's Send Button";
    self.showChatSendButtonCheckbox.translatesAutoresizingMaskIntoConstraints = NO;
    [self.showChatSendButtonCheckbox setTarget:self];
    [self.showChatSendButtonCheckbox setAction:@selector(toggleSendButton:)];
    [v addSubview:self.showChatSendButtonCheckbox];

    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // nick label
        [nickLabel.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:20],
        [nickLabel.topAnchor constraintEqualToAnchor:v.topAnchor constant:20],
        // nick field
        [nickField.leadingAnchor constraintEqualToAnchor:nickLabel.trailingAnchor constant:8],
        [nickField.centerYAnchor constraintEqualToAnchor:nickLabel.centerYAnchor],
        [nickField.trailingAnchor constraintEqualToAnchor:v.trailingAnchor constant:-20],
        
        // icon label
        [iconLabel.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:20],
        [iconLabel.topAnchor constraintEqualToAnchor:nickLabel.bottomAnchor constant:20],
        // icon field
        [iconField.leadingAnchor constraintEqualToAnchor:iconLabel.trailingAnchor constant:8],
        [iconField.centerYAnchor constraintEqualToAnchor:iconLabel.centerYAnchor],
        [iconField.trailingAnchor constraintEqualToAnchor:v.trailingAnchor constant:-20],

        [self.joinLeaveCheckbox.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:20],
        [self.joinLeaveCheckbox.topAnchor constraintEqualToAnchor:iconLabel.bottomAnchor constant:20],
        
        [self.nickChangeCheckbox.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:20],
        [self.nickChangeCheckbox.topAnchor constraintEqualToAnchor:self.joinLeaveCheckbox.bottomAnchor constant:20],
        
        [self.showUserlistRightCheckbox.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:20],
        [self.showUserlistRightCheckbox.topAnchor constraintEqualToAnchor:self.nickChangeCheckbox.bottomAnchor constant:20],
        
        [self.showChatSendButtonCheckbox.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:20],
        [self.showChatSendButtonCheckbox.topAnchor constraintEqualToAnchor:self.showUserlistRightCheckbox.bottomAnchor constant:20]
    ]];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    
    // 4) Populate its initial state from defaults
    BOOL showJoin = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowJoinLeaveMessages"];
    self.joinLeaveCheckbox.state = showJoin ? NSControlStateValueOn : NSControlStateValueOff;
    
    BOOL showNick = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowNickChangeMessages"];
    self.nickChangeCheckbox.state = showNick ? NSControlStateValueOn : NSControlStateValueOff;
    
    BOOL showRight = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowUserlistOnRightSide"];
    self.showUserlistRightCheckbox.state = showRight ? NSControlStateValueOn : NSControlStateValueOff;
    
    BOOL showSend = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowChatSendButton"];
    self.showChatSendButtonCheckbox.state = showSend ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)defaultNickChanged:(NSTextField *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:sender.stringValue forKey:@"DefaultNick"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)defaultIconChanged:(NSTextField *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:sender.stringValue forKey:@"DefaultIcon"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark – Action

- (void)toggleJoinLeave:(NSButton*)sender {
    BOOL newVal = (sender.state == NSControlStateValueOn);
    [[NSUserDefaults standardUserDefaults] setBool:newVal forKey:@"ShowJoinLeaveMessages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)toggleNickChange:(NSButton*)sender {
    BOOL newVal = (sender.state == NSControlStateValueOn);
    [[NSUserDefaults standardUserDefaults] setBool:newVal forKey:@"ShowNickChangeMessages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)toggleUserlistSide:(NSButton*)sender {
    BOOL newVal = (sender.state == NSControlStateValueOn);
    [[NSUserDefaults standardUserDefaults] setBool:newVal forKey:@"ShowUserlistOnRightSide"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    AppDelegate *appDel = (AppDelegate *)[NSApp delegate];
    [appDel updateChatView];
}

- (void)toggleSendButton:(NSButton*)sender {
    BOOL newVal = (sender.state == NSControlStateValueOn);
    [[NSUserDefaults standardUserDefaults] setBool:newVal forKey:@"ShowChatSendButton"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    AppDelegate *appDel = (AppDelegate *)[NSApp delegate];
    [appDel updateChatView];
}


@end

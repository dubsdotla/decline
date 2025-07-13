//
//  ChangeNickIconViewController.m
//  decline
//
//  Created by Derek Scott on 5/21/25.
//

#import "ChangeNickIconViewController.h"

@interface ChangeNickIconViewController ()

@property (nonatomic, copy, readonly)   NSString *initialNickname;
@property (nonatomic, assign, readwrite) uint32_t initialIconNumber;
@property (nonatomic, strong) NSTextField *nicknameField;
@property (nonatomic, strong) NSTextField *iconNumberField;
@property (nonatomic, strong) NSButton   *okayButton;
@property (nonatomic, strong) NSButton   *cancelButton;

@end

@implementation ChangeNickIconViewController

- (instancetype)initWithNickname:(NSString*)nick
                     iconNumber:(uint32_t)icon
{
    // since you're building in code (loadView), use this:
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;

    _initialNickname   = [nick copy];
    _initialIconNumber = icon;
    return self;
}

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 160)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Labels
    NSTextField *nicknameLabel = [self labelWithString:@"Nickname:"];
    NSTextField *iconLabel = [self labelWithString:@"Icon Number:"];
    
    self.nicknameField = [self textFieldWithPlaceholder:@""];
    self.iconNumberField = [self textFieldWithPlaceholder:@""];
    
    self.nicknameField.stringValue = self.initialNickname ?: @"";
    self.iconNumberField.stringValue = [@(self.initialIconNumber) stringValue];

    // Buttons
    self.okayButton = [self buttonWithTitle:@"Update" action:@selector(okPressed)];
    self.cancelButton = [self buttonWithTitle:@"Cancel" action:@selector(cancelPressed)];
    
    [self.okayButton setKeyEquivalent:@"\r"]; // Return key triggers OK
    [self.cancelButton setBezelStyle:NSBezelStyleRounded];
    [self.okayButton setBezelStyle:NSBezelStyleRounded];
    
    NSTextField *headingLabel = [self  labelWithString:@"Enter a new nickname and/or icon number"];
    headingLabel.font = [NSFont boldSystemFontOfSize:14];

    // Nickname row
    NSStackView *nicknameRow = [[NSStackView alloc] init];
    nicknameRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    nicknameRow.spacing = 8;
    nicknameRow.alignment = NSLayoutAttributeFirstBaseline;
    nicknameRow.translatesAutoresizingMaskIntoConstraints = NO;
    [nicknameRow addArrangedSubview:nicknameLabel];
    [nicknameRow addArrangedSubview:self.nicknameField];

    // Icon row
    NSStackView *iconRow = [[NSStackView alloc] init];
    iconRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    iconRow.spacing = 8;
    iconRow.alignment = NSLayoutAttributeFirstBaseline;
    iconRow.translatesAutoresizingMaskIntoConstraints = NO;
    [iconRow addArrangedSubview:iconLabel];
    [iconRow addArrangedSubview:self.iconNumberField];

    // Button row
    NSStackView *buttonRow = [[NSStackView alloc] init];
    buttonRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    buttonRow.spacing = 12;
    buttonRow.alignment = NSLayoutAttributeCenterY;
    buttonRow.distribution = NSStackViewDistributionEqualSpacing;
    buttonRow.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonRow addArrangedSubview:self.cancelButton];
    [buttonRow addArrangedSubview:self.okayButton]; // OK on the right

    // Main vertical stack
    NSStackView *mainStack = [[NSStackView alloc] init];
    mainStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    mainStack.spacing = 16;
    mainStack.edgeInsets = NSEdgeInsetsMake(20, 20, 20, 20);
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    [mainStack addArrangedSubview:headingLabel];
    [mainStack addArrangedSubview:nicknameRow];
    [mainStack addArrangedSubview:iconRow];
    [mainStack addArrangedSubview:buttonRow];

    [self.view addSubview:mainStack];

    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        [mainStack.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [mainStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [mainStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [mainStack.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [nicknameLabel.widthAnchor constraintEqualToAnchor:iconLabel.widthAnchor],
        [self.nicknameField.widthAnchor constraintGreaterThanOrEqualToConstant:200],
        [self.iconNumberField.widthAnchor constraintEqualToAnchor:self.nicknameField.widthAnchor],
    ]];
}

- (NSTextField *)labelWithString:(NSString *)string {
    NSTextField *label = [NSTextField labelWithString:string];
    label.alignment = NSTextAlignmentRight;
    return label;
}

- (NSTextField *)textFieldWithPlaceholder:(NSString *)placeholder {
    NSTextField *field = [[NSTextField alloc] init];
    field.placeholderString = placeholder;
    return field;
}

- (NSButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    NSButton *button = [NSButton buttonWithTitle:title target:self action:action];
    return button;
}

/*- (void)viewDidAppear
{
    [super viewDidAppear];
    [self.view.window makeFirstResponder:_okayButton];
}*/

- (void)okPressed {
    if (self.completionHandler) {
        NSInteger iconNum = self.iconNumberField.integerValue;
        self.completionHandler(self.nicknameField.stringValue, (uint32_t)iconNum);
    }
    [self.view.window.sheetParent endSheet:self.view.window returnCode:NSModalResponseOK];
}

- (void)cancelPressed {
    [self.view.window.sheetParent endSheet:self.view.window returnCode:NSModalResponseCancel];
}

@end

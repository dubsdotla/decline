//
//  CustomTextFieldWithPopup.m
//
#import "CustomTextFieldWithPopup.h"

@implementation PaddedTextFieldCell

- (instancetype)init {
    self = [super init];
    if (self) {
        self.rightPadding = 28.0; // Default padding for button
    }
    return self;
}

- (NSRect)drawingRectForBounds:(NSRect)rect {
    NSRect drawingRect = [super drawingRectForBounds:rect];
    drawingRect.size.width -= self.rightPadding;
    return drawingRect;
}

- (NSRect)titleRectForBounds:(NSRect)rect {
    NSRect titleRect = [super titleRectForBounds:rect];
    titleRect.size.width -= self.rightPadding;
    return titleRect;
}

@end

@interface CustomTextFieldWithPopup ()
@property (nonatomic, strong, readwrite) NSTextField *textField;
@property (nonatomic, strong, readwrite) NSButton *popupButton;
@end

@implementation CustomTextFieldWithPopup

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupSubviews];
        [self setupConstraints];
    }
    return self;
}

- (void)setupSubviews {
    // Create the text field with custom cell
    self.textField = [[NSTextField alloc] init];
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    self.textField.bordered = YES;
    self.textField.bezeled = YES;
    self.textField.stringValue = @"";
    self.textField.placeholderString = @"Enter text here...";
    
    // Use custom cell with right padding
    PaddedTextFieldCell *paddedCell = [[PaddedTextFieldCell alloc] init];
    paddedCell.bordered = YES;
    paddedCell.bezeled = YES;
    paddedCell.editable = YES;
    paddedCell.selectable = YES;
    self.textField.cell = paddedCell;
    
    // Create the popup button
    self.popupButton = [[NSButton alloc] init];
    self.popupButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.popupButton.buttonType = NSButtonTypeMomentaryPushIn;
    self.popupButton.bordered = NO;
    self.popupButton.bezelStyle = NSBezelStyleRegularSquare;
    
    // Set default SF Symbol
    [self setPopupButtonSymbolName:@"chevron.down"];
    
    [self addSubview:self.textField];
    [self addSubview:self.popupButton];
}

- (void)setupConstraints {
    CGFloat buttonWidth = 20.0;
    CGFloat rightPadding = 4.0;
    
    [NSLayoutConstraint activateConstraints:@[
        // Text field constraints - fill the entire container
        [self.textField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.textField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.textField.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.textField.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        // Popup button constraints - positioned inside the text field on the right
        [self.popupButton.trailingAnchor constraintEqualToAnchor:self.textField.trailingAnchor constant:-rightPadding],
        [self.popupButton.centerYAnchor constraintEqualToAnchor:self.textField.centerYAnchor],
        [self.popupButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [self.popupButton.heightAnchor constraintEqualToConstant:buttonWidth]
    ]];
}

- (void)setPopupButtonImage:(NSImage *)image {
    self.popupButton.image = image;
}

- (void)setPopupButtonSymbolName:(NSString *)symbolName {
    if (@available(macOS 11.0, *)) {
        NSImage *symbolImage = [NSImage imageWithSystemSymbolName:symbolName accessibilityDescription:nil];
        if (symbolImage) {
            [self setPopupButtonImage:symbolImage];
        }
    }
}

@end

//
//  CustomTextFieldWithPopup.h
//
#import <Cocoa/Cocoa.h>

@interface PaddedTextFieldCell : NSTextFieldCell
@property (nonatomic, assign) CGFloat rightPadding;
@end

@interface CustomTextFieldWithPopup : NSView

@property (nonatomic, strong, readonly) NSTextField *textField;
@property (nonatomic, strong, readonly) NSButton *popupButton;
@property (nonatomic, strong) NSMenu *popupMenu;

- (instancetype)initWithFrame:(NSRect)frameRect;
- (void)setPopupButtonImage:(NSImage *)image;
- (void)setPopupButtonSymbolName:(NSString *)symbolName;

@end

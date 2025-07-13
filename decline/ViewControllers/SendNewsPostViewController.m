#import "SendNewsPostViewController.h"

@interface SendNewsPostViewController ()
@property (nonatomic, strong) NSTextView *textView;
@property (nonatomic, strong) NSButton   *okButton;
@property (nonatomic, strong) NSButton   *cancelButton;
@end

@implementation SendNewsPostViewController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 480, 360)];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 1) Heading
    /*NSTextField *heading = [NSTextField labelWithString:@"Enter a new news post"];
    heading.font = [NSFont boldSystemFontOfSize:14];
    heading.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:heading];*/
    
    // 2) Scroll + textView
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    scroll.translatesAutoresizingMaskIntoConstraints   = NO;
    scroll.hasVerticalScroller   = YES;
    scroll.hasHorizontalScroller = NO;
    scroll.borderType            = NSNoBorder;
    [self.view addSubview:scroll];
    
    self.textView = [[NSTextView alloc] initWithFrame:NSZeroRect];
    self.textView.translatesAutoresizingMaskIntoConstraints       = NO;
    self.textView.minSize               = NSMakeSize(0,0);
    self.textView.maxSize               = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
    self.textView.verticallyResizable   = YES;
    self.textView.horizontallyResizable = NO;
    self.textView.textContainerInset    = NSMakeSize(5,5);
    self.textView.textContainer.widthTracksTextView  = YES;
    self.textView.textContainer.heightTracksTextView = NO;
    self.textView.font                  = [NSFont userFixedPitchFontOfSize:12];
    self.textView.editable              = YES;
    self.textView.selectable            = YES;
    self.textView.drawsBackground = NO;
    self.textView.textColor       = [NSColor textColor];
    self.textView.string = @"Your new news post goes here!";
    
    scroll.documentView = self.textView;
    
    // after `scroll.documentView = self.textView;`
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    NSClipView *clip = scroll.contentView;
    [NSLayoutConstraint activateConstraints:@[
      [self.textView.leadingAnchor  constraintEqualToAnchor:clip.leadingAnchor],
      [self.textView.trailingAnchor constraintEqualToAnchor:clip.trailingAnchor],
      [self.textView.topAnchor      constraintEqualToAnchor:clip.topAnchor],
      [self.textView.bottomAnchor   constraintEqualToAnchor:clip.bottomAnchor],
      // and ensure it’s at least some reasonable height so you can see the first lines:
      [self.textView.heightAnchor   constraintGreaterThanOrEqualToConstant:100],
    ]];
    
    // 3) Buttons
    self.cancelButton = [NSButton buttonWithTitle:@"Cancel"
                                           target:self
                                           action:@selector(cancelPressed)];
    self.cancelButton.bezelStyle = NSBezelStyleRounded;
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.okButton = [NSButton buttonWithTitle:@"Send"
                                       target:self
                                       action:@selector(okPressed)];
    self.okButton.bezelStyle = NSBezelStyleRounded;
    self.okButton.translatesAutoresizingMaskIntoConstraints = NO;
    //[self.okButton setKeyEquivalent:@"\r"]; // Return key triggers OK

    [self.view addSubview:self.cancelButton];
    [self.view addSubview:self.okButton];
    
    // 4) Auto Layout
    [NSLayoutConstraint activateConstraints:@[
      // heading
      //[heading.topAnchor     constraintEqualToAnchor:self.view.topAnchor constant:20],
      //[heading.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
      //[heading.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
      
      // scroll/textview block
      //[scroll.topAnchor      constraintEqualToAnchor:heading.bottomAnchor constant:12],
      [scroll.topAnchor      constraintEqualToAnchor:self.view.topAnchor constant:20],
      [scroll.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor constant:20],
      [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
      [scroll.bottomAnchor   constraintEqualToAnchor:self.cancelButton.topAnchor constant:-20],
      
      // cancel button
      [self.cancelButton.leadingAnchor  constraintEqualToAnchor:self.view.centerXAnchor constant:-70],
      [self.cancelButton.bottomAnchor   constraintEqualToAnchor:self.view.bottomAnchor constant:-20],
      
      // ok button
      [self.okButton.leadingAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:10],
      [self.okButton.centerYAnchor      constraintEqualToAnchor:self.cancelButton.centerYAnchor],
    ]];
}

- (void)okPressed {
    if (self.completionHandler) {
        NSString *newsText = self.textView.string;
        self.completionHandler(newsText);
    }
    [self.view.window.sheetParent endSheet:self.view.window returnCode:NSModalResponseOK];
}

- (void)cancelPressed {
    [self.view.window.sheetParent endSheet:self.view.window returnCode:NSModalResponseCancel];
}

@end

#import "ShowAgreementViewController.h"

@interface ShowAgreementViewController ()
@property (nonatomic, copy, readonly)   NSString *agreement;
@property (nonatomic, strong) NSTextView *textView;
@property (nonatomic, strong) NSButton   *okayButton;
//@property (nonatomic, strong) NSButton   *cancelButton;
@end

@implementation ShowAgreementViewController

- (instancetype)initWithAgreement:(NSString*)agreement
{
    // since you're building in code (loadView), use this:
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;

    _agreement   = [agreement copy];
    return self;
}

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 600, 360)];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Scroll‐view container
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    scroll.translatesAutoresizingMaskIntoConstraints   = NO;
    scroll.hasVerticalScroller   = YES;
    scroll.hasHorizontalScroller = NO;
    scroll.borderType            = NSNoBorder;
    [self.view addSubview:scroll];

    // Text‐view as documentView (no Auto Layout on it)
    self.textView = [[NSTextView alloc] initWithFrame:NSZeroRect];
    // allow manual resizing:
    self.textView.translatesAutoresizingMaskIntoConstraints = YES;
    self.textView.autoresizingMask = NSViewWidthSizable;
    // scrolling behavior:
    self.textView.verticallyResizable   = YES;
    self.textView.horizontallyResizable = NO;
    self.textView.textContainerInset    = NSMakeSize(5,5);
    self.textView.textContainer.widthTracksTextView   = YES;
    self.textView.textContainer.heightTracksTextView  = NO;
    // styling
    self.textView.font            = [NSFont userFixedPitchFontOfSize:12];
    self.textView.editable        = NO;
    self.textView.selectable      = YES;
    self.textView.drawsBackground = NO;
    self.textView.textColor       = [NSColor textColor];
    
    // turn on automatic link detection
    // this will scan the text and wrap anything that looks like http://… or https://… in an NSLink attribute
    self.textView.automaticLinkDetectionEnabled = YES;

    // only detect links (you can OR in other NSTextCheckingType bits if you like)
    self.textView.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    
    // hook it up
    scroll.documentView = self.textView;

    // OK button
    self.okayButton = [NSButton buttonWithTitle:@"agree" target:self action:@selector(okPressed)];
    
    self.okayButton.bezelStyle = NSBezelStyleRounded;
    self.okayButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.okayButton setKeyEquivalent:@"\r"];
    [self.view addSubview:self.okayButton];

    // Auto Layout for heading, scroll, OK button
    [NSLayoutConstraint activateConstraints:@[
        // scroll‐view
        [scroll.topAnchor      constraintEqualToAnchor:self.view.topAnchor constant:20],
        [scroll.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [scroll.bottomAnchor   constraintEqualToAnchor:self.okayButton.topAnchor constant:-20],

        // OK button
        [self.okayButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.okayButton.bottomAnchor   constraintEqualToAnchor:self.view.bottomAnchor constant:-20],
    ]];

    // Fill the text
    NSAttributedString *attStr = [[NSAttributedString alloc]
        initWithString:_agreement
            attributes:@{
                NSFontAttributeName:            [NSFont userFixedPitchFontOfSize:12],
                NSForegroundColorAttributeName: [NSColor textColor]
            }];
    
    [self.textView setEditable:YES];
    [self.textView.textStorage setAttributedString:attStr];
    [self.textView checkTextInDocument:nil];
    [self.textView setEditable:NO];

    // Now size the textView to fit *all* of its content, so the scroll‐view can scroll.
    // Force the scroll‐view to layout so its contentSize is valid:
    [scroll layoutSubtreeIfNeeded];
    NSSize contentSize = scroll.contentSize;

    // collapse to minimal height so containerSize can reflow:
    self.textView.frame = NSMakeRect(0, 0, contentSize.width, 1);

    // allow infinite height:
    self.textView.textContainer.containerSize = NSMakeSize(contentSize.width, CGFLOAT_MAX);
    self.textView.textContainer.heightTracksTextView = NO;

    // force layout
    [self.textView.layoutManager ensureLayoutForTextContainer:self.textView.textContainer];

    // measure needed height
    NSRect used = [self.textView.layoutManager usedRectForTextContainer:self.textView.textContainer];

    // resize to fit
    self.textView.frame = NSMakeRect(0, 0, contentSize.width, used.size.height);
}

- (void)okPressed {
    [self.view.window.sheetParent endSheet:self.view.window returnCode:NSModalResponseOK];
}

@end

//
//  DownloadsViewController.m
//  decline
//
//  Created by Derek Scott on 7/8/25.
//

#import "DownloadsViewController.h"

@interface DownloadsViewController ()
@property (nonatomic,strong) NSButton     *clearButton;
@end

@implementation DownloadsViewController

- (void)loadView {
    // 1) Use a vibrancy background so it looks like Safari’s popover
    NSVisualEffectView *bg = [NSVisualEffectView new];
    bg.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    bg.material     = NSVisualEffectMaterialSidebar;  // light sidebar look
    bg.state        = NSVisualEffectStateActive;
    self.view       = bg;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 2) Header row: “Downloads” + “Clear”
    NSTextField *title = [NSTextField labelWithString:@"Downloads"];
    title.font = [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold];

    self.clearButton = [NSButton buttonWithTitle:@"Clear" target:self action:@selector(onClear:)];
    self.clearButton.bezelStyle = NSBezelStyleInline;

    NSStackView *header = [NSStackView stackViewWithViews:@[title, [NSView new], self.clearButton]];
    header.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    header.edgeInsets  = NSEdgeInsetsMake(8, 12, 4, 12);
    header.translatesAutoresizingMaskIntoConstraints = NO;

    // 3) Table of downloads
    self.tableView = [[NSTableView alloc] initWithFrame:NSZeroRect];
    self.tableView.delegate   = self;
    self.tableView.dataSource = self;
    self.tableView.headerView = nil;
    self.tableView.rowHeight  = 64;
    self.tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;

    // — one column for the whole custom cell
    NSTableColumn *col = [NSTableColumn new];
    col.identifier = @"download";
    col.title      = @"";
    [self.tableView addTableColumn:col];

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.documentView   = self.tableView;
    scroll.hasVerticalScroller = YES;
    scroll.backgroundColor    = NSColor.clearColor;
    scroll.drawsBackground    = NO;

    // 4) Stack the header & scroll in a vertical stack
    NSStackView *vstack = [NSStackView stackViewWithViews:@[header, scroll]];
    vstack.orientation = NSUserInterfaceLayoutOrientationVertical;
    vstack.edgeInsets  = NSEdgeInsetsMake(10,0,0,0);
    vstack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:vstack];

    // 5) Constraints
    [NSLayoutConstraint activateConstraints:@[
      [vstack.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor],
      [vstack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
      [vstack.topAnchor      constraintEqualToAnchor:self.view.topAnchor],
      [vstack.bottomAnchor   constraintEqualToAnchor:self.view.bottomAnchor],
      [vstack.widthAnchor   constraintEqualToConstant:300],
      [scroll.heightAnchor   constraintEqualToConstant:200],  // max height
    ]];
}

#pragma mark — Actions

- (void)onClear:(id)sender {
    // Your clear-all logic here…
    NSLog(@"Clear all downloads");
    
    [self.downloads removeAllObjects];
    [self.tableView reloadData];
}

#pragma mark — NSTableView DataSource & Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.downloads.count;
}

- (NSView*)tableView:(NSTableView*)tv viewForTableColumn:(NSTableColumn*)col row:(NSInteger)row {
    DownloadCellView *cell = [tv makeViewWithIdentifier:@"DownloadCell" owner:self];
    if (!cell) {
        cell = [[DownloadCellView alloc] initWithFrame:NSMakeRect(0,0,300,64)];
        cell.identifier = @"DownloadCell";

        // icon
        NSImageView *icon = [[NSImageView alloc] initWithFrame:NSMakeRect(0,8,48,48)];
        [cell addSubview:icon];
        cell.imageView = icon;

        // label
        NSTextField *lbl = [NSTextField labelWithString:@""];
        lbl.frame = NSMakeRect(42, 30, 200, 18);
        //lbl.frame = NSMakeRect(36, 15, 200, 18);
        [cell addSubview:lbl];
        cell.textField = lbl;

        // progress
        NSProgressIndicator *bar = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(42,22,200,4)];
        //NSProgressIndicator *bar = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(36,8,200,4)];
        bar.indeterminate = NO;
        [cell addSubview:bar];
        cell.progressIndicator = bar;
        
        cell.progressIndicator.controlSize = NSControlSizeSmall;
        cell.progressIndicator.minValue = 0.0;
        cell.progressIndicator.maxValue = 1.0;
        
        NSTextField *lbl2 = [NSTextField labelWithString:@""];
        lbl2.frame = NSMakeRect(42, 0, 200, 18);
        lbl2.textColor = [NSColor grayColor];
        lbl2.font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
        [cell addSubview:lbl2];
        cell.statusField = lbl2;

        // reveal button
        NSImage *revealicon = [NSImage imageWithSystemSymbolName:@"magnifyingglass.circle.fill" accessibilityDescription:@"Reveal"];
        [revealicon setTemplate:YES];
        
        NSButton *btn = [NSButton buttonWithTitle:@"" image:revealicon target:self action:@selector(onReveal:)];
        btn.bezelStyle = NSBezelStyleTexturedRounded;
        btn.bordered = NO;
        
        btn.frame = NSMakeRect(250, 18, 24,24);
        [cell addSubview:btn];
        cell.revealButton = btn;
    }

    NSDictionary *dl = self.downloads[row];
    cell.textField.stringValue = dl[@"name"];
    [cell.imageView    setImage:dl[@"icon"]];
    
    [cell.progressIndicator setDoubleValue:[dl[@"progress"] doubleValue]];
    
    if([dl[@"progress"] doubleValue] >= 1.0) {
        [cell.progressIndicator setHidden:YES];
        cell.statusField.frame = NSMakeRect(42,12,200,18);
    }
    
    else {
        [cell.progressIndicator setHidden:NO];
    }
        
    cell.statusField.stringValue = dl[@"status"];

    return cell;
}

#pragma mark — Reveal action

- (void)onReveal:(NSButton*)btn {
    NSInteger row = [self.tableView rowForView:btn];
    NSDictionary *dl = self.downloads[row];
    
    NSString *downloadsFolder = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) firstObject];
    
    // Create the full file path
    NSString *filePath = [downloadsFolder stringByAppendingPathComponent:dl[@"name"]];
    
    // Check if the file exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        // Reveal the file in Finder
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[NSURL fileURLWithPath:filePath]]];
    }
    
    else {
        NSLog(@"File does not exist at path: %@", filePath);
    }
}

@end

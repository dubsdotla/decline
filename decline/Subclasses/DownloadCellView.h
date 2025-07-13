//
//  DownloadCellView.h
//  decline
//
//  Created by Derek Scott on 7/8/25.
//

#import <Cocoa/Cocoa.h>

@interface DownloadCellView : NSTableCellView
@property (nonatomic, strong) NSProgressIndicator *progressIndicator;
@property (nonatomic, strong) NSTextField *statusField;
@property (nonatomic, strong) NSButton            *revealButton;
@end

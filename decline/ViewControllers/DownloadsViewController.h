//
//  DownloadsViewController.h
//  decline
//
//  Created by Derek Scott on 7/8/25.
//

#import <Cocoa/Cocoa.h>
#import "DownloadCellView.h"

@interface DownloadsViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>
/// Your model array of downloads. Each item should have at least:
/// - a file name (NSString)
/// - a progress (0.0–1.0)
/// - a state (downloading, finished, error, etc)
///
@property (nonatomic,strong) NSTableView  *tableView;
@property (nonatomic,strong) NSMutableArray<NSDictionary*> *downloads;
@end

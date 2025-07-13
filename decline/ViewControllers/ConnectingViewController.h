//
//  ConnectingViewController.h
//  decline
//
//  Created by Derek Scott on 6/27/25.
//

#import <Cocoa/Cocoa.h>

@interface ConnectingViewController : NSViewController

/// The message to display, e.g. “Connecting to foo.example.com…”
- (instancetype)initWithMessage:(NSString*)message;

/// Expose the progress indicator so you can start/stop it
@property (nonatomic, readonly) NSProgressIndicator *progressIndicator;

@end

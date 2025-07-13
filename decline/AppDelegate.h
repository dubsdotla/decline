//
//  AppDelegate.h
//  decline
//
//  Created by Derek Scott on 5/12/25.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"
#import "CustomTextFieldWithPopup.h"
#import "PreferencesWindowController.h"
#import "HotlineClient.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) PreferencesWindowController *preferencesWindowController;
@property (nonatomic) NSMutableArray<HotlineClient*> *clients;

- (void)newConnection;
- (void)removeClient:(NSUUID*)uuid;
- (void)tileAllWindows;
- (void)updateChatView;

@end

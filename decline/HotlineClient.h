//
//  HotlineClient.h
//  decline
//
//  Created by Derek Scott on 6/12/25.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <arpa/inet.h>
#import <CoreServices/CoreServices.h>

#import "AppSupport.h"
#import "Constants.h"
#import "CustomTextFieldWithPopup.h"
#import "NSAttributedString+RTFAdditions.h"
#import "NSColor+Hex.h"
#import "NSString+Utils.h"
#import "NSWorkspace+Icons.h"
#import "ThemedBackgroundView.h"
#import "UserIcons.h"

#import "PreferencesWindowController.h"
#import "ChangeNickIconViewController.h"
#import "SendBroadcastViewController.h"
#import "SendNewsPostViewController.h"
#import "ShowAgreementViewController.h"

#import "ConnectingViewController.h"
#import "DownloadsViewController.h"

#import "FileTransferManager.h"
#import "UserTransactions.h"

@interface HotlineClient : NSObject <NSStreamDelegate, NSToolbarDelegate, NSToolbarItemValidation, NSTableViewDataSource, NSTableViewDelegate, NSComboBoxDelegate, NSWindowDelegate, FileTransferManagerDelegate>

// uuid
@property (nonatomic, strong) NSUUID *uuid;

// state
@property (assign) ClientUIState uiState;

// window
@property (strong) NSWindow *connectionWindow;
@property (strong) NSWindow *window;
@property (strong) NSWindow *nickSheetWindow;
@property (strong) NSWindow *broadcastSheetWindow;
@property (strong) NSWindow *newsPostSheetWindow;
@property (strong) NSWindow *agreementSheetWindow;
@property (assign) NSRect connectWindowFrame;

@property (strong) NSWindow *connectingSheetWindow;

// Connect UI
@property (nonatomic,strong) NSMutableArray<NSString*> *servers;

@property (strong) CustomTextFieldWithPopup *serverField;
@property (strong) NSTextField *loginField, *nickField, *iconField;
@property (strong) NSMenu *bookmarkMenu;
@property (strong) NSSecureTextField *passwordField;
@property (strong) NSButton *connectButton;

// Chat UI
@property (strong) NSSplitView  *splitView;
@property (strong) NSScrollView *chatScrollView;
@property (strong) NSTextView   *chatTextView;
@property (strong) NSTableView  *userListView;
@property (strong) NSTextField  *messageField;
@property (strong) NSButton     *sendButton;

// News UI
@property (strong) NSScrollView *newsScrollView;
@property (nonatomic, strong) NSTextView *newsTextView;

//Files UI
@property (strong) NSTableView  *filesTableView;
@property (strong) NSPathControl  *pathControl;

@property (strong) NSInputStream  *inputStream;
@property (strong) NSOutputStream *outputStream;
@property (assign) NSInteger       handshakeState;   // 0=proto,1=login,2=setUser,3=ready

@property (nonatomic, strong) NSMutableArray<FileTransferManager*> *fileTransfers;
@property (strong) UserTransactions  *transactions;

@property (nonatomic,strong) NSPopover *downloadsPopover;
@property (nonatomic,strong) NSMutableArray<NSDictionary*> *downloads;
@property (nonatomic,strong) DownloadsViewController *downloadsVC;
@property (strong) NSButton     *downloadButton;

@property (nonatomic, strong) NSMutableAttributedString *cachedChatContents;

@property (nonatomic,strong) NSMutableArray<NSDictionary*> *users;
@property (assign) BOOL processUserListCalled;
@property (assign) BOOL hasReceivedInitialUserList;
@property (nonatomic, strong) NSTimer  *userListTimer;

@property (assign) BOOL processNewsCalled;
@property (assign) BOOL hasReceivedInitialNews;
@property (nonatomic, strong) NSMutableArray<NSString*> *newsItems;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<NSDictionary *> *> *directoryCache;
@property (nonatomic, strong) NSMutableArray<NSDictionary*> *filesModel;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *downloadFilename;


@property (nonatomic, strong) NSString *serverAgreementMessage;
@property (nonatomic) BOOL showAgreementMessage;

@property (nonatomic, strong) NSString *serverAddress;
@property (nonatomic) int serverPort;
@property (nonatomic) BOOL isReconnecting;

@property (nonatomic, strong) NSThread *networkThread;

@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, strong) NSString *login;
@property (nonatomic, strong) NSString *password;
@property (nonatomic) uint32_t iconNumber;
@property (nonatomic) uint16_t socket;

@property (nonatomic)     uint64_t privs;
@property (nonatomic, strong) NSArray<NSString*> *currentUserPrivs;

@property (nonatomic) BOOL awaitingOpenUser;
@property (nonatomic, strong) NSString *openUserLogin;
@property (nonatomic, strong) NSString *openUserPassword;
@property (nonatomic)     uint64_t openUserPrivs;
@property (nonatomic, strong) NSString *openUserNick;

@property (nonatomic) BOOL canDownloadFile;
@property (nonatomic) BOOL canUploadFile;
@property (nonatomic) BOOL canDownloadFolder;
@property (nonatomic) BOOL canUploadFolder;
@property (nonatomic) BOOL canReadNews;
@property (nonatomic) BOOL canPostNews;
@property (nonatomic) BOOL canSendBroadcast;
@property (nonatomic) BOOL canSendMessage;

@property (nonatomic, copy) NSString *lastOpenLogin;

@property (nonatomic) BOOL awaitingModifyReply;

@property (nonatomic) uint16_t version;
@property (nonatomic) uint16_t bannerID;
@property (nonatomic, copy) NSString *serverName;

- (void)updateChatView;

@end

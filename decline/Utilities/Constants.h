//
//  Constants.h
//  decline
//
//  Created by Derek Scott on 6/12/25.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ClientUIState) {
    ClientUIStateConnect,
    ClientUIStateChat,
    ClientUIStateNews,
    ClientUIStateFiles
};

typedef NS_ENUM(NSInteger, HandshakeState) {
    HandshakeStateWaitingForHello = 0,
    HandshakeStateWaitingForLoginReply,
    HandshakeStateConnected
};

typedef NS_ENUM(NSInteger, SpecialNotice) {
    SpecialNoticeJoinLeave,
    SpecialNoticeNameChange,
    SpecialNoticePrivateMessage
};

static const CGFloat kConnectWidth  = 325;
static const CGFloat kConnectHeight = 190;
static const CGFloat kChatWidth     = 900;
static const CGFloat kChatHeight    = 600;

/// Full list of general privileges by bit index (0–37).
static NSString * const PrivNames[] = {
    [0]  = @"Delete File",
    [1]  = @"Upload File",
    [2]  = @"Download File",
    [3]  = @"Rename File",
    [4]  = @"Move File",
    [5]  = @"Create Folder",
    [6]  = @"Delete Folder",
    [7]  = @"Rename Folder",
    [8]  = @"Move Folder",
    [9]  = @"Read Chat",
    [10] = @"Send Chat",
    [11] = @"Open Chat",
    [12] = @"Close Chat",
    [13] = @"Show in List",
    [14] = @"Create User",
    [15] = @"Delete User",
    [16] = @"Open User",
    [17] = @"Modify User",
    [18] = @"Change Own Password",
    [19] = @"Send Private Message",
    [20] = @"News Read Article",
    [21] = @"News Post Article",
    [22] = @"Disconnect User",
    [23] = @"Cannot be Disconnected",
    [24] = @"Get Client Info",
    [25] = @"Upload Anywhere",
    [26] = @"Any Name",
    [27] = @"No Agreement",
    [28] = @"Set File Comment",
    [29] = @"Set Folder Comment",
    [30] = @"View Drop Boxes",
    [31] = @"Make Alias",
    [32] = @"Send Broadcast",
    [33] = @"News Delete Article",
    [34] = @"News Create Category",
    [35] = @"News Delete Category",
    [36] = @"News Create Folder",
    [37] = @"News Delete Folder",
    [38] = @"Upload Folder",
    [39] = @"Download Folder",
    [40] = @"Send Message",
    [41] = @"Unimplemented 41",
    [42] = @"Unimplemented 42",
    [43] = @"Unimplemented 43",
    [44] = @"Unimplemented 44",
    [45] = @"Unimplemented 45",
    [46] = @"Unimplemented 46",
    [47] = @"Unimplemented 47",
    [48] = @"Unimplemented 48",
    [49] = @"Unimplemented 49",
    [50] = @"Unimplemented 50",
    [51] = @"Unimplemented 51",
    [52] = @"Unimplemented 52",
    [53] = @"Unimplemented 53",
    [54] = @"Unimplemented 54",
    [55] = @"Unimplemented 55",
    [56] = @"Unimplemented 56",
    [57] = @"Unimplemented 57",
    [58] = @"Unimplemented 58",
    [59] = @"Unimplemented 59",
    [60] = @"Unimplemented 60",
    [61] = @"Unimplemented 61",
    [62] = @"Unimplemented 62",
    [63] = @"Unimplemented 63",

    // bits 41–63 currently unused
};

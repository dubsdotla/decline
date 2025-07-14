//
//  UserTransactions.m
//  decline
//
//  Created by Derek Scott on 6/17/25.
//

#import "UserTransactions.h"

@interface NSMutableData (HotlinePayload)
/// Append one “(OID, length, payload-bytes)” triplet to this NSMutableData.
- (void)hl_appendObjectWithOID:(uint16_t)oid bigEndianData:(NSData*)d;
@end

@implementation NSMutableData (HotlinePayload)
- (void)hl_appendObjectWithOID:(uint16_t)oid bigEndianData:(NSData*)d {
    uint16_t oidBE = htons(oid);
    uint16_t lenBE = htons((uint16_t)d.length);
    [self appendBytes:&oidBE length:2];
    [self appendBytes:&lenBE length:2];
    [self appendData:d];
}

NSData * _Nonnull HL_BE16(uint16_t v) {
    uint16_t be = htons(v);
    return [NSData dataWithBytes:&be length:2];
}
NSData * _Nonnull HL_BE32(uint32_t v) {
    uint32_t be = htonl(v);
    return [NSData dataWithBytes:&be length:4];
}

@end

@implementation UserTransactions

- (instancetype)init {
    
    if (self = [super init]) {
    
        self.txID = 1; //Valid transaction id's are 1 or greater;
        self.chatWindowID = 0;
    }
    
    return self;
}

- (uint32_t)getNextTxID {
    return self.txID++;
}

#pragma mark – Helper

- (NSData*)packetWithType:(uint16_t)type
                  payload:(NSData*)payload
{
    uint8_t  flags = 0, rep = 0;
    uint16_t typeBE = htons(type);
    uint32_t txidBE = htonl([self getNextTxID]);
    uint32_t errBE  = htonl(0);
    uint32_t sizeBE = htonl((uint32_t)payload.length);

    NSMutableData *pkt = [NSMutableData data];
    [pkt appendBytes:&flags  length:1];
    [pkt appendBytes:&rep    length:1];
    [pkt appendBytes:&typeBE length:2];
    [pkt appendBytes:&txidBE length:4];
    [pkt appendBytes:&errBE  length:4];
    [pkt appendBytes:&sizeBE length:4];
    [pkt appendBytes:&sizeBE length:4];
    [pkt appendData:payload];
    return pkt;
}

- (void)sendLoginTransactionWithNick:(NSString *)nickstring
                             iconNum:(uint32_t)iconnumber
                              Login:(NSString *)loginstring
                                Pass:(NSString *)passstring
                          forStream:(NSOutputStream *)stream
{
    // Build the payload: five objects (nick + login + password + client version)
    
    NSString *nick;
    NSString *login;
    NSString *pass;
    uint16_t clientVersion = 191;    // ← your version #
    
    if(nickstring.length > 0) {
        nick = nickstring;
    }
    
    else {
        nick = @"decline n00b";
    }
    
    if(loginstring.length > 0) {
        login = loginstring;
    }
    
    else {
        login = @"guest";
    }
    
    if(passstring.length > 0) {
        pass = passstring;
    }
    
    else {
        pass = @"";
    }
        
    NSMutableData *payload = [NSMutableData data];
    
    [payload appendData:HL_BE16(5)];
    [payload hl_appendObjectWithOID:105 bigEndianData:[NSData eorEncodeString:login.UTF8String]];
    [payload hl_appendObjectWithOID:106 bigEndianData:[NSData eorEncodeString:pass.UTF8String]];
    [payload hl_appendObjectWithOID:102 bigEndianData:[nickstring dataUsingEncoding:NSUTF8StringEncoding]];
    [payload hl_appendObjectWithOID:104 bigEndianData:HL_BE32(iconnumber)];
    [payload hl_appendObjectWithOID:160 bigEndianData:HL_BE16(clientVersion)];

    NSData *packet = [self packetWithType:107 payload:payload];

    NSLog(@"[DEBUG] → TX107 Login (with version=%u)", clientVersion);
    [stream write:packet.bytes maxLength:packet.length];
}

//Original
- (void)sendSetUserInfoTransactionWithNick:(NSString *)nickstring iconNum:(uint32_t)iconnumber forStream:(NSOutputStream *) stream {
    // Build the payload: two objects (nick + icon number)
    
    NSMutableData *payload = [NSMutableData data];
    
    [payload appendData:HL_BE16(2)];
    [payload hl_appendObjectWithOID:102 bigEndianData:[nickstring dataUsingEncoding:NSUTF8StringEncoding]];
    [payload hl_appendObjectWithOID:104 bigEndianData:HL_BE32(iconnumber)];
    
    NSData *packet = [self packetWithType:304 payload:payload];

    NSLog(@"[DEBUG] → TX304 SetUserInfo → nick=%@ icon='%u'", nickstring, iconnumber);
    [stream write:packet.bytes maxLength:packet.length];
}

- (void)sendGetUserListTransactionForStream:(NSOutputStream *)stream {
    // Build the payload: zero objects
    
    NSMutableData *payload = [NSMutableData data];
    
    [payload appendData:HL_BE16(0)];
    
    NSData *packet = [self packetWithType:300 payload:payload];

    NSLog(@"[DEBUG] → TX300: GetUserNameList");
    [stream write:packet.bytes maxLength:packet.length];
}

- (void)sendDownloadBannerTransactionForStream:(NSOutputStream *)stream {
    NSString *type = @"JPEG";
    
    NSMutableData *payload = [NSMutableData data];
    
    [payload appendData:HL_BE16(1)];
    [payload hl_appendObjectWithOID:152 bigEndianData:[type dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData *packet = [self packetWithType:212 payload:payload];
    
    NSLog(@"[DEBUG] → TX212: DownloadBanner");
    [stream write:packet.bytes maxLength:packet.length];
}

- (void)sendAgreeTransactionWithLogin:(NSString *)loginstring IconNum:(uint32_t)iconnumber forStream:(NSOutputStream *)stream {
    NSString *agreestring = @"I agree!";
    
    NSMutableData *payload = [NSMutableData data];
    
    [payload appendData:HL_BE16(4)];
    [payload hl_appendObjectWithOID:102 bigEndianData:[loginstring dataUsingEncoding:NSUTF8StringEncoding]];
    [payload hl_appendObjectWithOID:104 bigEndianData:HL_BE32(iconnumber)];
    [payload hl_appendObjectWithOID:113 bigEndianData:HL_BE16(4)]; //Options (OID 113) — only Automatic response = 4 (options bitmask: bit 2^2 = 4)
    [payload hl_appendObjectWithOID:215 bigEndianData:[agreestring dataUsingEncoding:NSUTF8StringEncoding]]; //Auto-response string (OID 215)

    NSData *packet = [self packetWithType:121 payload:payload];

    // Debug & send
    NSLog(@"[DEBUG] → TX121: Agree + Auto-response (I agree!) totalBytes=%lu",
          (unsigned long)packet.length);
    
    [stream write:packet.bytes maxLength:packet.length];
}

- (void)sendChatTransaction:(NSString*)text asEmote:(BOOL)asEmote forStream:(NSOutputStream *)stream {
    // Build the payload: three objects (param + chat text + windowID)
    
    NSMutableData *payload = [NSMutableData data];
    
    [payload appendData:HL_BE16(3)];
    [payload hl_appendObjectWithOID:109 bigEndianData:HL_BE16(asEmote ? 1 : 0)];
    [payload hl_appendObjectWithOID:101 bigEndianData:[text dataUsingEncoding:NSUTF8StringEncoding]];
    [payload hl_appendObjectWithOID:114 bigEndianData:HL_BE32(self.chatWindowID)];

    NSData *packet = [self packetWithType:105 payload:payload];

    NSLog(@"[DEBUG] → TX105 Chat: %@", text);
    [stream write:packet.bytes maxLength:packet.length];
}

- (void)sendPrivateMessageTransaction:(NSString *)message toSocket:(uint16_t)socketID forStream:(NSOutputStream *)stream {
    // Build the payload: two objects (socket ID + private message)
    
    NSMutableData *payload = [NSMutableData data];
    
    [payload appendData:HL_BE16(2)];
    [payload hl_appendObjectWithOID:103 bigEndianData:HL_BE16(socketID)];
    [payload hl_appendObjectWithOID:101 bigEndianData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData *packet = [self packetWithType:108 payload:payload];

    NSLog(@"[DEBUG] → TX108 Private → socket=%u msg='%@'", socketID, message);
    [stream write:packet.bytes maxLength:packet.length];
}

- (void)sendBroadcastTransaction:(NSString*)message forStream:(NSOutputStream *)stream {
    // Build the payload: one object (broadcast message)

    NSMutableData *payload = [NSMutableData data];
    
    [payload appendData:HL_BE16(1)];
    [payload hl_appendObjectWithOID:101 bigEndianData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData *packet = [self packetWithType:355 payload:payload];

    NSLog(@"[DEBUG] → TX355 Broadcast:“%@”", message);
    [stream write:packet.bytes maxLength:packet.length];
}

- (void)sendGetNewsTransactionForStream:(NSOutputStream *)stream {
    // Build the payload: zero objects
    
    NSMutableData *payload = [NSMutableData data];
    
    [payload appendData:HL_BE16(0)];
    
    NSData *packet = [self packetWithType:101 payload:payload];

    NSLog(@"[DEBUG] → TX101: GetNews");
    [stream write:packet.bytes maxLength:packet.length];
}

- (void)sendPostNewsTransactionWithPost:(NSString*)text forStream:(NSOutputStream *)stream {
    // Build the payload: one object (news message)

    NSMutableData *payload = [NSMutableData data];
    
    [payload appendData:HL_BE16(1)];
    [payload hl_appendObjectWithOID:101 bigEndianData:[text dataUsingEncoding:NSUTF8StringEncoding]];

    NSData *packet = [self packetWithType:103 payload:payload];

    NSLog(@"[DEBUG] → TX103 PostNews: “%@”", text);
    [stream write:packet.bytes maxLength:packet.length];
}

- (void)sendGetFileNameListTransactionWithFolder:(nullable NSString*)folderPath forStream:(NSOutputStream*)stream
{
    // Build the raw “file‐path” blob (might be zero‐length if no folderPath)
    NSData *pathBlob = [NSData dataForFilePath:folderPath];
    
    NSMutableData *payload = [NSMutableData data];
    
    if(pathBlob.length > 0) {
        [payload appendData:HL_BE16(1)];
        [payload hl_appendObjectWithOID:202 bigEndianData:pathBlob];
    }
    
    else {
        [payload appendData:HL_BE16(0)];
    }
    
    NSLog(@"[DEBUG] → TX200 GetFileNameList: “%@”",
          folderPath ?: @"<root>");
    
    NSData *packet = [self packetWithType:200 payload:payload];
    [stream write:packet.bytes maxLength:packet.length];
}

#pragma mark – Download File (TX-202)

- (void)sendDownloadFileTransactionWithName:(NSString*)fileName inFolder:(nullable NSString*)path stream:(NSOutputStream*)stream
{
    // object count = 2 (filename + filepath)
    
    NSData *pathBlob = [NSData dataForFilePath:path];
    
    NSMutableData *payload = [NSMutableData data];
    
    [payload appendData:HL_BE16(2)];
    [payload hl_appendObjectWithOID:201 bigEndianData:[fileName dataUsingEncoding:NSUTF8StringEncoding]];
    [payload hl_appendObjectWithOID:202 bigEndianData:pathBlob];
    
    NSLog(@"[DEBUG] → TX202 DownloadFile: “%@ from path %@”", fileName, path);
    
    NSData *packet = [self packetWithType:202 payload:payload];
    [stream write:packet.bytes maxLength:packet.length];
}

#pragma mark – Get File Info (TX-206)

- (void)sendGetFileInfoTransactionForName:(NSString*)fileName inFolder:(nullable NSString*)path stream:(NSOutputStream*)stream
{
    NSData *pathBlob = [NSData dataForFilePath:path];
    
    NSMutableData *payload = [NSMutableData data];
    
    //if path send filename and path, else just send filename
    if(pathBlob.length > 0) {
        [payload appendData:HL_BE16(2)];
        [payload hl_appendObjectWithOID:201 bigEndianData:[fileName dataUsingEncoding:NSUTF8StringEncoding]];
        [payload hl_appendObjectWithOID:202 bigEndianData:pathBlob];
    }
    
    else {
        [payload appendData:HL_BE16(1)];
        [payload hl_appendObjectWithOID:201 bigEndianData:[fileName dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSLog(@"[DEBUG] → TX206 GetFileInfo: “%@ from path %@”", fileName, path);

    NSData *packet = [self packetWithType:206 payload:payload];
    [stream write:packet.bytes maxLength:packet.length];
}

- (void)sendOpenUserTransaction:(NSString*)login forStream:(NSOutputStream *)stream {
    
}

- (void)sendModifyUserPrivilegesWithMask:(uint64_t)newPrivMask forStream:(NSOutputStream *)stream {
    
}

@end

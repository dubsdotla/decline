//
//  UserTransactions.h
//  decline
//
//  Created by Derek Scott on 6/17/25.
//

#import <Foundation/Foundation.h>
#import "NSData+Utils.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserTransactions : NSObject
@property (assign) uint32_t txID;
@property (assign) uint32_t chatWindowID;

- (uint32_t)getNextTxID;

- (void)sendLoginTransactionWithNick:(NSString *)nickstring iconNum:(uint32_t)iconnumber Login:(NSString *)loginstring Pass:(NSString *)passstring forStream:(NSOutputStream *) stream;
- (void)sendSetUserInfoTransactionWithNick:(NSString *)nickstring iconNum:(uint32_t)iconnumber forStream:(NSOutputStream *) stream;
- (void)sendGetUserListTransactionForStream:(NSOutputStream *)stream;
- (void)sendDownloadBannerTransactionForStream:(NSOutputStream *)stream;
- (void)sendAgreeTransactionWithLogin:(NSString *)loginstring IconNum:(uint32_t)iconnumber forStream:(NSOutputStream *)stream;
- (void)sendChatTransaction:(NSString*)text asEmote:(BOOL)asEmote forStream:(NSOutputStream *)stream;
- (void)sendPrivateMessageTransaction:(NSString *)message toSocket:(uint16_t)socketID forStream:(NSOutputStream *)stream;
- (void)sendBroadcastTransaction:(NSString*)message forStream:(NSOutputStream *)stream;
- (void)sendGetNewsTransactionForStream:(NSOutputStream *)stream;
- (void)sendPostNewsTransactionWithPost:(NSString*)text forStream:(NSOutputStream *)stream;
- (void)sendGetFileNameListTransactionWithFolder:(nullable NSString*)folderPath forStream:(NSOutputStream *)stream;
- (void)sendDownloadFileTransactionWithName:(NSString*)fileName inFolder:(nullable NSString*)path stream:(NSOutputStream*)stream;
- (void)sendGetFileInfoTransactionForName:(NSString*)fileName inFolder:(nullable NSString*)path stream:(NSOutputStream*)stream;
- (void)sendOpenUserTransaction:(NSString*)login forStream:(NSOutputStream *)stream;
- (void)sendModifyUserPrivilegesWithMask:(uint64_t)newPrivMask forStream:(NSOutputStream *)stream;
@end

NS_ASSUME_NONNULL_END

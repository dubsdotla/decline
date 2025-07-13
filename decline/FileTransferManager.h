//
//  FileTransferManager.h
//  decline
//
//  Created by Derek Scott on 6/29/25.
//

#import <Foundation/Foundation.h>
#import "UserTransactions.h"

@class FileTransferManager;

@protocol FileTransferManagerDelegate <NSObject>
@optional
/// called whenever a chunk of data arrives
- (void)fileTransferManager:(FileTransferManager*)mgr didReceiveBytes:(NSUInteger)bytesRead;

/// called once the transfer is complete (all bytes in)
- (void)fileTransferManagerDidFinishTransfer:(FileTransferManager*)mgr;
@end

@interface FileTransferManager : NSObject <NSStreamDelegate>

@property (nonatomic, weak) id<FileTransferManagerDelegate> delegate;
@property (nonatomic, weak) UserTransactions  *txProvider;

/// host/port of the file‐transfer socket
@property (nonatomic, readonly) NSString  *host;
@property (nonatomic) uint16_t   port;

/// the transfer-ID you were given by the control channel
@property (nonatomic, readonly) uint32_t   transferID;

/// name + total size of the file we’re downloading
@property (nonatomic, readonly) NSString  *fileName;
@property (nonatomic, readonly) uint32_t   fileSize;

/// the raw bytes we’ve received so far
@property (nonatomic, readonly) NSMutableData *receivedData;

/// starting TX-ID to use when wrapping TX108
@property (nonatomic        ) uint32_t   nextTxID;

/// designated initializer
- (instancetype)initWithHost:(NSString*)host
                        port:(uint16_t)port
                  transferID:(uint32_t)xferID
                    fileName:(NSString*)fileName
                    fileSize:(uint32_t)fileSize
                  txProvider:(UserTransactions*)txProvider;

/// kicks off the secondary “data” connection
- (void)openConnection;

@end

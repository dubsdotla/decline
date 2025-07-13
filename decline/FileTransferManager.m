//
//  FileTransferManager.m
//  decline
//
//  Created by Derek Scott on 6/29/25.
//

#import "FileTransferManager.h"
#import <netinet/in.h>

@interface FileTransferManager () <NSStreamDelegate>
@property (nonatomic, strong) NSInputStream   *inputStream;
@property (nonatomic, strong) NSOutputStream  *outputStream;
@property (nonatomic, readwrite) NSMutableData *receivedData;
@end

@implementation FileTransferManager {
  BOOL _didSendHTXF;
}

- (instancetype)initWithHost:(NSString*)host
                        port:(uint16_t)port
                  transferID:(uint32_t)xferID
                    fileName:(NSString*)fileName
                    fileSize:(uint32_t)fileSize
                  txProvider:(UserTransactions*)txProvider
{
    if ((self = [super init])) {
        _host         = [host copy];
        _port         = port + 1;
        _transferID   = xferID;
        _fileName     = [fileName copy];
        _fileSize     = fileSize;
        _receivedData = [NSMutableData dataWithCapacity:fileSize];
    }
    return self;
}

- (void)openConnection {
    NSInputStream  *inStream;
    NSOutputStream *outStream;

    [NSStream getStreamsToHostWithName:self.host
                                  port:self.port
                           inputStream:&inStream
                          outputStream:&outStream];

    self.inputStream  = inStream;
    self.outputStream = outStream;

    self.inputStream.delegate  = self;
    self.outputStream.delegate = self;

    // Schedule in the common run-loop mode so we see events even during UI tracking
    [inStream  scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [outStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

    [inStream  open];
    [outStream open];
}

#pragma mark – NSStreamDelegate

- (void)stream:(NSStream*)aStream handleEvent:(NSStreamEvent)event {
    switch(event) {
      case NSStreamEventOpenCompleted:
        NSLog(@"[FT] %@ stream opened",
              (aStream == self.inputStream)? @"Input":@"Output");
        break;

      case NSStreamEventHasSpaceAvailable:
        if (aStream == self.outputStream && !_didSendHTXF) {
            _didSendHTXF = YES;
            [self sendHTXFHandshake];
        }
        break;

      case NSStreamEventHasBytesAvailable: {
        uint8_t buf[4096];
        NSInteger n = [self.inputStream read:buf maxLength:sizeof(buf)];
        if (n>0) {
          [self.receivedData appendBytes:buf length:n];
          NSLog(@"[FT] got %ld bytes (total %lu)",
                n, (unsigned long)self.receivedData.length);
            
            [self.delegate fileTransferManager:self didReceiveBytes:buf[n]];
            
            if(self.receivedData.length == self.fileSize) {
                NSLog(@"Received all file data for %@", self.fileName);
                
                [self saveReceivedFileToDownloads];
                [self.delegate fileTransferManagerDidFinishTransfer:self];
            }
            
        }
        break;
      }

      case NSStreamEventErrorOccurred:
        NSLog(@"[FT] %@ stream error: %@",
              (aStream==self.inputStream)? @"Input":@"Output",
              aStream.streamError);
        break;

      case NSStreamEventEndEncountered:
        NSLog(@"[FT] %@ stream closed by peer",
              (aStream==self.inputStream)? @"Input":@"Output");
        [aStream close];
            
        [self saveReceivedFileToDownloads];
        [self.delegate fileTransferManagerDidFinishTransfer:self];
            
        break;

      default:
        break;
    }
}

// send the 16-byte HTXF handshake
- (void)sendHTXFHandshake {
    NSMutableData *h = [NSMutableData dataWithCapacity:16];
    [h appendData:[@"HTXF" dataUsingEncoding:NSASCIIStringEncoding]];

    uint32_t tidBE = htonl(self.transferID);
    [h appendBytes:&tidBE length:4];

    uint32_t z = 0;
    [h appendBytes:&z length:4];
    [h appendBytes:&z length:4];

    NSLog(@"[FT] → HTXF handshake id=%u (%lu bytes)",
          self.transferID, (unsigned long)h.length);

    NSInteger wrote = [self.outputStream write:h.bytes maxLength:h.length];
    if (wrote < 0) {
        NSLog(@"[FT][ERROR] writing HTXF: %@", self.outputStream.streamError);
    }
}

- (void)saveReceivedFileToDownloads {
    NSData *all = self.receivedData;
    const uint8_t *buf = all.bytes;
    NSUInteger      p   = 0;
    NSUInteger      L   = all.length;
    
    // 1)––– flat file header (“FILP”) –––
    if (p + 4 > L) return;
    NSString *magic = [[NSString alloc] initWithBytes:buf + p length:4 encoding:NSASCIIStringEncoding];
    p += 4;
    if (![magic isEqualToString:@"FILP"]) {
        NSLog(@"[FT][ERROR] bad FILP header: %@", magic);
        return;
    }
    // version (2 bytes) + RSV-16 bytes
    p += 2 + 16;
    // fork count (2 bytes)
    if (p + 2 > L) return;
    uint16_t forkCount = CFSwapInt16BigToHost(*(uint16_t*)(buf + p));
    p += 2;
    
    NSData *dataForkContents = nil;
    
    // 2)––– iterate each fork –––
    for (uint16_t i = 0; i < forkCount; i++) {
        if (p + 16 > L) break;  // need at least type(4)+comp(4)+rsvd(4)+size(4)
        
        // fork type
        NSString *forkType = [[NSString alloc] initWithBytes:buf + p length:4 encoding:NSASCIIStringEncoding];
        p += 4;
        // compression type (skip)
        p += 4;
        // RSV-4
        p += 4;
        // data size
        uint32_t forkSize = CFSwapInt32BigToHost(*(uint32_t*)(buf + p));
        p += 4;
        
        if (p + forkSize > L) break;
        
        if ([forkType isEqualToString:@"DATA"]) {
            // grab the DATA fork
            dataForkContents = [NSData dataWithBytes:buf + p length:forkSize];
            break;
        }
        
        // otherwise skip over this fork’s contents
        p += forkSize;
    }
    
    if (!dataForkContents) {
        NSLog(@"[FT][ERROR] no DATA fork found (got %lu bytes)", (unsigned long)L);
        return;
    }
    
    // 3)––– write DATA to disk in ~/Downloads/<fileName> –––
    NSURL *downloads = [[[NSFileManager defaultManager]
                          URLsForDirectory:NSDownloadsDirectory
                          inDomains:NSUserDomainMask] firstObject];
    NSURL *outURL = [downloads URLByAppendingPathComponent:self.fileName];
    
    NSError *err;
    if ([dataForkContents writeToURL:outURL options:NSDataWritingAtomic error:&err]) {
        NSLog(@"[FT] Wrote file to %@", outURL.path);
    } else {
        NSLog(@"[FT][ERROR] couldn’t write file: %@", err);
    }
}

@end

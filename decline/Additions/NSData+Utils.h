//
//  NSData+Utils.h
//  decline
//
//  Created by Derek Scott on 7/5/25.
//

#import <Cocoa/Cocoa.h>

@interface NSData (Utils)

+ (NSData * _Nullable)eorEncodeString:(const char * _Nonnull)s;
+ (NSData * _Nullable)dataForFilePath:(nullable NSString*)folderPath;

@end

//
//  ApplicationSupport.m
//  decline
//
//  Created by Derek Scott on 6/2/25.
//
#import "AppSupport.h"

@implementation AppSupport

+ (NSURL *)chatsURL {
    NSArray<NSURL *> *urls = [[NSFileManager defaultManager]
                              URLsForDirectory:NSApplicationSupportDirectory
                              inDomains:NSUserDomainMask];
    NSURL *baseAppSupport = urls.firstObject;
    
    // e.g. ~/Library/Application Support
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSURL *appSupportURL = [baseAppSupport URLByAppendingPathComponent:bundleID isDirectory:YES];
    NSURL *chatsURL = [appSupportURL URLByAppendingPathComponent:@"Chats"];
    
    NSError *createError = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:chatsURL.path]) {
        [[NSFileManager defaultManager] createDirectoryAtURL:chatsURL
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&createError];
        
        if(createError) {
            NSLog(@"Failed to create directory %@: %@", chatsURL.path, createError);
            return nil;
        }
    }
    
    return chatsURL;
}

@end

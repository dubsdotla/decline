//
//  UserIcons.m
//  decline
//
//  Created by Derek Scott on 6/16/25.
//

#import "UserIcons.h"

@implementation UserIcons

+ (NSDictionary *)standardUserIconsDict {
    NSString *iconsDir = [[NSBundle mainBundle] resourcePath];
    NSError *err = nil;
    NSArray<NSString*> *allFiles = [[NSFileManager defaultManager]
                                    contentsOfDirectoryAtPath:iconsDir
                                    error:&err];
    if (!allFiles) {
        NSLog(@"Error reading User Icons folder: %@", err);
        return nil;
    }
    
    // Filter to only “number.prefix.png” names
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9]+(\\..+)?\\.png$"];
    NSArray<NSString*> *iconFileNames =
    [allFiles filteredArrayUsingPredicate:predicate];
    
    // Build a dictionary: { @"1" : @"1.foo.png", @"20" : @"20.bar.png", … }
    NSMutableDictionary<NSString*, NSString*> *iconsByPrefix = [NSMutableDictionary dictionary];
    for (NSString *fileName in iconFileNames) {
        // split at the first “.”
        NSString *prefix = [[fileName componentsSeparatedByString:@"."] firstObject];
        if (prefix.length > 0) {
            iconsByPrefix[prefix] = fileName;
        }
    }
    
    // (Optional) Make it immutable
    return [iconsByPrefix copy];
    
    // iconsDict now maps @"1" → @"1.foo.png", etc.
    //NSLog(@"Icons by prefix: %@", self.iconFilenamesDict);
}

@end

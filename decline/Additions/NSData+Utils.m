//
//  NSData+Utils.m
//  decline
//
//  Created by Derek Scott on 7/5/25.
//

#import "NSData+Utils.h"

@implementation NSData (Utils)

+ (NSData*)eorEncodeString:(const char*)s {
    size_t count = strlen(s);
    NSMutableData *d = [NSMutableData dataWithCapacity:count];
    for (size_t i = 0; i < count; i++) {
        uint8_t e = ((uint8_t)s[i]) ^ 0xFF;
        [d appendBytes:&e length:1];
    }
    return d;
}

+ (NSData*)dataForFilePath:(nullable NSString*)folderPath {
    NSArray<NSString*> *parts = folderPath.length
      ? [folderPath componentsSeparatedByString:@"/"]
      : @[];
    NSMutableArray<NSString*> *levels = [NSMutableArray array];
    for (NSString *p in parts) if (p.length) [levels addObject:p];

    NSMutableData *d = [NSMutableData data];
    uint16_t lvlCountBE = htons((uint16_t)levels.count);
    [d appendBytes:&lvlCountBE length:2];

    for (NSString *lvl in levels) {
        uint16_t zero = 0;
        [d appendBytes:&zero length:2];

        NSData *nm = [lvl dataUsingEncoding:NSMacOSRomanStringEncoding
                          allowLossyConversion:NO]
                  ?: [lvl dataUsingEncoding:NSUTF8StringEncoding];
        uint8_t L = (uint8_t)nm.length;
        [d appendBytes:&L length:1];
        [d appendData:nm];
    }

    return d;
}

@end

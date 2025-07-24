//
//  NSString+Utils.m
//  decline
//
//  Created by Derek Scott on 7/5/25.
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

+ (NSString *)hexStringFromData:(NSData *)data {
    const unsigned char *ptr = data.bytes;
    NSMutableString *out = [NSMutableString stringWithCapacity:data.length * 2];
    for (NSUInteger i = 0; i < data.length; i++) {
        [out appendFormat:@"%02x ", ptr[i]];
    }
    return out;
}

+ (NSString *)autoDecodeStringWithBytes:(NSData *)bytes {
    NSString *decoded = nil;
    BOOL lossy = NO;
    NSDictionary *opts = @{
        NSStringEncodingDetectionSuggestedEncodingsKey : @[
            @(NSUTF8StringEncoding),
            @(NSShiftJISStringEncoding)
        ],
        NSStringEncodingDetectionUseOnlySuggestedEncodingsKey : @YES
    };
    NSStringEncoding enc = [NSString stringEncodingForData:bytes
                                           encodingOptions:opts
                                           convertedString:&decoded
                                       usedLossyConversion:&lossy];
    if (enc != 0 && decoded) return decoded;

    // Manual fallback loop
    NSArray<NSNumber*> *candidates = @[
        @(NSISOLatin1StringEncoding)
    ];
    for (NSNumber *n in candidates) {
        decoded = [[NSString alloc] initWithData:bytes encoding:n.unsignedIntegerValue];
        if (decoded) return decoded;
    }

    // Last resort: treat as MacRoman with loss
    return [[NSString alloc] initWithData:bytes
                                 encoding:NSMacOSRomanStringEncoding] ?: @"";
}

+ (NSString *)nickthirteen:(NSString *)nickstring {
    // Check the length of the input string
    NSUInteger length = [nickstring length];
    
    if (length < 13) {
        // Pad with spaces at the beginning
        NSUInteger paddingNeeded = 13 - length;
        NSString *padding = [@"" stringByPaddingToLength:paddingNeeded withString:@" " startingAtIndex:0];
        return [padding stringByAppendingString:nickstring];
    } else {
        // Crop to the first 13 characters
        return [nickstring substringToIndex:13];
    }
}

- (NSString *)utiStringForFilenameExtension {
    NSString *ext = [self pathExtension].lowercaseString;
    if (ext.length == 0) return nil;

    // macOS 11+
    UTType *t = [UTType typeWithFilenameExtension:ext];
    return t.identifier;
}

@end

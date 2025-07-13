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

#pragma mark – Hotline string decoder (EOR‐encoded)
+ (NSString*)decodeHotlineString:(NSData*)data {
    const uint8_t *in = data.bytes;
    NSUInteger len     = data.length;
    uint8_t *out       = malloc(len);
    for (NSUInteger i = 0; i < len; i++) {
        out[i] = 0xFF - in[i];
    }
    NSString *s = [[NSString alloc] initWithBytesNoCopy:out
                                                 length:len
                                               encoding:NSUTF8StringEncoding
                                           freeWhenDone:YES];
    return s;
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

//
//  NSColor+Hex.m
//  decline
//
//  Created by Derek Scott on 5/15/25.
//

#import "NSColor+Hex.h"

@implementation NSColor (Hex)

+ (NSColor*)colorWithHexString:(NSString*)hexString {
    // 1) Trim whitespace/newlines and uppercase
    NSString *s = [[hexString stringByTrimmingCharactersInSet:
                     [NSCharacterSet whitespaceAndNewlineCharacterSet]]
                    uppercaseString];
    // 2) Remove leading “#” if present
    if ([s hasPrefix:@"#"]) s = [s substringFromIndex:1];

    // 3) Must be 6 or 8 characters
    if (s.length != 6 && s.length != 8) {
        NSLog(@"[HexColor] Invalid hex length: %@", hexString);
        return nil;
    }

    // 4) Scan into an unsigned int
    unsigned int rgba = 0;
    NSScanner *scanner = [NSScanner scannerWithString:s];
    [scanner scanHexInt:&rgba];

    CGFloat a, r, g, b;
    if (s.length == 6) {
        // RRGGBB
        a = 1.0;
        r = ((rgba & 0xFF0000) >> 16) / 255.0;
        g = ((rgba & 0x00FF00) >>  8) / 255.0;
        b =  (rgba & 0x0000FF)        / 255.0;
    } else {
        // AARRGGBB
        a = ((rgba & 0xFF000000) >> 24) / 255.0;
        r = ((rgba & 0x00FF0000) >> 16) / 255.0;
        g = ((rgba & 0x0000FF00) >>  8) / 255.0;
        b =  (rgba & 0x000000FF)        / 255.0;
    }

    return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
}

@end

//
//  NSColor+Hex.h
//  decline
//
//  Created by Derek Scott on 5/15/25.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (Hex)
/// hexString may start with “#” or not, may be 6 (RRGGBB) or 8 (AARRGGBB) hex digits.
+ (NSColor*)colorWithHexString:(NSString*)hexString;
@end

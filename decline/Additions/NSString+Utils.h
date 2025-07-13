//
//  NSString+Utils.h
//  decline
//
//  Created by Derek Scott on 7/5/25.
//

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface NSString (Utils)

+ (NSString*)hexStringFromData:(NSData *)data;
+ (NSString*)decodeHotlineString:(NSData*)data;
+ (NSString *)nickthirteen:(NSString *)nickstring;
- (NSString *)utiStringForFilenameExtension;

@end

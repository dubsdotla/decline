//
//  NSWorkspace+Icons.m
//  decline
//
//  Created by Derek Scott on 6/25/25.
//

#import "NSWorkspace+Icons.h"
#import <CoreServices/CoreServices.h>

@implementation NSWorkspace (Icons)

- (NSImage *)iconForFileExtension:(NSString *)ext
{
    NSImage *icon = nil;
    
    if (@available(macOS 11.0, *)) {
        UTType *type = [UTType typeWithFilenameExtension:ext];
        icon = [self iconForContentType:type];
    } else {
        CFStringRef cfExt = (__bridge CFStringRef)ext;
        CFStringRef cfUTI = UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension,
            cfExt,
            NULL
        );
        if (cfUTI) {
            icon = [self iconForFileType:(__bridge NSString *)cfUTI];
            CFRelease(cfUTI);
        }
    }

    return icon;
}   // ← close the method here

@end

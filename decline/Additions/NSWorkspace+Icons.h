//
//  NSWorkspace+Icons.h
//  decline
//
//  Created by Derek Scott on 6/25/25.
//

#import <Cocoa/Cocoa.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface NSWorkspace (Icons)
// returns a properly‐sized icon for the given file extension (e.g. "txt", "md", "png")
- (NSImage *)iconForFileExtension:(NSString *)ext;
@end

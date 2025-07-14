//
//  NSAttributedString+RTFAdditions.m
//  decline
//
//  Created by Derek Scott on 6/3/25.
//

#import "NSAttributedString+RTFAdditions.h"

@implementation NSAttributedString (RTFAdditions)

+ (instancetype)attributedStringWithRTFFileURL:(NSURL *)fileURL
                                         error:(NSError **)error
{
    if (!fileURL) {
        if (error) {
            *error = [NSError errorWithDomain:@"RTFAdditionsDomain"
                                         code:-1
                                     userInfo:@{ NSLocalizedDescriptionKey: @"fileURL was nil" }];
        }
        return nil;
    }

    // Specify that we want RTF‐format input
    NSDictionary<NSAttributedStringDocumentReadingOptionKey, id> *readOptions = @{
        NSDocumentTypeDocumentOption: NSRTFTextDocumentType
    };

    // Use the built‐in initWithURL:options:… initializer
    NSAttributedString *result = [[self alloc] initWithURL:fileURL
                                                   options:readOptions
                                        documentAttributes:NULL
                                                     error:error];
    return result;
}

- (BOOL)writeToRTFFileURL:(NSURL *)fileURL
                    error:(NSError **)error
{
    if (!fileURL) {
        if (error) {
            *error = [NSError errorWithDomain:@"RTFAdditionsDomain"
                                         code:-1
                                     userInfo:@{ NSLocalizedDescriptionKey: @"fileURL was nil" }];
        }
        return NO;
    }

    // Tell AppKit we want RTF output
    NSDictionary<NSAttributedStringDocumentAttributeKey, id> *writeOptions = @{
        NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType
    };

    // Convert the entire range to RTF data
    NSData *rtfData = [self dataFromRange:NSMakeRange(0, self.length)
                        documentAttributes:writeOptions
                                     error:error];
    if (!rtfData) {
        // error is already set by dataFromRange:…
        return NO;
    }

    // Write the data atomically to disk
    return [rtfData writeToURL:fileURL
                       options:NSDataWritingAtomic
                         error:error];
}

@end

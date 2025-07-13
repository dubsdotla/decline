//
//  NSAttributedString+RTFAdditions.h
//  decline
//
//  Created by Derek Scott on 6/3/25.
//

//
//  NSAttributedString+RTFAdditions.h
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>  // for NSAttributedStringDocument* constants

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (RTFAdditions)

/**
 Loads an RTF file from disk and returns an attributed string.

 @param fileURL   The file URL of the `.rtf` on disk. (Must not be nil.)
 @param error     If something goes wrong, this will be set. May be NULL.
 @return          A newly‐initialized NSAttributedString, or nil on failure.
 */
+ (nullable instancetype)attributedStringWithRTFFileURL:(NSURL *)fileURL
                                                 error:(NSError * _Nullable * _Nullable)error;

/**
 Writes this attributed string out as RTF to disk.

 @param fileURL   The destination file URL (e.g. “…/MyDocument.rtf”). (Must not be nil.)
 @param error     If something goes wrong, this will be set. May be NULL.
 @return          YES on success, NO on failure.
 */
- (BOOL)writeToRTFFileURL:(NSURL *)fileURL
                    error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END

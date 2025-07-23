//
//  BookmarkManager.h
//  decline
//
//  Created by Derek Scott on 7/19/25.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN

@interface BookmarkManager : NSObject
+ (void)storeCredentialsForAddress:(NSString *)address username:(NSString *)username password:(NSString *)password;
+ (void)removeCredentialsForAddress:(NSString *)address;
+ (NSDictionary*)retrieveCredentialsForAddress:(NSString *)address;
+ (NSArray<NSDictionary *> *)retrieveKeychainItemsWithPrefix:(NSString *)prefix;
@end

NS_ASSUME_NONNULL_END

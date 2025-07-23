//
//  BookmarkManager.m
//  decline
//
//  Created by Derek Scott on 7/19/25.
//

#import "BookmarkManager.h"

@implementation BookmarkManager

+  (void)storeCredentialsForAddress:(NSString *)address username:(NSString *)username password:(NSString *)password {
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];

    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: username, // Use username as the account
        (__bridge id)kSecAttrService: address, // Use address as the service identifier
        (__bridge id)kSecValueData: passwordData
    };

    // Remove any existing item
    SecItemDelete((__bridge CFDictionaryRef)query);

    // Add the new item to the Keychain
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    if (status == errSecSuccess) {
        NSLog(@"Successfully stored credentials for %@", address);
    } else {
        NSLog(@"Error storing credentials: %d", (int)status);
    }
}

+ (void)removeCredentialsForAddress:(NSString *)address {
    NSDictionary *query = @{
        (__bridge id)kSecClass:       (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: address
    };

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status == errSecSuccess || status == errSecItemNotFound) {
        if (status == errSecSuccess) {
            NSLog(@"Deleted all credentials for service %@", address);
        } else {
            NSLog(@"No credentials found for service %@ to delete.", address);
        }
    } else {
        NSLog(@"Error deleting credentials for service %@: %d", address, (int)status);
    }
}

// Method to retrieve credentials from Keychain
+  (NSDictionary*)retrieveCredentialsForAddress:(NSString *)address {
    // Define the query
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: address, // Use the service name from the Keychain
        (__bridge id)kSecReturnAttributes: @YES,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

    NSMutableDictionary *userPassDict = [[NSMutableDictionary alloc] init];
    
    if (status == errSecSuccess) {
        // Extract the username and password
        NSDictionary *item = (__bridge_transfer NSDictionary *)result;
        NSString *username = item[(__bridge id)kSecAttrAccount];
        NSData *passwordData = item[(__bridge id)kSecValueData];
        NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];

        userPassDict[@"username"] = username;
        userPassDict[@"password"] = password;
    } else {
        // Handle error (e.g., no matching credentials found)
        NSLog(@"Error retrieving credentials: %d", (int)status);
    }
    
    return userPassDict;
}

+ (NSArray<NSDictionary *> *)retrieveKeychainItemsWithPrefix:(NSString *)prefix {
    NSMutableArray<NSDictionary *> *results = [NSMutableArray array];

    // 1) Fetch all generic‐password attributes (no data)
    NSDictionary *attrQuery = @{
        (__bridge id)kSecClass:            (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecReturnAttributes: @YES,
        (__bridge id)kSecMatchLimit:       (__bridge id)kSecMatchLimitAll
    };
    CFTypeRef attrResult = NULL;
    OSStatus attrStatus = SecItemCopyMatching((__bridge CFDictionaryRef)attrQuery, &attrResult);
    if (attrStatus != errSecSuccess) {
        NSLog(@"Error retrieving Keychain attributes: %d", (int)attrStatus);
        return nil;
    }

    NSArray<NSDictionary *> *allItems = (__bridge_transfer NSArray *)attrResult;
    for (NSDictionary *item in allItems) {
        NSString *service = item[(__bridge id)kSecAttrService];
        if (![service hasPrefix:prefix]) continue;

        NSString *account = item[(__bridge id)kSecAttrAccount];
        // 2) For each matching item, fetch its password data
        NSDictionary *pwdQuery = @{
            (__bridge id)kSecClass:            (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService:      service,
            (__bridge id)kSecAttrAccount:      account,
            (__bridge id)kSecReturnData:       @YES,
            (__bridge id)kSecMatchLimit:       (__bridge id)kSecMatchLimitOne
        };
        CFTypeRef pwdResult = NULL;
        OSStatus pwdStatus = SecItemCopyMatching((__bridge CFDictionaryRef)pwdQuery, &pwdResult);
        if (pwdStatus == errSecSuccess) {
            NSData   *passwordData = (__bridge_transfer NSData *)pwdResult;
            NSString *password     = [[NSString alloc] initWithData:passwordData
                                                           encoding:NSUTF8StringEncoding];
            NSDictionary *entry = @{
                @"service": service,
                @"account": account,
                @"password": password
            };
            [results addObject:entry];
        } else {
            NSLog(@"Error retrieving password for %@/%@: %d", service, account, (int)pwdStatus);
        }
    }

    return [results copy];
}

@end

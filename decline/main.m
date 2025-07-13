//
//  main.m
//  decline
//
//  Created by Derek Scott on 5/12/25.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // 1. Create the singleton application instance
        NSApplication *app = [NSApplication sharedApplication];
        // 2. Allocate & set your AppDelegate
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        // 3. Enter the run loop (which will call applicationDidFinishLaunching:)
        [app run];
    }
    return EXIT_SUCCESS;
}

//
//  ChattyAppDelegate.m
//  Chatty
//
//  Copyright (c) 2009 Peter Bakhyryev <peter@byteclub.com>, ByteClub LLC
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//  
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.

#import "ChattyAppDelegate.h"
#import "ChattyViewController.h"
#import "ChatRoomViewController.h"
#import "WelcomeViewController.h"

static ChattyAppDelegate* _instance;

@implementation ChattyAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize chatRoomViewController;
@synthesize welcomeViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    // Allow other classes to use us
    _instance = self;

    // Create the root view controller
    self.viewController = [[ChattyViewController alloc] init];
    self.chatRoomViewController = [[ChatRoomViewController alloc] init];
    self.welcomeViewController = [[WelcomeViewController alloc] init];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Override point for customization after app launch
    [window addSubview:chatRoomViewController.view];
    [window addSubview:viewController.view];
    [window addSubview:welcomeViewController.view];
    [window makeKeyAndVisible];
    
    // Greet user
    [window bringSubviewToFront:welcomeViewController.view];
    [welcomeViewController activate];
}




+ (ChattyAppDelegate*)getInstance {
  return _instance;
}


// Show chat room
- (void)showChatRoom:(Room*)room {
  chatRoomViewController.chatRoom = room;
  [chatRoomViewController activate];
  
  [window bringSubviewToFront:chatRoomViewController.view];
}


// Show screen with room selection
- (void)showRoomSelection {
  [viewController activate];
  
  [window bringSubviewToFront:viewController.view];
}


@end

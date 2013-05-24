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
#import "AppConfig.h"

static ChattyAppDelegate* _instance;

@implementation ChattyAppDelegate

@synthesize window;
@synthesize roomListController;
@synthesize chatRoomViewController;
@synthesize welcomeViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    // Allow other classes to use us
    _instance = self;

    self.welcomeViewController = [[WelcomeViewController alloc] init];
    self.welcomeViewController.navigationItem.title = @"Chatty";
    self.roomListController = [[ChattyViewController alloc] init];
    self.roomListController.navigationItem.title = @"Rooms";
    self.chatRoomViewController = [[ChatRoomViewController alloc] init];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Create the root view controller
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:welcomeViewController];    
    [self.window setRootViewController: self.navigationController];
    [self.window makeKeyAndVisible];
    
    // Greet user
    [self.welcomeViewController activate];
}




+ (ChattyAppDelegate*)getInstance {
  return _instance;
}


// Show chat room
- (void)showChatRoom:(Room*)room {
  self.chatRoomViewController.chatRoom = room;
  self.chatRoomViewController.navigationItem.title = [AppConfig getInstance].name;
  [self.navigationController pushViewController:self.chatRoomViewController animated:NO];
}


// Show screen with room selection
- (void)showRoomSelection {
  [self.navigationController pushViewController:self.roomListController animated:NO];
}


@end

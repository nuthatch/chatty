//
//  ChatRoomViewController.m
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

#import "ChatRoomViewController.h"
#import "ChattyAppDelegate.h"
#import "UITextView+Utils.h"
#import "AppConfig.h"

@implementation ChatRoomViewController

@synthesize chatRoom;

// After view shows up, start the room
- (void)activate {
  if ( chatRoom != nil ) {
    chatRoom.delegate = self;
    [chatRoom start];
  }
  
  [input becomeFirstResponder];
}

// activate room when pushed
- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self activate];
}

// We are being asked to display a chat message
- (void)displayChatMessage:(NSString*)message fromUser:(NSString*)userName {
  [chat appendTextAfterLinebreak:[NSString stringWithFormat:@"%@: %@", userName, message]];
  [chat scrollToBottom];
}


// Room closed from outside
- (void)roomTerminated:(id)room reason:(NSString*)reason {
  // Explain what happened
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Room terminated" message:reason delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
  [alert show];
  [self exit];
}

// assume user exits with 'back' in navigation, rather than exit button
- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self exit];
}


// User decided to exit room
- (IBAction)exit {
  // Close the room
  [chatRoom stop];

  // Remove keyboard
  [input resignFirstResponder];

  // Erase chat
  chat.text = @"";

  // Switch back to welcome view
// [[ChattyAppDelegate getInstance] showRoomSelection];
}


#pragma mark -
#pragma mark UITextFieldDelegate Method Implementations

// This is called whenever "Return" is touched on iPhone's keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	if (theTextField == input) {
		// processs input
    [chatRoom broadcastChatMessage:input.text fromUser:[AppConfig getInstance].name];

		// clear input
		[input setText:@""];
	}
	return YES;
}

@end

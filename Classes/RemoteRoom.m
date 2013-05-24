//
//  RemoteRoom.m
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

#import "RemoteRoom.h"


// Private properties
@interface RemoteRoom ()
@property(nonatomic,strong) Connection* connection;
@end


@implementation RemoteRoom

@synthesize connection;

// Setup connection but don't connect yet
- (id)initWithHost:(NSString*)host andPort:(int)port {
    self = [super init];
    if (self) {
        connection = [[Connection alloc] initWithHostAddress:host andPort:port];
    }
    return self;
}


// Initialize and connect to a net service
- (id)initWithNetService:(NSNetService*)netService {
    self = [super init];
    if (self) {
        connection = [[Connection alloc] initWithNetService:netService];
    }
    return self;
}

// Start everything up, connect to server
- (BOOL)start {
  if ( connection == nil ) {
    return NO;
  }
  
  // We are the delegate
  connection.delegate = self;
  
  return [connection connect];
}


// Stop everything, disconnect from server
- (void)stop {
  if ( connection == nil ) {
    return;
  }
  
  [connection close];
  self.connection = nil;
}


// Send chat message to the server
- (void)broadcastChatMessage:(NSString*)message fromUser:(NSString*)name {
  // Create network packet to be sent to all clients
  NSDictionary* packet = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message", name, @"from", nil];

  // Send it out
  [connection sendNetworkPacket:packet];
}


#pragma mark -
#pragma mark ConnectionDelegate Method Implementations

- (void)connectionAttemptFailed:(Connection*)connection {
  [delegate roomTerminated:self reason:@"Wasn't able to connect to server"];
}


- (void)connectionTerminated:(Connection*)connection {
  [delegate roomTerminated:self reason:@"Connection to server closed"];
}


- (void)receivedNetworkPacket:(NSDictionary*)packet viaConnection:(Connection*)connection {
  // Display message locally
  [delegate displayChatMessage:[packet objectForKey:@"message"] fromUser:[packet objectForKey:@"from"]];
}


@end

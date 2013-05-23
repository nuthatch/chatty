//
//  Connection.h
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

#import <Foundation/Foundation.h>
#import <CFNetwork/CFSocketStream.h>
#import "ConnectionDelegate.h"


@interface Connection : NSObject {
  id<ConnectionDelegate> delegate;
  
  // Connection info: host address and port
  NSString* host;
  int port;
  
  // Connection info: native socket handle
  CFSocketNativeHandle connectedSocketHandle;
  
  // Connection info: NSNetService
  NSNetService* netService;
  
  // Read stream
  CFReadStreamRef readStream;
  bool readStreamOpen;
  NSMutableData* incomingDataBuffer;
  int packetBodySize;
  
  // Write stream
  CFWriteStreamRef writeStream;
  bool writeStreamOpen;
  NSMutableData* outgoingDataBuffer;
}

@property(nonatomic,strong) id<ConnectionDelegate> delegate;

// Initialize and store connection information until 'connect' is called
- (id)initWithHostAddress:(NSString*)host andPort:(int)port;

// Initialize using a native socket handle, assuming connection is open
- (id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle;

// Initialize using an instance of NSNetService
- (id)initWithNetService:(NSNetService*)netService;

// Connect using whatever connection info that was passed during initialization
- (BOOL)connect;

// Close connection
- (void)close;

// Send network message
- (void)sendNetworkPacket:(NSDictionary*)packet;

@end

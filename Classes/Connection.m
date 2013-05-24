//
//  Connection.m
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

#import "Connection.h"


// Declare C callback functions
void readStreamEventHandler(CFReadStreamRef stream, CFStreamEventType eventType, void *info);
void writeStreamEventHandler(CFWriteStreamRef stream, CFStreamEventType eventType, void *info);


// Private properties and methods
@interface Connection ()

// Properties
@property(nonatomic,strong) NSString* host;
@property(nonatomic,assign) int port;
@property(nonatomic,assign) CFSocketNativeHandle connectedSocketHandle;
@property(nonatomic,strong) NSNetService* netService;

// Initialize
- (void)clean;

// Further setup streams created by one of the 'init' methods
- (BOOL)setupSocketStreams;

// Stream event handlers
- (void)readStreamHandleEvent:(CFStreamEventType)event;
- (void)writeStreamHandleEvent:(CFStreamEventType)event;

// Read all available bytes from the read stream into buffer and try to extract packets
- (void)readFromStreamIntoIncomingBuffer;

// Write whatever data we have in the buffer, as much as stream can handle
- (void)writeOutgoingBufferToStream;

@end


@implementation Connection

@synthesize delegate;
@synthesize host, port;
@synthesize connectedSocketHandle;
@synthesize netService;


// Initialize, empty
- (void)clean {  
  readStream = nil;
  readStreamOpen = NO;
  
  writeStream = nil;
  writeStreamOpen = NO;
  
  incomingDataBuffer = nil;
  outgoingDataBuffer = nil;
  
  self.netService = nil;
  self.host = nil;
  connectedSocketHandle = -1;
  packetBodySize = -1;
}

// Initialize and store connection information until 'connect' is called
- (id)initWithHostAddress:(NSString*)_host andPort:(int)_port {
  [self clean];
  
  self.host = _host;
  self.port = _port;
  return self;
}


// Initialize using a native socket handle, assuming connection is open
- (id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle {
  [self clean];

  self.connectedSocketHandle = nativeSocketHandle;
  return self;
}


// Initialize using an instance of NSNetService
- (id)initWithNetService:(NSNetService*)_netService {
  [self clean];
  
  // Has it been resolved?
  if ( _netService.hostName != nil ) {
    return [self initWithHostAddress:_netService.hostName andPort:_netService.port];
  }
  
  self.netService = _netService;
  return self;
}


// Connect using whatever connection info that was passed during initialization
- (BOOL)connect {
  if ( self.host != nil ) {
    // Bind read/write streams to a new socket
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)self.host,
        self.port, &readStream, &writeStream);
    
    // Do the rest
    return [self setupSocketStreams];
  }
  else if ( self.connectedSocketHandle != -1 ) {
    // Bind read/write streams to a socket represented by a native socket handle
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, self.connectedSocketHandle,
        &readStream, &writeStream);
    
    // Do the rest
    return [self setupSocketStreams];
  }
  else if ( netService != nil ) {
    // Still need to resolve?
    if ( netService.hostName != nil ) {
      CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
          (__bridge CFStringRef)netService.hostName, netService.port, &readStream, &writeStream);
      return [self setupSocketStreams];
    }

    // Start resolving
    netService.delegate = (id)self;
    [netService resolveWithTimeout:5.0];
    return YES;
  }

  // Nothing was passed, connection is not possible
  return NO;
}


// Further setup socket streams that were created by one of our 'init' methods
- (BOOL)setupSocketStreams {
  // Make sure streams were created correctly
  if ( readStream == nil || writeStream == nil ) {
    [self close];
    return NO;
  }
  
  // Create buffers
  incomingDataBuffer = [[NSMutableData alloc] init];
  outgoingDataBuffer = [[NSMutableData alloc] init];
  
  // Indicate that we want socket to be closed whenever streams are closed
  CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket,
    kCFBooleanTrue);
  CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket,
    kCFBooleanTrue);

  // We will be handling the following stream events
  CFOptionFlags registeredEvents = kCFStreamEventOpenCompleted |
      kCFStreamEventHasBytesAvailable | kCFStreamEventCanAcceptBytes |
      kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred;
  
  // Setup stream context - reference to 'self' will be passed to stream event handling callbacks
  CFStreamClientContext ctx = {0, (__bridge void *)(self), NULL, NULL, NULL};

  // Specify callbacks that will be handling stream events
  CFReadStreamSetClient(readStream, registeredEvents, readStreamEventHandler, &ctx);
  CFWriteStreamSetClient(writeStream, registeredEvents, writeStreamEventHandler, &ctx);
  
  // Schedule streams with current run loop
  CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(),
      kCFRunLoopCommonModes);
  CFWriteStreamScheduleWithRunLoop(writeStream, CFRunLoopGetCurrent(),
      kCFRunLoopCommonModes);
  
  // Open both streams
  if ( ! CFReadStreamOpen(readStream) || ! CFWriteStreamOpen(writeStream)) {
    [self close];
    return NO;
  }
  
  return YES;
}


// Close connection
- (void)close {
  // Cleanup read stream
  if ( readStream != nil ) {
    CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFReadStreamClose(readStream);
    CFRelease(readStream);
    readStream = NULL;
  }
  
  // Cleanup write stream
  if ( writeStream != nil ) {
    CFWriteStreamUnscheduleFromRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFWriteStreamClose(writeStream);
    CFRelease(writeStream);
    writeStream = NULL;
  }
  
  // Cleanup buffers
  incomingDataBuffer = NULL;
  outgoingDataBuffer = NULL;
  
  // Stop net service?
  if ( netService != nil ) {
    [netService stop];
    self.netService = nil;
  }
  
  // Reset all other variables
  [self clean];
}


// Send network message
- (void)sendNetworkPacket:(NSDictionary*)packet {
  // Encode packet
  NSData* rawPacket = [NSKeyedArchiver archivedDataWithRootObject:packet];
  
  // Write header: lengh of raw packet
  int packetLength = [rawPacket length];
  [outgoingDataBuffer appendBytes:&packetLength length:sizeof(int)];
  
  // Write body: encoded NSDictionary
  [outgoingDataBuffer appendData:rawPacket];
  
  // Try to write to stream
  [self writeOutgoingBufferToStream];
}


#pragma mark Read stream methods

// Dispatch readStream events
void readStreamEventHandler(CFReadStreamRef stream, CFStreamEventType eventType,
    void *info) {
  Connection* connection = (__bridge Connection*)info;
  [connection readStreamHandleEvent:eventType];
}


// Handle events from the read stream
- (void)readStreamHandleEvent:(CFStreamEventType)event {
  // Stream successfully opened
  if ( event == kCFStreamEventOpenCompleted ) {
    readStreamOpen = YES;
  }
  // New data has arrived
  else if ( event == kCFStreamEventHasBytesAvailable ) {
    // Read as many bytes from the stream as possible and try to extract meaningful packets
    [self readFromStreamIntoIncomingBuffer];
  }
  // Connection has been terminated or error encountered (we treat them the same way)
  else if ( event == kCFStreamEventEndEncountered || event == kCFStreamEventErrorOccurred ) {
    // Clean everything up
    [self close];

    // If we haven't connected yet then our connection attempt has failed
    if ( !readStreamOpen || !writeStreamOpen ) {
      [delegate connectionAttemptFailed:self];
    }
    else {
      [delegate connectionTerminated:self];
    }
  }
}


// Read as many bytes from the stream as possible and try to extract meaningful packets
- (void)readFromStreamIntoIncomingBuffer {
  // Temporary buffer to read data into
  UInt8 buf[1024];

  // Try reading while there is data
  while( CFReadStreamHasBytesAvailable(readStream) ) {  
    CFIndex len = CFReadStreamRead(readStream, buf, sizeof(buf));
    if ( len <= 0 ) {
      // Either stream was closed or error occurred. Close everything up and treat this as "connection terminated"
      [self close];
      [delegate connectionTerminated:self];
      return;
    }
    
    [incomingDataBuffer appendBytes:buf length:len];
  }

  // Try to extract packets from the buffer.
  //
  // Protocol: header + body
  //  header: an integer that indicates length of the body
  //  body: bytes that represent encoded NSDictionary
  
  // We might have more than one message in the buffer - that's why we'll be reading it inside the while loop
  while( YES ) {
    // Did we read the header yet?
    if ( packetBodySize == -1 ) {
      // Do we have enough bytes in the buffer to read the header?
      if ( [incomingDataBuffer length] >= sizeof(int) ) {
        // extract length
        memcpy(&packetBodySize, [incomingDataBuffer bytes], sizeof(int));
        
        // remove that chunk from buffer
        NSRange rangeToDelete = {0, sizeof(int)};
        [incomingDataBuffer replaceBytesInRange:rangeToDelete withBytes:NULL length:0];
      }
      else {
        // We don't have enough yet. Will wait for more data.
        break;
      }
    }
    
    // We should now have the header. Time to extract the body.
    if ( [incomingDataBuffer length] >= packetBodySize ) {
      // We now have enough data to extract a meaningful packet.
      NSData* raw = [NSData dataWithBytes:[incomingDataBuffer bytes] length:packetBodySize];
      NSDictionary* packet = [NSKeyedUnarchiver unarchiveObjectWithData:raw];
      
      // Tell our delegate about it
      [delegate receivedNetworkPacket:packet viaConnection:self];

      // Remove that chunk from buffer
      NSRange rangeToDelete = {0, packetBodySize};
      [incomingDataBuffer replaceBytesInRange:rangeToDelete withBytes:NULL length:0];
      
      // We have processed the packet. Resetting the state.
      packetBodySize = -1;
    }
    else {
      // Not enough data yet. Will wait.
      break;
    }
  }
}


#pragma mark Write stream methods

// Dispatch writeStream event handling
void writeStreamEventHandler(CFWriteStreamRef stream, CFStreamEventType eventType, void *info) {
  Connection* connection = (__bridge Connection*)info;
  [connection writeStreamHandleEvent:eventType];
}


// Handle events from the write stream
- (void)writeStreamHandleEvent:(CFStreamEventType)event {
    // Stream successfully opened
  if ( event == kCFStreamEventOpenCompleted ) {
    writeStreamOpen = YES;
  }
  // Stream has space for more data to be written
  else if ( event == kCFStreamEventCanAcceptBytes ) {
    // Write whatever data we have, as much as stream can handle
    [self writeOutgoingBufferToStream];
  }
  // Connection has been terminated or error encountered (we treat them the same way)
  else if ( event == kCFStreamEventEndEncountered || event == kCFStreamEventErrorOccurred ) {
    // Clean everything up
    [self close];

    // If we haven't connected yet then our connection attempt has failed
    if ( !readStreamOpen || !writeStreamOpen ) {
      [delegate connectionAttemptFailed:self];
    }
    else {
      [delegate connectionTerminated:self];
    }
  }
}


// Write whatever data we have, as much of it as stream can handle
- (void)writeOutgoingBufferToStream {
  // Is connection open?
  if ( !readStreamOpen || !writeStreamOpen ) {
    // No, wait until everything is operational before pushing data through
    return;
  }

  // Do we have anything to write?
  if ( [outgoingDataBuffer length] == 0 ) {
    return;
  }
  
  // Can stream take any data in?
  if ( !CFWriteStreamCanAcceptBytes(writeStream) ) { 
    return;
  }
  
  // Write as much as we can
  CFIndex writtenBytes = CFWriteStreamWrite(writeStream, [outgoingDataBuffer bytes], [outgoingDataBuffer length]);

  if ( writtenBytes == -1 ) {
    // Error occurred. Close everything up.
    [self close];
    [delegate connectionTerminated:self];
    return;
  }
  
  NSRange range = {0, writtenBytes};
  [outgoingDataBuffer replaceBytesInRange:range withBytes:NULL length:0];
}


#pragma mark -
#pragma mark NSNetService Delegate Method Implementations

// Called if we weren't able to resolve net service
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
  if ( sender != netService ) {
    return;
  }
  
  // Close everything and tell delegate that we have failed
  [delegate connectionAttemptFailed:self];
  [self close];
}


// Called when net service has been successfully resolved
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
  if ( sender != netService ) {
    return;
  }
  
  // Save connection info
  self.host = netService.hostName;
  self.port = netService.port;
  
  // Don't need the service anymore
  self.netService = nil;
  
  // Connect!
  if ( ![self connect] ) {
    [delegate connectionAttemptFailed:self];
    [self close];
  }
}

@end

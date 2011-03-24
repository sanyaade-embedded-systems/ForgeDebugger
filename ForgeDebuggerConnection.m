//
//  ForgeDebuggerConnection.m
//  ForgeDebugger
//
//  Created by Uli Kusterer on 13.11.05.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "ForgeDebuggerConnection.h"


@implementation ForgeDebuggerConnection

-(id)	initWithSocket: (ULINetSocket*)inSock debuggerSession: (id<ForgeDebuggerSession>)inDebuggerSession
{
	if( (self = [super init]) )
	{
		socket = [inSock retain];
		[socket setDelegate: self];
		[socket scheduleOnCurrentRunLoop];
		session = inDebuggerSession;
		
		currentData = [[NSMutableData alloc] init];
		
		//NSLog( @"B Connection Created" );
	}
	
	return self;
}


-(void)	dealloc
{
	[socket release];
	socket = nil;
	[currentData release];
	currentData = nil;

	//NSLog( @"B Connection Destroyed" );
	
	[super dealloc];
}


-(void)	writeOneLine: (NSString*)str
{
	//NSLog( @"B Writing one line" );

	[socket writeString: str encoding: NSUTF8StringEncoding];
}


-(void)	writeCommandWithoutData: (const char*)str
{
	//NSLog( @"B Writing one line" );
	
	uint32_t	dataLen = 0;
	[socket write: str length: 4];
	[socket write: &dataLen length: sizeof(dataLen)];
}


- (void)netsocketConnected:(ULINetSocket*)inNetSocket
{
	//NSLog(@"B Connected.");
}


- (void)netsocket:(ULINetSocket*)inNetSocket connectionTimedOut:(NSTimeInterval)inTimeout
{
	[self autorelease];
	//NSLog(@"B Connection timed out.");
}


- (void)netsocketDisconnected:(ULINetSocket*)inNetSocket
{
	[self autorelease];
	//NSLog(@"B Disconnected.");
}


- (void)netsocket:(ULINetSocket*)inNetSocket connectionAccepted:(ULINetSocket*)inNewNetSocket
{
	//NSLog(@"B Connection accepted.");
}


-(NSInteger)	processOneCommandInDataBuffer
{
	if( [currentData length] < 8 )
		return 0;
	
	uint32_t	*	bytesArray = (uint32_t*) [currentData bytes];
	char		*	singleBytes = (char*) bytesArray;
	unsigned		payloadLength = bytesArray[1];
	
	if( ([currentData length] -8) < payloadLength )
		return 0;
	
	NSData* thePayload = [currentData subdataWithRange: NSMakeRange(8,payloadLength)];
	
	NSString	*	selName = [NSString stringWithFormat: @"handle%c%c%c%cOperation:", singleBytes[0], singleBytes[1], singleBytes[2], singleBytes[3]];
	SEL	theAction = NSSelectorFromString( selName );
	
	//NSLog( @"Asked to do %@ with %d bytes of payload", selName, payloadLength );
	
	if( [session respondsToSelector: theAction] )
		[(NSObject*)session performSelectorOnMainThread: theAction withObject: thePayload waitUntilDone: NO];
	else
		;//NSLog( @"No handler for %@", selName );
	
	return payloadLength + 8;
}


-(void)	processCommandsInDataBuffer
{
	NSInteger	bytesRead = 0;
	while(( bytesRead = [self processOneCommandInDataBuffer] ))
		[currentData replaceBytesInRange: NSMakeRange(0,bytesRead) withBytes: nil length: 0];
}


- (void)netsocket:(ULINetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
	//NSLog( @"B %u bytes available", inAmount );
	
	[inNetSocket readOntoData: currentData];
	
	[self processCommandsInDataBuffer];
}


- (void)netsocketDataSent:(ULINetSocket*)inNetSocket
{
	//NSLog(@"B Data Sent.");
}

@end

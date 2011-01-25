//
//  ForgeDebuggerConnection.m
//  ForgeDebugger
//
//  Created by Uli Kusterer on 13.11.05.
//  Copyright 2005 Uli Kusterer. All rights reserved.
//

#import "ForgeDebuggerConnection.h"


@implementation ForgeDebuggerConnection

-(id)	initWithSocket: (ULINetSocket*)inSock
{
	if( (self = [super init]) )
	{
		socket = [inSock retain];
		readBufLock = [[NSLock alloc] init];
		readBuffer = [[NSMutableString alloc] init];
		[socket setDelegate: self];
		[socket scheduleOnCurrentRunLoop];
		
		NSLog( @"B Connection Created" );
	}
	
	return self;
}


-(void)	dealloc
{
	[socket release];
	[readBuffer release];
	[readBufLock release];

	NSLog( @"B Connection Destroyed" );
	
	[super dealloc];
}


-(void)	writeOneLine: (NSString*)str
{
	NSLog( @"B Writing one line" );

	[readBufLock lock];
	[socket writeString: str encoding: NSISOLatin1StringEncoding];
	[readBufLock unlock];
}


- (void)netsocketConnected:(ULINetSocket*)inNetSocket
{
	NSLog(@"B Connected.");
}


- (void)netsocket:(ULINetSocket*)inNetSocket connectionTimedOut:(NSTimeInterval)inTimeout
{
	[self autorelease];
	NSLog(@"B Connection timed out.");
}


- (void)netsocketDisconnected:(ULINetSocket*)inNetSocket
{
	[self autorelease];
	NSLog(@"B Disconnected.");
}


- (void)netsocket:(ULINetSocket*)inNetSocket connectionAccepted:(ULINetSocket*)inNewNetSocket
{
	NSLog(@"B Connection accepted.");
}


-(void)	processOneMessage: (uint32_t)messageID withParam: (uint32_t)param
{
	NSLog( @"%c%c%c%c %d",
			((char*)&messageID)[0], ((char*)&messageID)[1], ((char*)&messageID)[2], ((char*)&messageID)[3],
			param);
}


-(void)	processOneMessageObj: (NSData*)eightBytesObj
{
	if( [eightBytesObj length] != 8 )
		return;
	
	uint32_t	*	bytesArray = (uint32_t*) [eightBytesObj bytes];
	[self processOneMessage: bytesArray[0] withParam: ntohl(bytesArray[1])];
}


- (void)netsocket:(ULINetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
	NSLog( @"B %u bytes available", inAmount );
	
	NSData*	theBytes = [inNetSocket readData: 8];
	
	[self performSelectorOnMainThread: @selector(processOneMessageObj:) withObject: theBytes waitUntilDone: NO];
}


- (void)netsocketDataSent:(ULINetSocket*)inNetSocket
{
	NSLog(@"B Data Sent.");
}

@end

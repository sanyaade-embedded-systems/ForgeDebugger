//
//  ForgeDebuggerConnection.m
//  ForgeDebugger
//
//  Created by Uli Kusterer on 13.11.05.
//  Copyright 2005 Uli Kusterer. All rights reserved.
//

#import "ForgeDebuggerConnection.h"


@implementation ForgeDebuggerConnection

-(id)	initWithSocket: (NetSocket*)inSock
{
	if( (self = [super init]) )
	{
		socket = [inSock retain];
		[socket setDelegate: self];
	}
	
	return self;
}


-(void)	dealloc
{
	[socket release];
	
	[super dealloc];
}


-(void)	writeOneLine: (NSString*)str
{
	[readBufLock lock];
	[socket writeString: str encoding: NSISOLatin1StringEncoding];
	[readBufLock unlock];
}


- (void)netsocketConnected:(NetSocket*)inNetSocket
{
	NSLog(@"Connected.");
}


- (void)netsocket:(NetSocket*)inNetSocket connectionTimedOut:(NSTimeInterval)inTimeout
{
	[self autorelease];
	NSLog(@"Connection timed out.");
}


- (void)netsocketDisconnected:(NetSocket*)inNetSocket
{
	[self autorelease];
	NSLog(@"Disconnected.");
}


- (void)netsocket:(NetSocket*)inNetSocket connectionAccepted:(NetSocket*)inNewNetSocket
{
	NSLog(@"Connection accepted.");
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
	[self processOneMessage: bytesArray[0] withParam: bytesArray[1]];
}


- (void)netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
	NSLog( @"%u bytes available", inAmount );
	
	NSData*	theBytes = [inNetSocket readData: 8];
	
	[self performSelectorOnMainThread: @selector(processOneMessageObj:) withObject: theBytes waitUntilDone: NO];
}


- (void)netsocketDataSent:(NetSocket*)inNetSocket
{
	NSLog(@"Data Sent.");
}

@end

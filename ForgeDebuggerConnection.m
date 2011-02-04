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
		readBufLock = [[NSLock alloc] init];
		readBuffer = [[NSMutableString alloc] init];
		[socket setDelegate: self];
		[socket scheduleOnCurrentRunLoop];
		session = inDebuggerSession;
		
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
	[socket writeString: str encoding: NSUTF8StringEncoding];
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


- (void)netsocket:(ULINetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
	NSLog( @"B %u bytes available", inAmount );
	
	NSData*			theBytes = [inNetSocket readData: 8];
	uint32_t	*	bytesArray = (uint32_t*) [theBytes bytes];
	char		*	singleBytes = (char*) bytesArray;
    
    NSData* thePayload = [inNetSocket readData: bytesArray[1]];
    
	SEL	theAction = NSSelectorFromString( [NSString stringWithFormat: @"handle%c%c%c%cOperation:", singleBytes[0], singleBytes[1], singleBytes[2], singleBytes[3]] );
	
	if( [session respondsToSelector: theAction] )
		[(NSObject*)session performSelectorOnMainThread: theAction withObject: thePayload waitUntilDone: NO];
}


- (void)netsocketDataSent:(ULINetSocket*)inNetSocket
{
	NSLog(@"B Data Sent.");
}

@end

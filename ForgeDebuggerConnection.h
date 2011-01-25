//
//  ForgeDebuggerConnection.h
//  ForgeDebugger
//
//  Created by Uli Kusterer on 13.11.05.
//  Copyright 2005 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ULINetSocket.h"


@interface ForgeDebuggerConnection : NSObject
{
	ULINetSocket	*	socket;
	NSMutableString	*	readBuffer;
	NSLock*				readBufLock;
}

-(id)	initWithSocket: (ULINetSocket*)sock;

@end

//
//  ForgeDebuggerConnection.h
//  ForgeDebugger
//
//  Created by Uli Kusterer on 13.11.05.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ULINetSocket.h"


@protocol ForgeDebuggerSession <NSObject>

-(void)	handleEMTYOperation: (NSData*)theData;
-(void)	handleVARIOperation: (NSData*)theData;
-(void)	handleCALLOperation: (NSData*)theData;
-(void)	handleWAITOperation: (NSData*)theData;

@end


@interface ForgeDebuggerConnection : NSObject
{
	ULINetSocket	*			socket;
	id<ForgeDebuggerSession>	session;
	NSMutableData	*			currentData;
}

-(id)	initWithSocket: (ULINetSocket*)inSock debuggerSession: (id<ForgeDebuggerSession>)inDebuggerSession;

-(void)	writeOneLine: (NSString*)str;
-(void)	writeCommandWithoutData: (const char*)str;

@end

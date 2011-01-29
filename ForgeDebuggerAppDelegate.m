//
//  ForgeDebuggerAppDelegate.m
//  ForgeDebugger
//
//  Created by Uli Kusterer on 14.01.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "ForgeDebuggerAppDelegate.h"
#import "ULINetSocket.h"
#import "ForgeDebuggerConnection.h"

@implementation ForgeDebuggerAppDelegate

@synthesize window = mWindow;
@synthesize stackTable = mStackTable;
@synthesize variablesTable = mVariablesTable;
@synthesize textView = mTextView;


- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	mServerSocket = [[ULINetSocket netsocketListeningOnRandomPort] retain];
	[mServerSocket setDelegate: self];
	[mServerSocket scheduleOnCurrentRunLoop];
	
	mVariables = [[NSMutableArray alloc] init];
	mHandlers = [[NSMutableArray alloc] init];
}


-(void)	dealloc
{
	[mVariables release];
	[mHandlers release];
	
	[super dealloc];
}


- (void)netsocketConnected:(ULINetSocket*)inNetSocket
{
	NSLog(@"A Connected.");
}


- (void)netsocket:(ULINetSocket*)inNetSocket connectionTimedOut:(NSTimeInterval)inTimeout
{
	NSLog(@"A Connection timed out.");
}


- (void)netsocketDisconnected:(ULINetSocket*)inNetSocket
{
	NSLog(@"A Disconnected.");
}


- (void)netsocket:(ULINetSocket*)inNetSocket connectionAccepted:(ULINetSocket*)inNewNetSocket
{
	NSLog(@"A Connection accepted.");
	
	ForgeDebuggerConnection*	conn = [[ForgeDebuggerConnection alloc] initWithSocket: inNewNetSocket debuggerSession: self];
	conn = conn;
}


- (void)netsocket:(ULINetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
	NSLog(@"A Data Available.");
}


- (void)netsocketDataSent:(ULINetSocket*)inNetSocket
{
	NSLog(@"A Data Sent.");
}


-(BOOL)	application: (NSApplication *)sender openFile: (NSString *)filename
{
	NSString		*		codeStr = [[[NSString alloc] initWithContentsOfFile: filename] autorelease];
	NSDictionary	*		textAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
												[NSFont userFixedPitchFontOfSize: 10.0], NSFontAttributeName,
												nil];
	
	[mTextView setString: codeStr];
	[[mTextView textStorage] addAttributes: textAttrs range: NSMakeRange(0, [codeStr length])];
	
	return YES;
}


-(NSInteger)	numberOfRowsInTableView: (NSTableView*)inView
{
	if( inView == mStackTable )
		return [mHandlers count];
	else
		return [mVariables count];
}


- (id)tableView:(NSTableView *)inView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if( inView == mStackTable )
	{
		return [[mHandlers objectAtIndex: row] objectForKey: [tableColumn identifier]];
	}
	else
	{
		return [[mVariables objectAtIndex: row] objectForKey: [tableColumn identifier]];
	}
}


-(NSData*)	subdataUntilNextNullByteInData: (NSData*)theData foundRange: (NSRange*)theRange	// Must be { 0, 0 } on first call.
{
	NSInteger	len = [theData length];
	char		theByte = 0;
	theRange->location += theRange->length;
	theRange->length = 0;
	
	for( NSInteger x = 0; x < len; x++ )
	{
		[theData getBytes: &theByte length: 1];
		if( theByte == 0 )
			break;
		theRange->length ++;
	}
	
	return [theData subdataWithRange: *theRange];
}


-(void)	handleEMTYOperation: (NSData*)theData
{
	[mVariables removeAllObjects];
	[mVariablesTable reloadData];
	[mHandlers removeAllObjects];
	[mStackTable reloadData];
}


-(void)	handleVARIOperation: (NSData*)theData
{
	NSRange			theRange = { 0, 0 };
	
	NSData		*	varNameData = [self subdataUntilNextNullByteInData: theData foundRange: &theRange];
	NSData		*	varTypeData = [self subdataUntilNextNullByteInData: theData foundRange: &theRange];
	NSData		*	varValueData = [self subdataUntilNextNullByteInData: theData foundRange: &theRange];
	
	NSString	*	varName = [[NSString alloc] initWithData: varNameData encoding: NSUTF8StringEncoding];
	NSString	*	varType = [[NSString alloc] initWithData: varTypeData encoding: NSUTF8StringEncoding];
	NSString	*	varValue = [[NSString alloc] initWithData: varValueData encoding: NSUTF8StringEncoding];
	[mVariables addObject: [NSDictionary dictionaryWithObjectsAndKeys: varName, @"name", varType, @"type", varValue, @"value", nil]];
	[varName release];
	[varType release];
	[varValue release];
	[mVariablesTable reloadData];
}


-(void)	handleCALLOperation: (NSData*)theData
{
	NSRange			theRange = { 0, 0 };
	
	NSData		*	handlerNameData = [self subdataUntilNextNullByteInData: theData foundRange: &theRange];
	
	NSString	*	handlerName = [[NSString alloc] initWithData: handlerNameData encoding: NSUTF8StringEncoding];
	[mHandlers addObject: [NSDictionary dictionaryWithObjectsAndKeys: handlerName, @"name", nil]];
	[handlerName release];
	[mStackTable reloadData];
}


-(void)	handleWAITOperation: (NSData*)theData
{
	// Enable UI until one of them is used and we've sent a reply to the client.
}

@end

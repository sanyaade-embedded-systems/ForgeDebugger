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
@synthesize fileNameField = mFileNameField;
@synthesize instructionField = mInstructionField;
@synthesize stepInstructionButton = mStepInstructionButton;
@synthesize continueButton = mContinueButton;
@synthesize exitToTopButton = mExitToTopButton;
@synthesize addCheckpointButton = mAddCheckpointButton;
@synthesize removeCheckpointButton = mRemoveCheckpointButton;
@synthesize instructionsTableView = mInstructionsTableView;


- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	mServerSocket = [[ULINetSocket netsocketListeningOnPort: 13762] retain];
	[mServerSocket setDelegate: self];
	[mServerSocket scheduleOnCurrentRunLoop];
	
	mVariables = [[NSMutableArray alloc] init];
	mHandlers = [[NSMutableArray alloc] init];
	mInstructions = [[NSMutableDictionary alloc] init];
	
	[self setDebuggerUIEnabled: NO];
}


-(void)	dealloc
{
	[mVariables release];
	[mHandlers release];
	[mInstructions release];
	
	[super dealloc];
}


- (void)netsocketConnected:(ULINetSocket*)inNetSocket
{
	//NSLog(@"A Connected.");
}


- (void)netsocket:(ULINetSocket*)inNetSocket connectionTimedOut:(NSTimeInterval)inTimeout
{
	//NSLog(@"A Connection timed out.");
}


- (void)netsocketDisconnected:(ULINetSocket*)inNetSocket
{
	//NSLog(@"A Disconnected.");
}


- (void)netsocket:(ULINetSocket*)inNetSocket connectionAccepted:(ULINetSocket*)inNewNetSocket
{
	//NSLog(@"A Connection accepted.");
	
	mDebuggerConnection = [[ForgeDebuggerConnection alloc] initWithSocket: inNewNetSocket debuggerSession: self];
}


- (void)netsocket:(ULINetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
	//NSLog(@"A Data Available.");
}


- (void)netsocketDataSent:(ULINetSocket*)inNetSocket
{
	//NSLog(@"A Data Sent.");
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
	else if( inView == mVariablesTable )
		return [mVariables count];
	else
		return [mInstructions count];
}


-(NSArray*)	sortedInstructionKeysArray
{
	return [[mInstructions allKeys] sortedArrayUsingSelector: @selector(compare:)];
}


- (id)tableView:(NSTableView *)inView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if( inView == mStackTable )
	{
		return [[mHandlers objectAtIndex: row] objectForKey: [tableColumn identifier]];
	}
	else if( inView == mVariablesTable )
	{
		return [[mVariables objectAtIndex: row] objectForKey: [tableColumn identifier]];
	}
	else
	{
		NSArray	*	sortedKeys = [self sortedInstructionKeysArray];
		NSString* instructionStr = [mInstructions objectForKey: [sortedKeys objectAtIndex: row]];
		return instructionStr;
	}
}


-(NSData*)	subdataUntilNextNullByteInData: (NSData*)theData foundRange: (NSRange*)theRange	// Must be { 0, 0 } on first call.
{
	NSInteger	len = [theData length];
	char		theByte = 0;
	theRange->location += theRange->length;
	theRange->length = 0;
	
	if( theRange->location != 0 )
		theRange->location ++;	// Skip previous range's trailing NULL byte.
		
	for( NSInteger x = theRange->location; x < len; x++ )
	{
		[theData getBytes: &theByte range: NSMakeRange(x,1)];
		if( theByte == 0 )
			break;
		theRange->length ++;
	}
	
	if( theRange->length == 0 || theRange->location >= [theData length] )
	{
		theRange->location = [theData length];
		theRange->length = 0;
		return [NSData data];
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
	[mVariables addObject: [NSDictionary dictionaryWithObjectsAndKeys:
					varName, @"name",
					varType, @"type",
					varValue, @"value", nil]];
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
	[mHandlers addObject: [NSDictionary dictionaryWithObjectsAndKeys:
					handlerName, @"name", nil]];
	[handlerName release];
	[mStackTable reloadData];
}


-(void)	handleINSTOperation: (NSData*)theData
{
	NSRange						theRange = { 0, 0 };
	NSData				*		instructionData = [self subdataUntilNextNullByteInData: theData foundRange: &theRange];
	unsigned long long			instructionPointer = 0;
	static unsigned long long	sLastInstructionPointer = 0;
	[theData getBytes: &instructionPointer range: NSMakeRange(theRange.location+theRange.length+1, sizeof(instructionPointer))];
	NSString			*		instructionKey = [NSString stringWithFormat: @"%ll016x", instructionPointer];
	
	if( sLastInstructionPointer != instructionPointer )
	{
		NSString	*	instructionStr = [[[NSString alloc] initWithData: instructionData encoding: NSUTF8StringEncoding] autorelease];
		
		[mInstructions setObject: instructionStr forKey: instructionKey];
		[mInstructionsTableView reloadData];
		
		sLastInstructionPointer = instructionPointer;
	}
}


-(void)	handleCURROperation: (NSData*)theData
{
	unsigned long long			instructionPointer = 0;
	[theData getBytes: &instructionPointer length: sizeof(instructionPointer)];
	NSString			*		instructionKey = [NSString stringWithFormat: @"%ll016x", instructionPointer];
	
	NSUInteger		instrIdx = [[self sortedInstructionKeysArray] indexOfObjectIdenticalTo: instructionKey];
	NSIndexSet	*	indexesToSelect = [NSIndexSet indexSetWithIndex: instrIdx];
	[mInstructionsTableView selectRowIndexes: indexesToSelect byExtendingSelection: NO];
}


-(void)	handleSOUROperation: (NSData*)theData
{
	NSRange			theRange = { 0, 0 };
	NSData		*	fileNameData = [self subdataUntilNextNullByteInData: theData foundRange: &theRange];
	NSData		*	fileContentData = [self subdataUntilNextNullByteInData: theData foundRange: &theRange];
	
	NSString	*	fileNameStr = [[NSString alloc] initWithData: fileNameData encoding: NSUTF8StringEncoding];
	NSString	*	fileContentStr = [[NSString alloc] initWithData: fileContentData encoding: NSUTF8StringEncoding];
	[[[mTextView textStorage] mutableString] setString: fileContentStr];
	[mFileNameField setStringValue: fileNameStr];
	[fileNameStr release];
	[fileContentStr release];
	
	[[mTextView textStorage] addAttribute: NSFontAttributeName value: [NSFont userFixedPitchFontOfSize: 10.0] range: NSMakeRange(0,[[mTextView textStorage] length])];
}


-(void)	handleLINEOperation: (NSData*)theData
{
	NSRange			allRange = NSMakeRange(0,[[mTextView textStorage] length]);
	NSRange			lineRange = { 0,0 };
	uint32_t		theLine = 0;
	NSString	*	theStr = [mTextView string];
	NSInteger		textLength = [theStr length];
	NSInteger		currLine = 1;
	BOOL			foundLine = NO;
	BOOL			foundLineEnd = NO;
	
	[theData getBytes: &theLine length: sizeof(theLine)];
	
	for( NSInteger currIdx = 0; currIdx < textLength; currIdx++ )
	{
		if( [theStr characterAtIndex: currIdx] == '\n' )
		{
			if( foundLine )
			{
				lineRange.length = currIdx -lineRange.location +1;	// Select the line break, too.
				foundLineEnd = YES;
				break;
			}
			currLine += 1;
		}
		else if( currLine == theLine && !foundLine )
		{
			lineRange.location = currIdx;
			foundLine = YES;
		}
	}
	
	if( foundLine && !foundLineEnd )
		lineRange.length = textLength -lineRange.location;
	
	[[mTextView textStorage] removeAttribute: NSBackgroundColorAttributeName range: allRange];
	[[mTextView textStorage] addAttribute: NSBackgroundColorAttributeName value: [NSColor colorWithCalibratedRed:0.8 green: 1.0 blue: 0.8 alpha: 1.0] range: lineRange];
}


-(void)	setDebuggerUIEnabled: (BOOL)inEnabled
{
	[mStepInstructionButton setEnabled: inEnabled];
	[mContinueButton setEnabled: inEnabled];
	[mExitToTopButton setEnabled: inEnabled];
	[mAddCheckpointButton setEnabled: inEnabled];
	[mRemoveCheckpointButton setEnabled: inEnabled];
}


-(void)	handleWAITOperation: (NSData*)theData
{
	// Enable UI until one of them is used and we've sent a reply to the client.
	[self setDebuggerUIEnabled: YES];
}


-(IBAction)	doStepOneInstruction: (id)sender
{
	[mDebuggerConnection writeCommandWithoutData: "step"];
	
	[self setDebuggerUIEnabled: NO];
}


-(IBAction)	doContinue: (id)sender
{
	[mDebuggerConnection writeCommandWithoutData: "CONT"];

	[self setDebuggerUIEnabled: NO];
}


-(IBAction)	doExitToTop: (id)sender
{
	[mDebuggerConnection writeCommandWithoutData: "EXIT"];

	[self setDebuggerUIEnabled: NO];
}


-(IBAction)	doAddCheckpoint: (id)sender
{
	[mDebuggerConnection writeCommandWithoutData: "+CHK"];

	[self setDebuggerUIEnabled: NO];
}


-(IBAction)	doRemoveCheckpoint: (id)sender
{
	[mDebuggerConnection writeCommandWithoutData: "-CHK"];

	[self setDebuggerUIEnabled: NO];
}

@end

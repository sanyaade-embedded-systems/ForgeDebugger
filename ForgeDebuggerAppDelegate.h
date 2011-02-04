//
//  ForgeDebuggerAppDelegate.h
//  ForgeDebugger
//
//  Created by Uli Kusterer on 14.01.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ForgeDebuggerConnection.h"


@class ULINetSocket;


@interface ForgeDebuggerAppDelegate : NSObject <NSApplicationDelegate,ForgeDebuggerSession>
{
    NSWindow		*		mWindow;
	NSTableView		*		mStackTable;
	NSTableView		*		mVariablesTable;
	NSTextView		*		mTextView;
	ULINetSocket	*		mServerSocket;
	ForgeDebuggerConnection*mDebuggerConnection;
	NSMutableArray	*		mVariables;
	NSMutableArray	*		mHandlers;
	NSButton		*		mStepInstructionButton;
	NSButton		*		mContinueButton;
	NSButton		*		mExitToTopButton;
	NSButton		*		mAddCheckpointButton;
	NSButton		*		mRemoveCheckpointButton;
}

@property (assign) IBOutlet NSWindow		*		window;
@property (assign) IBOutlet NSTableView		*		stackTable;
@property (assign) IBOutlet NSTableView		*		variablesTable;
@property (assign) IBOutlet NSTextView		*		textView;
@property (assign) IBOutlet NSButton		*		stepInstructionButton;
@property (assign) IBOutlet NSButton		*		continueButton;
@property (assign) IBOutlet NSButton		*		exitToTopButton;
@property (assign) IBOutlet NSButton		*		addCheckpointButton;
@property (assign) IBOutlet NSButton		*		removeCheckpointButton;

-(IBAction)	doStepOneInstruction: (id)sender;
-(IBAction)	doContinue: (id)sender;
-(IBAction)	doExitToTop: (id)sender;
-(IBAction)	doAddCheckpoint: (id)sender;
-(IBAction)	doRemoveCheckpoint: (id)sender;

@end

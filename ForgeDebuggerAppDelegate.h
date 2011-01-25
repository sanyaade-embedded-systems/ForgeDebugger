//
//  ForgeDebuggerAppDelegate.h
//  ForgeDebugger
//
//  Created by Uli Kusterer on 14.01.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class ULINetSocket;


@interface ForgeDebuggerAppDelegate : NSObject <NSApplicationDelegate>
{
    NSWindow		*		mWindow;
	NSTableView		*		mStackTable;
	NSTableView		*		mVariablesTable;
	NSTextView		*		mTextView;
	ULINetSocket	*		mServerSocket;
	ULINetSocket	*		mClientSocket;
}

@property (assign) IBOutlet NSWindow		*		window;
@property (assign) IBOutlet NSTableView		*		stackTable;
@property (assign) IBOutlet NSTableView		*		variablesTable;
@property (assign) IBOutlet NSTextView		*		textView;

@end

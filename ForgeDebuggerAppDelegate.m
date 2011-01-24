//
//  ForgeDebuggerAppDelegate.m
//  ForgeDebugger
//
//  Created by Uli Kusterer on 14.01.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "ForgeDebuggerAppDelegate.h"
#import "NetSocket.h"
#import "ForgeDebuggerConnection.h"

@implementation ForgeDebuggerAppDelegate

@synthesize window = mWindow;
@synthesize stackTable = mStackTable;
@synthesize variablesTable = mVariablesTable;
@synthesize textView = mTextView;

//	int						sockfd,
//							portno,
//							n;
//    struct	sockaddr_in		serv_addr;
//    struct	hostent		*	server = NULL;
//
//    char buffer[256];
//    portno = 13762;
//    sockfd = socket( AF_INET, SOCK_STREAM, 0 );
//    server = gethostbyname( "127.0.0.1" );
//    if( server == NULL )
//	{
//        fprintf(stderr,"ERROR, no such host\n");
//        exit(0);
//    }
//    bzero((char *) &serv_addr, sizeof(serv_addr));
//    serv_addr.sin_family = AF_INET;
//    bcopy((char *)server->h_addr, 
//         (char *)&serv_addr.sin_addr.s_addr,
//         server->h_length);
//    serv_addr.sin_port = htons(portno);
//    if (connect(sockfd,&serv_addr,sizeof(serv_addr)) < 0) 
//        error("ERROR connecting");
//    printf("Please enter the message: ");
//    bzero(buffer,256);
//    fgets(buffer,255,stdin);
//    n = write(sockfd,buffer,strlen(buffer));
//    if (n < 0) 
//         error("ERROR writing to socket");
//    bzero(buffer,256);
//    n = read(sockfd,buffer,255);
//    if (n < 0) 
//         error("ERROR reading from socket");
//    printf("%s\n",buffer);
//    return 0;



- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	mServerSocket = [[NetSocket netsocketListeningOnRandomPort] retain];
	[mServerSocket setDelegate: self];
	[mServerSocket scheduleOnCurrentRunLoop];
	
	mClientSocket = [[NetSocket netsocketConnectedToHost: @"127.0.0.1" port: [mServerSocket localPort]] retain];
	[mClientSocket scheduleOnCurrentRunLoop];
	[mClientSocket setDelegate: self];
	
	[NSTimer scheduledTimerWithTimeInterval: 2.0 target: self selector: @selector(timerAction:) userInfo: nil repeats: YES];
}


-(void)	timerAction: (NSTimer*)theTimer
{
	[mClientSocket writeString: @"AAAABBBB" encoding: NSASCIIStringEncoding];
}


- (void)netsocketConnected:(NetSocket*)inNetSocket
{
	NSLog(@"A Connected.");
}


- (void)netsocket:(NetSocket*)inNetSocket connectionTimedOut:(NSTimeInterval)inTimeout
{
	NSLog(@"A Connection timed out.");
}


- (void)netsocketDisconnected:(NetSocket*)inNetSocket
{
	NSLog(@"A Disconnected.");
}


- (void)netsocket:(NetSocket*)inNetSocket connectionAccepted:(NetSocket*)inNewNetSocket
{
	NSLog(@"A Connection accepted.");
	
	(ForgeDebuggerConnection*)[[ForgeDebuggerConnection alloc] initWithSocket: inNewNetSocket];
}


- (void)netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
	NSLog(@"A Data Available.");
}


- (void)netsocketDataSent:(NetSocket*)inNetSocket
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
	return 0;
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return @"Meglon?";
}

@end

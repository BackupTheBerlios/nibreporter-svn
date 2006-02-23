//  AppController.m
//  NibReporter
//  Created by Keith Wilson on 8/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.

#import "AppController.h"
#import "MyDocument.h"
#import "Utils.h"

@implementation AppController
// *****************************************************************************
-(void)applicationDidFinishLaunching:(NSNotification*)notification
{
	//DisplayMsg(@"Open a nib file using menu option: \n\nFile - Open or\nFile - Open Recent");
	NSDocumentController *dc = [NSDocumentController sharedDocumentController];
	// :mattneub:20060223 
	// I found this whole automatic-opening foo really annoying:
	// I'm the user, if I want to open something let me open it
	// also it was making debugging damned near impossible
	/*
	id doc;
	NSArray *urls = [dc recentDocumentURLs];
	if([urls count])
		{	NSError *outError = nil;
			doc = [dc openDocumentWithContentsOfURL:[[urls objectAtIndex:0] absoluteURL] display:YES error:&outError];
		}
	if(!doc)	
	 */
		[dc openDocument:self]; //invoke the file open dialog
}
// *****************************************************************************
-(BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}
// *****************************************************************************
-(IBAction)	displayClasses:(id)sender
{
	MyDocument *doc = [[NSDocumentController sharedDocumentController] currentDocument];
	[doc displayClasses];
}
// *****************************************************************************
-(IBAction)	displayNibtoolErrors:(id)sender
{
	NSDocument *doc = [[NSDocumentController sharedDocumentController] currentDocument];
	NSString *errMessage = [doc valueForKey:@"nibtoolErrorMessages"];
	if(errMessage && [errMessage length])
		DisplayMsg(errMessage);
	else
		DisplayMsg(@"%@\n\nNo errors were reported by nibtool", [[doc fileName] lastPathComponent]);
}
// *****************************************************************************
-(IBAction)printReport:(id)sender
{
	DisplayMsg(@"Please use the source code (it's free) to generate your own reports");
}
// *****************************************************************************
@end

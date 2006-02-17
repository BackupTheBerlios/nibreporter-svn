//  AppController.h
//  NibReporter
//  Created by Keith Wilson on 8/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject 
{
}
-(void)		applicationDidFinishLaunching:(NSNotification*)notification;
-(BOOL)		applicationShouldOpenUntitledFile:(NSApplication *)sender;
-(IBAction)	displayClasses:(id)sender;
-(IBAction)	displayNibtoolErrors:(id)sender;
-(IBAction) printReport:(id)sender;
	
@end

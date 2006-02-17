//  NibClassesDialogController.h
//  NibReporter
//  Created by Keith Wilson on 16/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.

#import <Cocoa/Cocoa.h>

@interface NibClassesDialogController : NSWindowController 
{
	IBOutlet NSTableView		*tv;
	IBOutlet NSArrayController *arrayController;

	NSArray	*classesSortDescriptors;

	NSManagedObjectContext	*moc;
}
-(id)			init;
-(void)		dealloc;
-(float)		tableView:(NSTableView *)tableView heightOfRow:(int)row;
-(BOOL)		windowShouldClose:(id)sender;
@end

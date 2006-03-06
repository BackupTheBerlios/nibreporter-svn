//  NibClassesDialogController.m
//  NibReporter
//  Created by Keith Wilson on 16/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.

//:KSW 06-Mar-06 added include Utils.h for SetFontSize proptotype 
#import "NibClassesDialogController.h"
#import "NibClass.h"
#include "Utils.h"  

@implementation NibClassesDialogController
// *****************************************************************************
-(id)init
{
	if(self = [super initWithWindowNibName:@"NibClasses"])
		{	NSSortDescriptor *sortByClass = [[[NSSortDescriptor alloc] initWithKey:@"nibClass" ascending:YES] autorelease];
			[self setValue:[NSArray arrayWithObject:sortByClass] forKey:@"classesSortDescriptors"];
		}
return self;
}
// *****************************************************************************
-(void)dealloc
{
	[moc release];
	[super dealloc];
}
// *****************************************************************************
// *****************************************************************************
-(void)awakeFromNib
{
	SetFontSize(tv, 11.0, 1.0);
}
// *****************************************************************************
- (float)tableView:(NSTableView *)tableView heightOfRow:(int)row
{
	NibClass *nibClass = [[arrayController arrangedObjects] objectAtIndex:row];
	int maxRows = MAX([[nibClass valueForKey:@"actions"] count], [[nibClass valueForKey:@"outlets"] count]);
return (int)(1.3 * 11.0 * MAX(1, maxRows)); 	
}
// *****************************************************************************
-(BOOL)windowShouldClose:(id)sender
{
	//must disconnect the parent-child relationship between the windows before closing else
	//the parent will get closed as well
	[[[self window] parentWindow] removeChildWindow:[self window]];
return YES;
}
// *****************************************************************************
@end

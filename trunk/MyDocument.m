//  MyDocument.m
//  NibReporter
//  Created by Keith Wilson on 7/02/06.
//  Copyright __MyCompanyName__ 2006 . All rights reserved.

#import "MyDocument.h"
#import "NRConnector.h"
#import "Utils.h"

//:KSW 02-Mar-06 - please note the following note on database design:
//In the datamodel the object and connection property are represented as separete Entities which
//means that during loading of the data a separate managedObject must be created for each property instance.
//For a large Nib file the nibtool extract run takes approx 2 seconds and the loading of the 
//CoreData store takes a further 2 seconds. The time to load the CoreData model can be
//reduced to 50 milliseconds by archiving the property data for each object into a Dictionary (NSData) attribute
//and subsequently unarchiving the property data as and when needed. Although the code becomes only slightly
//more complex I have left it as is to simplify access for report writing by future developers.

//:KSW 04-Mar-06 added gDestination
static NibObject *gDestination = nil;

@implementation MyDocument
// *****************************************************************************
-(id)init
{
	if(self = [super init])
		{	NSSortDescriptor *sortByClass	 = [[[NSSortDescriptor alloc] initWithKey:@"pConnection.connectionClass" ascending:YES] autorelease];
			NSSortDescriptor *sortByFlipped = [[[NSSortDescriptor alloc] initWithKey:@"isFlipped" ascending:YES] autorelease];
			[self setValue:[NSArray arrayWithObjects:sortByClass, sortByFlipped, nil] forKey:@"connectionsSortDescriptors"];

			NSSortDescriptor *sortByType = [[[NSSortDescriptor alloc] initWithKey:@"type" ascending:YES] autorelease];
			[self setValue:[NSArray arrayWithObject:sortByType] forKey:@"propertiesSortDescriptors"];

			NSSortDescriptor *sortObjectsByLongName = [[[NSSortDescriptor alloc] initWithKey:@"longName" ascending:YES] autorelease];
			[self setValue:[NSArray arrayWithObject:sortObjectsByLongName] forKey:@"hierarchySortDescriptors"];
			// :mattneub:20060223 - added 3 retains
			// :KSW 02-Mar-06 removed Matt's retains - agreed with Matt as not needed
			nibtoolErrorMessages = nil;
		}
	return self;
}
// *****************************************************************************
// :mattneub:20060223 - added dealloc for memory management
-(void)dealloc 
{
	[self->connectionsSortDescriptors release];
	[self->propertiesSortDescriptors release];
	[self->hierarchySortDescriptors release];
	[self->nibClassesDialogController release];
	[self->nibtoolErrorMessages release];
	[super dealloc];
}
// *****************************************************************************
-(void)awakeFromNib
{
	float fontSize = 11.0;
	SetFontSize(olv, fontSize, 1);
	SetFontSize(tvConns, fontSize, 2.5); //two lines of data
	SetFontSize(tvObsProps, fontSize, 1);
	SetFontSize(tvObsProps2, fontSize, 1);
	SetFontSize(tvConnsProps, fontSize, 1);
}
// *****************************************************************************
-(IBAction)collapseAll:(id)sender
{
	id item = [olv itemAtRow:0];
	[olv collapseItem:item  collapseChildren:YES];
}
// *****************************************************************************
-(void)displayClasses
{
	if(!nibClassesDialogController)
		{	if(!(nibClassesDialogController = [[NibClassesDialogController alloc] init]))
				return;
			[[nibClassesDialogController window] center]; 
		}
	[[olv window] addChildWindow:[nibClassesDialogController window] ordered:NSWindowAbove];
	[[nibClassesDialogController window] setTitle:[NSString stringWithFormat:@"Classes in %@", [[self fileName] lastPathComponent]]];
	[[nibClassesDialogController window] makeKeyAndOrderFront:self]; 
	[nibClassesDialogController setValue:moc forKey:@"moc"];
}
// *****************************************************************************
-(IBAction)expandAll:(id)sender
{
	id item = [olv itemAtRow:0];
	[olv collapseItem:item  collapseChildren:YES];//collapse first row so the expand always works
	[olv expandItem:item expandChildren:YES];
}
// *****************************************************************************
-(void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSOutlineView *ov = [notification object];
	if(ov == olv)
		{	NSArray *hierarchySelections = [objectsTreeController selectedObjects];
			if([hierarchySelections count] == 1)
				{	NSManagedObject *hierarchySelection = [hierarchySelections objectAtIndex:0];
					NSMutableArray *array = [[NSMutableArray alloc] init];
					NSSet *connsSet = [hierarchySelection valueForKey:@"allConnections"];
					NSEnumerator *e = [connsSet objectEnumerator];
					id connection;
					while(connection = [e nextObject])
						{	NRConnector *conn = [[NRConnector alloc] init];
							[conn setValue:hierarchySelection forKey:@"pHierObj"];
							[conn setValue:connection forKey:@"pConnection"];
							id source = [connection valueForKey:@"source"];
							id dest   = [connection valueForKey:@"destination"];
							if(source == hierarchySelection)
								{	[conn setValue:dest forKey:@"pOtherObj"];
									[conn setValue:[NSNumber numberWithBool:NO] forKey:@"isFlipped"];
								}
							else if (dest == hierarchySelection)
								{  [conn setValue:source forKey:@"pOtherObj"];
									[conn setValue:[NSNumber numberWithBool:YES] forKey:@"isFlipped"];
								}
							[array addObject:conn];
							[conn release];
						}				
					[self setValue:array forKey:@"connectionsArray"];
					[array release];
					[connsArrayController setSelectionIndexes:nil];
					[connsArrayController setSelectionIndex:0];
				}
			//KSW 06-Mar-06 added next 4 lines for case where no connections in connsArray - to remove previous highlighted row in olv
			if([[connsArrayController arrangedObjects] count] == 0)
				{	gDestination = nil;
					[olv reloadData];
				}
		}
}
// *****************************************************************************
//:KSW 04-Mar-06 added willDisplayCell - to highlight the otherObject (destination) of the Connection
-(void)outlineView:(NSOutlineView*)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	//NOTE WELL: this method uses an undocumented private method observedObject of _NSArrayControllerTreeNode

	id observedObject = [item observedObject]; //observedObject is an undocumented method and causes the compiler to issue a warning
	if(observedObject == gDestination) 
		[cell setTextColor:[NSColor redColor]];
	else
		[cell setTextColor:[NSColor blackColor]];
}
// *****************************************************************************
//:KSW 04-Mar-06 added toolTipForCell for OutlineView
-(NSString*)outlineView:(NSOutlineView*)ov toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation
{
	return [cell stringValue];
}
// *****************************************************************************
//:KSW 04-Mar-06 added tableViewSelectionDidChange
-(void)tableViewSelectionDidChange:(NSNotification*)notification
{
	//whenever the selectedObject in the Connections is changed then highlight the destination object in the hierarchy (if it is showing)
	NSTableView *tv = [notification object];
	if(tv != tvConns)
		return;
	gDestination = nil;
	int row = [tvConns selectedRow];
	if((row < 0) || (row >= [[connsArrayController arrangedObjects] count]))
		return;
	NRConnector *connector = [[connsArrayController arrangedObjects] objectAtIndex:row];
	NibObject *pOtherObj = [connector valueForKey:@"pOtherObj"];
	gDestination = pOtherObj;
	[olv reloadData]; //during reload the pOtherObj will be highlighted in red
}
// *****************************************************************************
//:KSW 04-Mar-06 added toolTipForCell for TableViews - added delegate connections in nib file for 3 tableViews
-(NSString*)tableView:(NSTableView*)tableView toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn*)tc row:(int)row mouseLocation:(NSPoint)mouseLocation
{
	return [cell stringValue];
}
// *****************************************************************************
-(BOOL)readFromFileWrapper:(NSFileWrapper*)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError
{
	NSFileManager *fm = [NSFileManager defaultManager];
	// put working files in temporary items directory, don't shmock up user's stuff // :mattneub:20060223
	// it is probably something like /var/tmp/folders.501/TemporaryItems
	// NSString *nibReportsPath = [@"~/NibReporter_WorkFiles" stringByExpandingTildeInPath];
	NSString *nibReportsPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"NibReporter_WorkFiles"];
	// :mattneub:20060223 
	//BOOL isDir = FALSE;
	// next line was meaningless since if test 1 succeeds (no file) test 2 will never be true...
	// ...and if test 1 fails (there is a file) test 2 will never even be tested
	// if(![fm fileExistsAtPath:nibReportsPath isDirectory:&isDir] && isDir)
	// I don't see why we need to test for anything at all, frankly
	[fm createDirectoryAtPath:nibReportsPath attributes:nil];

	NSString *nibFilename = [fileWrapper filename];
	if([typeName isEqualToString:@"NibFile"])
		{	//create an output file for nibtool in directory nibReportsPath
			NSString *outfile = [NSString stringWithFormat:@"%@/%@.txt",
										nibReportsPath, 
										[[fileWrapper filename] stringByDeletingPathExtension]];
			[fm createFileAtPath:outfile contents:nil attributes:nil];
			NSFileHandle *outfileHandle = [NSFileHandle fileHandleForWritingAtPath:outfile];

			//the fileWrapper (in memory) does not know the original directory it came from
			// so write the nib to a temporary file
			NSString *tempFile = [NSString stringWithFormat:@"%@/temp.nib", nibReportsPath];
			[fileWrapper writeToFile:tempFile atomically:YES updateFilenames:YES];

			//create an autoreleased pipe for the nibtool error messages
			NSPipe *pipe = [NSPipe pipe]; 
			NSFileHandle *pipeHandle = [pipe fileHandleForWriting];

			//extract the info using nibtool
			NSArray *args = [NSArray arrayWithObjects:@"-a", @"-8", tempFile, nil];
			NSTask *task = [[NSTask alloc] init];
			[task setLaunchPath:@"/usr/bin/nibtool"];
			[task setArguments:args];
			[task setStandardOutput:outfileHandle];
			[task setStandardError:pipeHandle];
			[task launch];
			[task waitUntilExit];
			[task release];
			[outfileHandle closeFile];

			//delete the temporary nib file
			[fm removeFileAtPath:tempFile handler:nil];
			
			//display the nibtool error messages (if any)
			[pipeHandle closeFile];	//		
			pipeHandle = [pipe fileHandleForReading];
			NSData *data = [pipeHandle readDataToEndOfFile];
			if([data length]) {	
				NSString *s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
				// need some sort of memory management policy here; at the very least let's release before setting to alloc'd value
				[self->nibtoolErrorMessages release];
				nibtoolErrorMessages = [[NSString alloc] initWithFormat:@"Error messages from nibtool while processing %@\n\n%@", nibFilename, s];
				DisplayMsg(nibtoolErrorMessages);
			}
			//process the data and load the InMemory data store
			[self replaceUnescapedDoubleQuotes:outfile];
			[self extractPropertiesFromFile:outfile];
			NSLog(@"Num Registered Objects in moc = %ld", [[moc registeredObjects] count]);
			return TRUE;
		}
	return FALSE;
}
// *****************************************************************************
-(void)windowControllerDidLoadNib:(NSWindowController *) aController
{
   [super windowControllerDidLoadNib:aController];
	[[aController window] center]; 	
	//[[aController window] cascadeTopLeftFromPoint:NSMakePoint(0, 1)];
}
// *****************************************************************************
-(NSString*)windowNibName
{
	return @"MyDocument";
}
// *****************************************************************************
@end

//  MyDocument.m
//  NibReporter
//  Created by Keith Wilson on 7/02/06.
//  Copyright __MyCompanyName__ 2006 . All rights reserved.

#import "MyDocument.h"
#import "NRConnector.h"
#import "Utils.h"

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

			nibtoolErrorMessages = nil;
		}
	return self;
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
		}
}
// *****************************************************************************
-(BOOL)readFromFileWrapper:(NSFileWrapper*)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *nibReportsPath = [@"~/NibReporter_WorkFiles" stringByExpandingTildeInPath];
	BOOL isDir = FALSE;
	if(![fm fileExistsAtPath:nibReportsPath isDirectory:&isDir] && isDir)
		[fm createDirectoryAtPath:nibReportsPath attributes:nil];

	NSString *nibFilename = [fileWrapper filename];
	if([typeName isEqualToString:@"NibFile"])
		{	
			//create an output file for nibtool in directory nibReportsPath
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
			if([data length])
				{	NSString *s  = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
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

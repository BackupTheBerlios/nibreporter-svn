//  MyDocument.m
//  NibReporter
//  Created by Keith Wilson on 7/02/06.
//  Copyright __MyCompanyName__ 2006 . All rights reserved.

#import "MyDocument.h"
#import "Utils.h"
#import "NRConnector.h";

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
	[self setFontSize:olv];
	[self setFontSize:tvConns];
	[self setFontSize:tvObsProps];
	[self setFontSize:tvObsProps2];
	[self setFontSize:tvConnsProps];
}
// *****************************************************************************
-(void)creatManagedObjectContext
{
	NSError *error;
	NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:nil];
	moc = [[NSManagedObjectContext alloc] init];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
	[moc setPersistentStoreCoordinator: psc];
	[psc release];
	id newStore = [psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
	if(!newStore)
		NSLog(@"Store Configuration Failure\n%@", ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error");
}
// *****************************************************************************
-(int)displayQuotesAlert:(NSString*)filename :(int)line
{
	NSLog(@"bad doubleQuote replaced in line %ld", line);
	NSAlert *alert = [[NSAlert alloc] init];
	NSString *alertString = [NSString stringWithFormat:@"There is an error in the plist file\nRefer: %@ \n at line number %ld", filename, line];
	[alert setInformativeText:	[NSString stringWithFormat:@"The error is an unexpected double quote that should be replaced with a single quote"]];
	[alert addButtonWithTitle:@"replace them all, don't ask again"];
	[alert addButtonWithTitle:@"replace it"];
	[alert addButtonWithTitle:@"leave it alone"];
	[alert setMessageText:alertString];
	int rc = [alert runModal];
	[alert release];

return rc == NSAlertFirstButtonReturn ? 2 : rc == NSAlertSecondButtonReturn ? 1 : 0;
}
// *****************************************************************************
-(IBAction)expandAll:(id)sender
{
	id item = [olv itemAtRow:0];
	[olv collapseItem:item  collapseChildren:YES];//collapse first row so the expand always works
	[olv expandItem:item expandChildren:YES];
}
// *****************************************************************************
-(void)extractPropertiesFromFile:(NSString*)path
{
	NSString *errorString;
	NSPropertyListFormat format;
	id plist;
	NSData *plistData = [NSData dataWithContentsOfFile:path];
	if(!(plist = [NSPropertyListSerialization propertyListFromData:plistData
                                mutabilityOption:NSPropertyListMutableContainers
                                format:&format
                                errorDescription:&errorString]))
		{	NSLog(errorString);
			[errorString release];
		}
	NSDictionary *objects = [plist objectForKey:@"Objects"];
	NSDictionary *connections = [plist objectForKey:@"Connections"];
	//NSDictionary *classes = [plist objectForKey:@"Classes"]; //the classes info is not used anywhere
	NSDictionary *hierarchy = [plist objectForKey:@"Hierarchy"];

	objectIdsXrefs = [[NSMutableDictionary alloc] init];
	[self creatManagedObjectContext];      //  12 msec
	[self loadObjects:objects];				// 488 msec
	[self loadConnections:connections];		// 194 msec
	[self loadHierarchy:hierarchy :nil];	//  58 msec
	[objectIdsXrefs release];

	NSError *error = nil;
	[moc save:&error];							// 288 msec

	//total to load/save large nib file = 1.11 seconds
}
// *****************************************************************************
-(void)loadConnections:(NSDictionary*)connections
{
	NSEnumerator *e = [connections keyEnumerator];
	NSString *key;
	while(key = [e nextObject])
		{	NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:@"Connection" inManagedObjectContext:moc];
			NSArray *words = [key componentsSeparatedByString:@" "];
			if([words count] != 2)
				{	DisplayMsg(@"%@\n\nwords count error at line %ld", [[self fileName] lastPathComponent], __LINE__);
					continue;
				}
			[mo setValue:[NSNumber numberWithInt:[[words objectAtIndex:1] intValue]] forKey:@"connectionId"];
			NSDictionary *properties = [connections valueForKey:key]; 
			NSEnumerator *e2 = [properties keyEnumerator];
			NSString *pKey;
			while(pKey = [e2 nextObject])
				{	NSMutableString *propertyValue = [NSMutableString stringWithString:[properties valueForKey:pKey]];
					while([propertyValue rangeOfString:@"  "].location != NSNotFound)
						[propertyValue replaceOccurrencesOfString:@"  " withString:@" " options:0 range:NSMakeRange(0, [propertyValue length])];
					if([pKey isEqualToString:@"Class"])
						{	if([propertyValue isEqualToString:@"NSNibBindingConnector"])
								[mo setValue:@"Binding" forKey:@"connectionClass"];
							else if ([propertyValue isEqualToString:@"NSNibOutletConnector"])
								[mo setValue:@"Outlet" forKey:@"connectionClass"];
							else if ([propertyValue isEqualToString:@"NSNibControlConnector"])
								[mo setValue:@"Action" forKey:@"connectionClass"];
							else		
								[mo setValue:propertyValue forKey:@"connectionClass"];
						}	
					if([pKey isEqualToString:@"Source"] || 
						[pKey isEqualToString:@"Destination"] || 
						[pKey isEqualToString:@"Object"] || 
						[pKey isEqualToString:@"Controller"])
						{	int objectId = [propertyValue intValue];
							id object = nil;
							if(object = [objectIdsXrefs objectForKey:[NSString stringWithFormat:@"%ld", objectId]])
								{	NSMutableSet *set = [object mutableSetValueForKey:@"allConnections"];
									if([pKey isEqualToString:@"Source"])
										{	[mo setValue:object forKey:@"source"];
											[set addObject:mo];
										}
									else if([pKey isEqualToString:@"Destination"])
										{	[mo setValue:object forKey:@"destination"];
											[set addObject:mo];
										}
									else if([pKey isEqualToString:@"Controller"])
										{	[mo setValue:object forKey:@"source"];
											[set addObject:mo];
										}
									else if([pKey isEqualToString:@"Object"])
										{	[mo setValue:object forKey:@"destination"];
											[set addObject:mo];
										}
								}
							else
								{	DiplayMsg(@"Cannot find ObjectId %ld", objectId);
									continue;
								}
						}
					//some of these props will duplicate the attributes of mo - but it's a read only database so who cares
					NSManagedObject *mop = [NSEntityDescription insertNewObjectForEntityForName:@"ConnectionProperty" inManagedObjectContext:moc];
					[mop setValue:pKey forKey:@"type"];
					[mop setValue:propertyValue forKey:@"value"];
					[mop setValue:mo forKey:@"owner"];
				}
		}			
}
// *****************************************************************************
-(void)loadHierarchy:(NSDictionary*)hierarchy :(NSManagedObject*)parentObject
{
	//recurse through the hierarchical plist
	NSEnumerator *e = [hierarchy keyEnumerator];
	NSString *key;
	id childObject = nil;
	while(key = [e nextObject])
		{	NSArray *words = [key componentsSeparatedByString:@" "];
			if(![words count])
				continue;
			//find the object and add a child unless it is a leaf object
			if([words count] > 1)
				{	int objectId = [[words objectAtIndex:1] intValue];
					if(childObject = [objectIdsXrefs objectForKey:[NSString stringWithFormat:@"%ld", objectId]])
						{	NSMutableSet *set = [parentObject mutableSetValueForKey:@"children"];
							[set addObject:childObject];
						}	
				}
			if(!childObject)
				continue;
			id value = [hierarchy valueForKey:key];
			if([value isKindOfClass:[NSDictionary class]])
				[self loadHierarchy:value :childObject];
		}
}
// *****************************************************************************
-(void)loadObjects:(NSDictionary*)objects
{
	NSEnumerator *e = [objects keyEnumerator];
	NSString *key;
	while(key = [e nextObject])
		{	NSArray *words = [key componentsSeparatedByString:@" "];
			if([words count] != 2)
				{	DisplayMsg(@"%@\n\nwords count error at line %ld", [[self fileName] lastPathComponent], __LINE__);
					continue;
				}
			NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:@"NibObject" inManagedObjectContext:moc];
			[mo setValue:[NSNumber numberWithInt:[[words objectAtIndex:1] intValue]] forKey:@"objectId"];
			[objectIdsXrefs setObject:mo forKey:[words objectAtIndex:1]];

			//add the objectId as a property so it displays in the properties tables
			NSManagedObject *mop = [NSEntityDescription insertNewObjectForEntityForName:@"ObjectProperty" inManagedObjectContext:moc];
			[mop setValue:@"Object Id" forKey:@"type"];
			[mop setValue:[words objectAtIndex:1] forKey:@"value"];
			[mop setValue:mo forKey:@"owner"];

			NSDictionary *properties = [objects valueForKey:key]; 
			NSEnumerator *e2 = [properties keyEnumerator];
			NSString *pKey;
			while(pKey = [e2 nextObject])
				{	NSMutableString *propertyValue = [NSMutableString stringWithString:[properties valueForKey:pKey]];
					while([propertyValue rangeOfString:@"  "].location != NSNotFound)
						[propertyValue replaceOccurrencesOfString:@"  " withString:@" " options:0 range:NSMakeRange(0, [propertyValue length])];
					if([pKey isEqualToString:@"Class"])
						[mo setValue:propertyValue forKey:@"objectClass"];
					NSManagedObject *mop = [NSEntityDescription insertNewObjectForEntityForName:@"ObjectProperty" inManagedObjectContext:moc];
					[mop setValue:pKey forKey:@"type"];
					[mop setValue:propertyValue forKey:@"value"];
					[mop setValue:mo forKey:@"owner"];
				}
		}			
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

			return TRUE;
		}
return FALSE;
}
// *****************************************************************************
-(void)replaceUnescapedDoubleQuotes:(NSString*)filename
{
	// scan for doubleQuotes and then scan up to the next unnested semicolon
	// replacing all the intermediate double quote with a single quote
	//double quote errors occur in the plist file for iBDeclaredKeys (and some others)

	NSMutableString  *fc = [NSMutableString stringWithContentsOfFile:filename];
	int *errLines = calloc(0, 0); 
	int kk, line = 1, nests = 0, numReplaced = 0;
	UniChar ch;
	BOOL displayAlert = TRUE;
	for(kk = 0; kk < [fc length]; kk++)
		{	ch = [fc characterAtIndex:kk];
			switch(ch)
				{	case '\n':
						line++;
						break;
					case '\"': //then scan up to next unnested = or ;
						nests = 0;
						BOOL getMore = FALSE;
						for(++kk; kk < [fc length]; kk++)
							{	ch = [fc characterAtIndex:kk];
								switch(ch)
									{	case '\n':
											if(nests)
												[fc replaceCharactersInRange:NSMakeRange(kk, 1) withString:@" "];//will remove double spaces later
											line++;
											break;
										case '{':
										case '(': //to handle the special case for iBDeclaredKeys
											nests++; 
											break;
										case '}':
										case ')': //to handle the special case for iBDeclaredKeys
											nests--; 
											break;
										case ';': 
										case '=':
											if(!nests)
												getMore = TRUE;
											break;
										case '\"':
											if(nests)
												{	int rc = 1; //default to replace unless told otherwise
													if(displayAlert)
														{	rc = [self displayQuotesAlert:filename :line]; //0 = do nothing, 1 = replace, 2 - replace all
															if(rc == 2)
																displayAlert = FALSE;
														}
													if(rc)
														{	[fc replaceCharactersInRange:NSMakeRange(kk, 1) withString:@"\'"];
															numReplaced++;
															errLines = realloc(errLines, numReplaced * sizeof(int));
															errLines[numReplaced - 1] = line;
														}
												}
											else
												getMore = TRUE;
											break;
									}
								if(getMore)	
									break;
							}						
				}
		}
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filename];
	[fileHandle writeData:[fc dataUsingEncoding:NSUTF8StringEncoding]];
	[fileHandle closeFile];
	if(numReplaced)
		{	NSMutableString *s = [[NSMutableString alloc] init];
			[s appendFormat:@"%ld double quotes were replaced with single quotes at lines:\n", numReplaced];
			for(kk = 0; kk < numReplaced; kk++)
				{	if((kk == 0) || ((kk > 0) && (errLines[kk] != errLines[kk - 1])))
						[s appendFormat:@"%ld ", errLines[kk]];
				}
			DisplayMsg(@"%@\n\n%@", [[self fileName] lastPathComponent], s);
		}
}
// *****************************************************************************
-(void)setFontSize:(id)tableView 
{	
	float fontSize = 11.0;
	long kk = 0, height = (long)(1.3 * fontSize);
	NSArray *tcArray = [tableView tableColumns];
	for(kk = 0; kk < [tcArray count]; kk++)
		{  NSCell *dataCell = [[tcArray objectAtIndex:kk] dataCell];
			[dataCell setFont:[[NSFontManager sharedFontManager] convertFont:[dataCell font] toSize:fontSize]];
		}
	if(tableView == tvConns)
		[tableView setRowHeight:2.5 * height];
	else	
		[tableView setRowHeight:height];
}
// *****************************************************************************
-(void)windowControllerDidLoadNib:(NSWindowController *) aController
{
   [super windowControllerDidLoadNib:aController];
	[[aController window] center]; 	//[[aController window] cascadeTopLeftFromPoint:NSMakePoint(0, 50)];
}
// *****************************************************************************
-(NSString*)windowNibName
{
	return @"MyDocument";
}
// *****************************************************************************
@end

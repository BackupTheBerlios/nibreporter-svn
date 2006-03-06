//  MyDocument_LoadData.m
//  NibReporter
//  Created by Keith Wilson on 17/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.

#import "MyDocument.h"
//KSW 6-Mar-06 added next line to include prototype(s)
#include "Utils.h" 

@implementation MyDocument (LoadData)
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

	//:KSW 02-Mar-06 added next line - database is read only so do not need undoManager
	[[moc undoManager] disableUndoRegistration];

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
	NSDictionary *classes = [[plist objectForKey:@"Classes"] retain]; 
	NSDictionary *hierarchy = [plist objectForKey:@"Hierarchy"];

	objectIdsXrefs = [[NSMutableDictionary alloc] init];
	[self creatManagedObjectContext];      //  12 msec
	[self loadObjects:objects];				// 488 msec
	[self loadConnections:connections];		// 194 msec
	[self loadClasses:classes];		      //     msec
	[self loadHierarchy:hierarchy :nil];	//  58 msec
	[objectIdsXrefs release];

	NSError *error = nil;
	[moc save:&error];							// 288 msec

	//total to load/save large nib file = 1.11 seconds
}
// *****************************************************************************
-(void)loadClasses:(NSDictionary*)classes
{
	id nextPlistElement = [classes objectForKey:@"IBClasses"];
	if(![nextPlistElement isKindOfClass:[NSArray class]]) 
		{	DisplayMsg(@"unexpected class encountered in plist at line %ld", __LINE__);
			return;
		}
	NSArray *ibClasses = nextPlistElement; //ibClasses is an Array of dictionaries describing each class in the nib file
	int kk;
	for(kk = 0; kk < [ibClasses count]; kk++)
		{	nextPlistElement = [ibClasses objectAtIndex:kk];
			if(![nextPlistElement isKindOfClass:[NSDictionary class]]) 
				{	DisplayMsg(@"unexpected class encountered in plist at line %ld", __LINE__);
					continue;
				}
			NSDictionary *dict = nextPlistElement;
			NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:@"NibClass" inManagedObjectContext:moc];
			NSEnumerator *e = [dict keyEnumerator];
			NSString *key;
			while(key = [e nextObject])
				{	if(![key length])
						continue;
					if([key isEqualToString:@"CLASS"])
						[mo setValue:[dict valueForKey:key] forKey:@"nibClass"];
					else if([key isEqualToString:@"SUPERCLASS"])
						[mo setValue:[dict valueForKey:key] forKey:@"nibSuperClass"];
					else if([key isEqualToString:@"LANGUAGE"])
						[mo setValue:[dict valueForKey:key] forKey:@"language"];
					else if([key isEqualToString:@"ACTIONS"])
						{	nextPlistElement = [dict valueForKey:key];
							if(![nextPlistElement isKindOfClass:[NSDictionary class]]) 
								{	DisplayMsg(@"unexpected class encountered in plist at line %ld", __LINE__);
									continue;
								}
							NSDictionary *actions = nextPlistElement;
							NSEnumerator *eActions = [actions keyEnumerator];
							NSString *key2;
							while(key2 = [eActions nextObject])
								{  if(![key2 length])
										continue;
									NSManagedObject *moAction = [NSEntityDescription insertNewObjectForEntityForName:@"Action" inManagedObjectContext:moc];
									[moAction setValue:key2 forKey:@"name"];
									[moAction setValue:[actions valueForKey:key2] forKey:@"type"];
									[moAction setValue:mo forKey:@"nibClass"];
								}
						}
					else if([key isEqualToString:@"OUTLETS"])
						{	nextPlistElement = [dict valueForKey:key];
							if(![nextPlistElement isKindOfClass:[NSDictionary class]]) 
								{	DisplayMsg(@"unexpected class encountered in plist at line %ld", __LINE__);
									continue;
								}
							NSDictionary *outlets = nextPlistElement;
							NSEnumerator *eOutlets = [outlets keyEnumerator];
							NSString *key3;
							while(key3 = [eOutlets nextObject])
								{	if(![key3 length])
										continue;
									NSManagedObject *moOutlet = [NSEntityDescription insertNewObjectForEntityForName:@"Outlet" inManagedObjectContext:moc];
									[moOutlet setValue:key3 forKey:@"name"];
									[moOutlet setValue:[outlets valueForKey:key3] forKey:@"type"];
									[moOutlet setValue:mo forKey:@"nibClass"];
								}
						}
					else 
						DisplayMsg(@"Classes Key = %@ was ignored", key);
				}
		}
}
// *****************************************************************************
-(void)loadConnections:(NSDictionary*)connections
{
	NSEnumerator *e = [connections keyEnumerator];
	NSString *key;
	while(key = [e nextObject])
		{	if(![key length])
				continue;
			NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:@"Connection" inManagedObjectContext:moc];
			NSArray *words = [key componentsSeparatedByString:@" "];
			if([words count] != 2)
				{	DisplayMsg(@"%@\n\nwords count error at line %ld", [[self fileName] lastPathComponent], __LINE__);
					continue;
				}
			[mo setValue:[NSNumber numberWithInt:[[words objectAtIndex:1] intValue]] forKey:@"connectionId"];
			id nextPlistElement = [connections valueForKey:key];
			if(![nextPlistElement isKindOfClass:[NSDictionary class]]) 
				{	DisplayMsg(@"unexpected class encountered in plist at line %ld", __LINE__);
					continue;
				}
			NSDictionary *properties = nextPlistElement; 
			NSEnumerator *e2 = [properties keyEnumerator];
			NSString *pKey;
			while(pKey = [e2 nextObject])
				{	if(![pKey length])
						continue;
					NSMutableString *propertyValue = [NSMutableString stringWithString:[properties valueForKey:pKey]];
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
								{	//:KSW 06-Mar-06 corrected typo in next line, was Diplay
									DisplayMsg(@"Cannot find ObjectId %ld", objectId);
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
	while(key = [e nextObject])
		{	if(![key length])
				continue;
			NSArray *words = [key componentsSeparatedByString:@" "];
			if(![words count])
				continue;
			//find the object and add a child unless it is a leaf object
			id childObject = nil;
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
		{	if(![key length])
				continue;
			NSArray *words = [key componentsSeparatedByString:@" "];
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

			id nextPlistElement = [objects valueForKey:key]; 
			if(![nextPlistElement isKindOfClass:[NSDictionary class]]) 
				{	DisplayMsg(@"unexpected class encountered in plist at line %ld", __LINE__);
					continue;
				}
			NSDictionary *properties = nextPlistElement; 
			NSEnumerator *e2 = [properties keyEnumerator];
			NSString *pKey;
			while(pKey = [e2 nextObject])
				{	if(![pKey length])
						continue;
					NSMutableString *propertyValue = [NSMutableString stringWithString:[properties valueForKey:pKey]];
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
-(void)replaceUnescapedDoubleQuotes:(NSString*)filename
{
	// scan for doubleQuotes and then scan up to the next unnested semicolon or =
	// replace all the intermediate nested double quote with a single quote

	//For instance:

   //iBDeclaredKeys record as generated by nibtool should be an array = ( .... ) not = "( .... )";
	// - it should not have doubleQuotes before and after the parentheses
	// - to fix iBDeclaredKeys simply make the whole thing into a string
		
	//the Options record as generated by nibtool should be a dictionary = { .... };
	// - error found in Matt Neuburg's nibtool output for: 
	// - Options = "{NSSelectorName = "doDoubleClick:"; }";
	// - it should not have doubleQuotes before and after the curly braces
	// - to fix Options simply make the whole thing into a string

	BOOL doItSilently = TRUE; //toggle TRUE or FALSE to display nibtool records that have been modified by Nib Reporter
	BOOL displayAlert = doItSilently ? FALSE : TRUE;

	NSMutableString  *fc = [NSMutableString stringWithContentsOfFile:filename];

	//:KSW 02-Mar-06 added next 2 lines in case menu in nibtool output are for keyboard shortcuts
	// containing { and } which are not properly output by nibtool and make the nibtool plist invalid
	[fc replaceOccurrencesOfString:@"\"{\"" withString:@"\"L\"" options:0 range:NSMakeRange(0, [fc length])];
	[fc replaceOccurrencesOfString:@"\"}\"" withString:@"\"R\"" options:0 range:NSMakeRange(0, [fc length])];

	int *errLines = calloc(0, 0); 
	int kk, line = 1, nests = 0, numReplaced = 0;
	UniChar ch;
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
											//:KSW 02-Mar-06 added next line to be sure to be sure - should really issue an error message and abort if nests <= 0
											if(nests > 0)
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

	if(!doItSilently && numReplaced)
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

@end

//  MyDocument.h
//  NibReporter
//  Created by Keith Wilson on 7/02/06.
//  Copyright __MyCompanyName__ 2006 . All rights reserved.

#import <Cocoa/Cocoa.h>
#import "NibClassesDialogController.h"

@interface MyDocument : NSDocument
{
	NSManagedObjectContext	*moc;
	NSMutableDictionary		*objectIdsXrefs; 
	NSString						*nibtoolErrorMessages;
	
	IBOutlet NSOutlineView	*olv;
	IBOutlet NSTableView		*tvObsProps;
	IBOutlet NSTableView		*tvObsProps2;
	IBOutlet NSTableView		*tvConns;
	IBOutlet NSTableView		*tvConnsProps;

	IBOutlet NSArrayController	*connsArrayController;
	IBOutlet NSTreeController	*objectsTreeController;
	
	NibClassesDialogController *nibClassesDialogController;

	NSArray	*connectionsSortDescriptors;
	NSArray	*propertiesSortDescriptors;
	NSArray	*hierarchySortDescriptors;

	NSArray	*connectionsArray;
}
-(id)				init;
-(void)			awakeFromNib;
-(IBAction)		collapseAll:(id)sender;
-(void)			displayClasses;
-(IBAction)		expandAll:(id)sender;
-(void)			outlineViewSelectionDidChange:(NSNotification *)notification;
-(BOOL)			readFromFileWrapper:(NSFileWrapper*)fileWrapper ofType:(NSString*)typeName error:(NSError**)outError;
-(void)			windowControllerDidLoadNib:(NSWindowController*)aController;
-(NSString*)	windowNibName;
@end

@interface MyDocument (LoadData)
-(void)			creatManagedObjectContext;
-(int)			displayQuotesAlert:(NSString*)filename :(int)line;
-(void)			extractPropertiesFromFile:(NSString*)path;
-(void)			loadClasses:(NSDictionary*)classes;
-(void)			loadConnections:(NSDictionary*)connections;
-(void)			loadHierarchy:(NSDictionary*)hierarchy :(NSManagedObject*)parentObject;
-(void)			loadObjects:(NSDictionary*)objects;
-(void)			replaceUnescapedDoubleQuotes:(NSString*)filename;
@end


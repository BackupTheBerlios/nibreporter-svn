//  MyDocument.h
//  NibReporter
//  Created by Keith Wilson on 7/02/06.
//  Copyright __MyCompanyName__ 2006 . All rights reserved.

#import <Cocoa/Cocoa.h>

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

	IBOutlet NSSplitView    *svH1;
	IBOutlet NSSplitView    *svH2;
	IBOutlet NSSplitView    *svV1;
	IBOutlet NSSplitView    *svV2;
	
	IBOutlet NSArrayController	*connsArrayController;
	IBOutlet NSTreeController	*objectsTreeController;
	
	NSArray	*connectionsSortDescriptors;
	NSArray	*propertiesSortDescriptors;
	NSArray	*hierarchySortDescriptors;

	NSArray	*connectionsArray;
}
-(id)				init;
-(void)			awakeFromNib;
-(void)			creatManagedObjectContext;
-(int)			displayQuotesAlert:(NSString*)filename :(int)line;
-(IBAction)		expandAll:(id)sender;
-(void)			extractPropertiesFromFile:(NSString*)path;
-(void)			loadConnections:(NSDictionary*)connections;
-(void)			loadHierarchy:(NSDictionary*)hierarchy :(NSManagedObject*)parentObject;
-(void)			loadObjects:(NSDictionary*)objects;
-(void)			outlineViewSelectionDidChange:(NSNotification *)notification;
-(BOOL)			readFromFileWrapper:(NSFileWrapper*)fileWrapper ofType:(NSString*)typeName error:(NSError**)outError;
-(void)			replaceUnescapedDoubleQuotes:(NSString*)filename;
-(void)			setFontSize:(id)tableView;
-(void)			windowControllerDidLoadNib:(NSWindowController*)aController;
-(NSString*)	windowNibName;
@end

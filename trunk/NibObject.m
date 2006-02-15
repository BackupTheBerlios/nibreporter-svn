//  NibObject.m
//  NibReporter
//  Created by Keith Wilson on 13/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.

#import "NibObject.h"

@implementation NibObject
// *****************************************************************************
-(NSString*)longName
{
//could possibly use an AttributedString (to handle the graphics chars in menus) provided the tableViews can handle it properly
	NSMutableString *s = [[[NSMutableString alloc] init] autorelease];
	NSString *otherObjClass = [self propertyValueForType:@"Class"];
	NSString *val;
	[s appendFormat:@" %@", otherObjClass];
	if([otherObjClass isEqualToString:@"NSObjectController"] ||
		[otherObjClass isEqualToString:@"NSArrayController"] ||
		[otherObjClass isEqualToString:@"NSTreeController"] ||
		[otherObjClass isEqualToString:@"NSCustomView"] ||
		[otherObjClass isEqualToString:@"NSCustomObject"] ||
		[otherObjClass isEqualToString:@"NSTableView"] ||
		[otherObjClass isEqualToString:@"NSOutlineView"])
		{	if(val = [self propertyValueForType:@"Name"])
				[s appendFormat:@" \"%@\"", val];
			if(val = [self propertyValueForType:@"CustomClass"])
				[s appendFormat:@" \"%@\"", val];
		}
	else if([otherObjClass isEqualToString:@"NSButton"])
		{	if(val = [self propertyValueForType:@"iBTitle"])
				[s appendFormat:@" \"%@\"", val];
		}
	else if( [otherObjClass isEqualToString:@"NSTableColumn"] ||
				[otherObjClass isEqualToString:@"NSTextField"])
		{	if(val =  [self propertyValueForType:@"stringValue"])
				[s appendFormat:@" \"%@\"", val];
			if(val =  [self propertyValueForType:@"identifier"])
				[s appendFormat:@" \"%@\"", val];
		}
	else if( [otherObjClass isEqualToString:@"NSTabViewItem"])
		{	if(val =  [self propertyValueForType:@"label"])
				[s appendFormat:@" \"%@\"", val];
			if(val =  [self propertyValueForType:@"identifier"])
				[s appendFormat:@" \"%@\"", val];
		}
	else if( [otherObjClass isEqualToString:@"NSMenu"] ||
				[otherObjClass isEqualToString:@"NSMenuItem"])
		{	if(val = [self propertyValueForType:@"title"])
				[s appendFormat:@" \"%@\"", val];
		}
	else if( [otherObjClass isEqualToString:@"NSComboBox"] ||
				[otherObjClass isEqualToString:@"NSComboBoxCell"])
		{	if(val = [self propertyValueForType:@"objectValues"])
				[s appendFormat:@" \"%@\"", val];
		}
return s;
}
// *****************************************************************************
-(NSString*)propertyValueForType:(NSString*)propType
{
	id prop;
	NSString *val = nil;
	NSEnumerator *e = [[self valueForKey:@"properties"] objectEnumerator];
	while(prop = [e nextObject])
		{	if([[prop valueForKey:@"type"] isEqualToString:propType])
				{	if((val = [prop valueForKey:@"value"]) && ![val isEqualToString:@"<null>"])
						return val;
				}
		}
return nil;
}
// *****************************************************************************
@end

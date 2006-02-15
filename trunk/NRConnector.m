//  NRConnector.m
//  NibReporter
//  Created by Keith Wilson on 12/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.

#import "NRConnector.h"

@implementation NRConnector
// *****************************************************************************
-(NSString*)name
{
	NSMutableString *s = [[[NSMutableString alloc] init] autorelease]; 
	NSString *val;
	if(val = [self propertyValueForType:@"Action"])
		[s appendFormat:@"%@", val];
	if(val = [self propertyValueForType:@"Outlet"])
		[s appendFormat:@"%@", val];
	if(val = [self propertyValueForType:@"KeyPath"])
		[s appendFormat:@"%@", val];

	if([[pConnection valueForKey:@"connectionClass"] isEqualToString:@"Binding"])
		[s appendString:@" \n   is bound to"];
	else
		[s appendString:isFlipped ? @" \n   from" : @" \n   to"];
//xx changed 2 lines at line 36 in file:NibConnector.m
	if(val = [pOtherObj longName])
		[s appendString:val];
return s;
}
// *****************************************************************************
-(NSString*)propertyValueForType:(NSString*)propType
{
	id prop;
	NSEnumerator *e = [[pConnection valueForKey:@"properties"] objectEnumerator];
	while(prop = [e nextObject])
		{	if([[prop valueForKey:@"type"] isEqualToString:propType])
				return [prop valueForKey:@"value"];
		}
return nil;
}
// *****************************************************************************
@end

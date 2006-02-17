//
//  NibClass.m
//  NibReporter
//
//  Created by Keith Wilson on 16/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NibClass.h"


@implementation NibClass
// *****************************************************************************
-(NSString*) namesOfActions
{
	NSMutableString *s = [[[NSMutableString alloc] init] autorelease];
	NSArray *array = [[self valueForKey:@"actions"] allObjects];
	NSSortDescriptor *sortByName = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	array = [array sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortByName]];
	int kk;
	for(kk = 0; kk < [array count]; kk++)
		{	id action = [array objectAtIndex:kk];
			if(kk > 0)
				[s appendString:@"\n"];
			[s appendFormat:@"%@   (%@) ", [action valueForKey:@"name"], [action valueForKey:@"type"]];  
		}
return s;
}
// *****************************************************************************
-(NSString*) namesOfOutlets
{
	NSMutableString *s = [[[NSMutableString alloc] init] autorelease];
	NSArray *array = [[self valueForKey:@"outlets"] allObjects];
	NSSortDescriptor *sortByName = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	array = [array sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortByName]];
	int kk;
	for(kk = 0; kk < [array count]; kk++)
		{	id outlet = [array objectAtIndex:kk];
			if(kk > 0)
				[s appendString:@"\n"];
			[s appendFormat:@"%@   (%@) ", [outlet valueForKey:@"name"], [outlet valueForKey:@"type"]];  
		}
return s;
}
// *****************************************************************************
@end

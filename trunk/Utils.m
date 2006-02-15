//  Utils.m
//  NibReporter
//  Created by Keith Wilson on 9/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.

#include "Utils.h"
// *****************************************************************************
void DisplayMsg(NSString *format, ...)
{
	if(format)
		{	va_list argList;
			va_start (argList, format);
			NSString *pString = [[[NSString alloc] initWithFormat:format arguments:argList] autorelease];
			va_end(argList);
			NSAlert *alert = [[NSAlert alloc] init];
			[[alert window] setTitle:@"Nib Reporter"];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:pString];
			[alert runModal];
			[alert release];
		}
}
// *****************************************************************************

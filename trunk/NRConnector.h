//  NRConnector.h
//  NibReporter
//  Created by Keith Wilson on 12/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.

#import "NibObject.h"
#import <Cocoa/Cocoa.h>

@interface NRConnector : NSObject
{
	NibObject			*pHierObj;		//the object selected in the hierarchy
	NSManagedObject	*pConnection;  //a connector for which pHierObs is Source or Target
	NibObject			*pOtherObj;    //the object on the other end from pHieraObs
	BOOL					isFlipped;
}
-(NSString*)	name;
-(NSString*)	propertyValueForType:(NSString*)propType;
@end

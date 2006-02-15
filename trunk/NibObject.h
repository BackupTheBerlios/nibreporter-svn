//  NibObject.h
//  NibReporter
//  Created by Keith Wilson on 13/02/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.

#import <Cocoa/Cocoa.h>

@interface NibObject : NSManagedObject
{
}
-(NSString*)	longName;
-(NSString*)	propertyValueForType:(NSString*)propType;
@end

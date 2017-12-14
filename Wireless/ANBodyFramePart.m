//
//  ANBodyFramePart.m
//
//  Created by Christof Ferreira Torres on 10/12/2017.
//

#import "ANBodyFramePart.h"

@implementation ANBodyFramePart

@synthesize data;
@synthesize typeID;

- (id)initWithType:(UInt8)aTypeID data:(NSData *)theData {
    if ((self = [super init])) {
        data = theData;
        typeID = aTypeID;
    }
    return self;
}

@end

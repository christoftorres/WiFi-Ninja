//
//  ANBodyFramePart.h
//
//  Created by Christof Ferreira Torres on 10/12/2017.
//

#import <Foundation/Foundation.h>

@interface ANBodyFramePart : NSObject {
    NSData * data;
    UInt8 typeID;
}

@property (readonly) NSData * data;
@property (readonly) UInt8 typeID;

- (id)initWithType:(UInt8)aTypeID data:(NSData *)theData;

@end

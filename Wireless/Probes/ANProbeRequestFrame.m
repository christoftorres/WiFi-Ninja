//
//  ANProbeRequestFrame.m
//  JamWiFi
//
//  Created by Christof Ferreira Torres on 10/12/2017.
//

#import "ANProbeRequestFrame.h"

@implementation ANProbeRequestFrame

@synthesize packet;

- (id)initWithPacket:(AN80211Packet *)probeRequest {
    if ((self = [super init])) {
        packet = probeRequest;
        int bodyOffset = 0x0;
        if (bodyOffset >= packet.bodyLength - 4) return nil;
        NSMutableArray * mParts = [NSMutableArray array];
        for (int i = bodyOffset; i < packet.bodyLength - 4; i += 2) {
            UInt8 typeID = packet.bodyData[i];
            UInt8 length = packet.bodyData[i + 1];
            if (length + i + 2 > packet.bodyLength) return nil;
            NSData * data = [NSData dataWithBytes:&packet.bodyData[i + 2] length:length];
            //NSLog(@"Type: %d len: %d data: %@", typeID, length, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            ANBodyFramePart * part = [[ANBodyFramePart alloc] initWithType:typeID data:data];
            [mParts addObject:part];
            i += length;
        }
        probeRequestParts = mParts;
    }
    return self;
}

- (ANBodyFramePart *)probeRequestPartWithID:(UInt8)anID {
    for (ANBodyFramePart * part in probeRequestParts) {
        if ([part typeID] == anID) return part;
    }
    return nil;
}

- (NSString *)ssid {
    ANBodyFramePart * part = [self probeRequestPartWithID:0];
    if (!part) return nil;
    return [[NSString alloc] initWithData:part.data encoding:NSUTF8StringEncoding];
}

@end

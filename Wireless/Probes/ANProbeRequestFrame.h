//
//  ANProbeRequestFrame.h
//  JamWiFi
//
//  Created by Christof Ferreira Torres on 10/12/2017.
//

#import <Foundation/Foundation.h>
#import "AN80211Packet.h"
#import "ANBodyFramePart.h"

@interface ANProbeRequestFrame : NSObject {
    AN80211Packet * packet;
    NSArray * probeRequestParts;
}

@property (readonly) AN80211Packet * packet;

- (id)initWithPacket:(AN80211Packet *)probeRequest;
- (ANBodyFramePart *)probeRequestPartWithID:(UInt8)anID;

- (NSString *)ssid;

@end

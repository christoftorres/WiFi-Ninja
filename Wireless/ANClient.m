//
//  ANClient.m
//  JamWiFi
//
//  Created by Alex Nichol on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ANClient.h"

@implementation ANClient

@synthesize packetCount;
@synthesize deauthsSent;
@synthesize macAddress;
@synthesize bssid;
@synthesize rssi;
@synthesize enabled;
@synthesize probes;

- (id)initWithMac:(const unsigned char *)mac bssid:(const unsigned char *)aBSSID {
    if ((self = [super init])) {
        macAddress = (unsigned char *)malloc(6);
        bssid = (unsigned char *)malloc(6);
        packetCount = 0;
        memcpy(macAddress, mac, 6);
        memcpy(bssid, aBSSID, 6);
        enabled = YES;
        probes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) return NO;
    ANClient * client = (ANClient *)object;
    if (memcmp(client.macAddress, macAddress, 6) == 0) {
        return YES;
    }
    return NO;
}

- (void)dealloc {
    free(macAddress);
    free(bssid);
}

@end

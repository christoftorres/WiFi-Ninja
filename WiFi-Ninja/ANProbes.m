//
//  ANProbes.m
//  JamWiFi
//
//  Created by Alex Nichol on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ANProbes.h"
#import "ANAppDelegate.h"
#import "ANClientKiller.h"
#import "ANBeaconFrame.h"
#import "ANProbeRequestFrame.h"

@implementation ANProbes

- (id)initWithFrame:(NSRect)frameRect sniffer:(ANWiFiSniffer *)aSniffer networks:(NSArray *)theNetworks {
    if ((self = [super initWithFrame:frameRect])) {
        [self configureUI];
        
        networks = theNetworks;
        sniffer = aSniffer;
        allClients = [[NSMutableArray alloc] init];
        
        NSMutableArray * mChannels = [[NSMutableArray alloc] init];
        for (CWNetwork * net in networks) {
            if (![mChannels containsObject:net.wlanChannel]) {
                [mChannels addObject:net.wlanChannel];
            }
        }
        
        channels = [mChannels copy];
        channelIndex = -1;
        [self hopChannel];
        hopTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(hopChannel) userInfo:nil repeats:YES];
        [sniffer setDelegate:self];
        [sniffer start];
    }
    return self;
}

- (void)configureUI {
    NSRect frame = self.frame;
    clientsScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 52, frame.size.width - 20, frame.size.height - 62)];
    clientsTable = [[NSTableView alloc] initWithFrame:[[clientsScrollView contentView] bounds]];
    backButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, 10, 110, 24)];
    
    [backButton setBezelStyle:NSRoundedBezelStyle];
    [backButton setTitle:@"Back"];
    [backButton setFont:[NSFont systemFontOfSize:13]];
    [backButton setTarget:self];
    [backButton setAction:@selector(backButton:)];
    
    NSTableColumn * stationColumn = [[NSTableColumn alloc] initWithIdentifier:@"station"];
    [[stationColumn headerCell] setStringValue:@"Station"];
    [stationColumn setWidth:120];
    [stationColumn setEditable:NO];
    [clientsTable addTableColumn:stationColumn];
    
    NSTableColumn * packetsColumn = [[NSTableColumn alloc] initWithIdentifier:@"count"];
    [[packetsColumn headerCell] setStringValue:@"Probe Requests"];
    [packetsColumn setWidth:100];
    [packetsColumn setEditable:NO];
    [clientsTable addTableColumn:packetsColumn];
    
    NSTableColumn * probesColumn = [[NSTableColumn alloc] initWithIdentifier:@"probes"];
    [[probesColumn headerCell] setStringValue:@"Probes"];
    [probesColumn setWidth:190];
    [probesColumn setEditable:NO];
    [clientsTable addTableColumn:probesColumn];
    
    NSTableColumn * rssiColumn = [[NSTableColumn alloc] initWithIdentifier:@"rssi"];
    [[rssiColumn headerCell] setStringValue:@"RSSI"];
    [rssiColumn setWidth:50];
    [rssiColumn setEditable:NO];
    [clientsTable addTableColumn:rssiColumn];
    
    [clientsScrollView setDocumentView:clientsTable];
    [clientsScrollView setBorderType:NSBezelBorder];
    [clientsScrollView setHasVerticalScroller:YES];
    [clientsScrollView setHasHorizontalScroller:YES];
    [clientsScrollView setAutohidesScrollers:NO];
    
    [clientsTable setDataSource:self];
    [clientsTable setDelegate:self];
    [clientsTable setAllowsMultipleSelection:YES];
    
    [self addSubview:clientsScrollView];
    [self addSubview:backButton];
    
    [self setAutoresizesSubviews:YES];
    [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [clientsScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  }

- (void)backButton:(id)sender {
    [sniffer stop];
    [sniffer setDelegate:nil];
    sniffer = nil;
    [(ANAppDelegate *)[NSApp delegate] showNetworkList];
}

#pragma mark - Table View -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [allClients count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    ANClient * client = [allClients objectAtIndex:row];
    if ([[tableColumn identifier] isEqualToString:@"station"]) {
        return MACToString(client.macAddress);
    } else if ([[tableColumn identifier] isEqualToString:@"count"]) {
        return [NSNumber numberWithInt:client.packetCount];
    } else if ([[tableColumn identifier] isEqualToString:@"rssi"]) {
        return [NSNumber numberWithFloat:client.rssi];
    } else if ([[tableColumn identifier] isEqualToString:@"probes"]) {
        NSMutableString *string = [NSMutableString string];
        for (id probe in client.probes) {
            if (probe == client.probes.firstObject) {
                [string appendString:[NSString stringWithFormat:@"%@", probe]];
            } else {
                [string appendString:[NSString stringWithFormat:@", %@", probe]];
            }
        }
        return string;
    }
    return nil;
}

#pragma mark - WiFi -

- (void)hopChannel {
    channelIndex += 1;
    if (channelIndex >= [channels count]) {
        channelIndex = 0;
    }
    [sniffer setChannel:[channels objectAtIndex:channelIndex]];
}

#pragma mark WiFi Sniffer

- (void)wifiSnifferFailedToOpenInterface:(ANWiFiSniffer *)sniffer {
    NSRunAlertPanel(@"Interface Error", @"Failed to open sniffer interface.", @"OK", nil, nil);
}

- (void)wifiSniffer:(ANWiFiSniffer *)sniffer failedWithError:(NSError *)error {
    NSRunAlertPanel(@"Sniff Error", @"Got a sniff error. Please try again.", @"OK", nil, nil);
}

- (void)wifiSniffer:(ANWiFiSniffer *)sniffer gotPacket:(AN80211Packet *)packet {
    BOOL hasClient = NO;
    unsigned char client[6];
    unsigned char bssid[6];
    if ([packet dataFCS] != [packet calculateFCS]) return;
    
    if (packet.macHeader->frame_control.type == 0x0 && packet.macHeader->frame_control.subtype == 0x4) {
        ANClient * clientObj = [[ANClient alloc] initWithMac:packet.macHeader->mac2 bssid:packet.macHeader->mac3];
        if (![allClients containsObject:clientObj]) {
            [allClients addObject:clientObj];
        } else {
            clientObj = [allClients objectAtIndex:[allClients indexOfObject:clientObj]];
        }
        clientObj.packetCount += 1;
        clientObj.rssi = (float)packet.rssi;
        
        ANProbeRequestFrame * probeRequest = [[ANProbeRequestFrame alloc] initWithPacket:packet];
        if (probeRequest.ssid.length > 0 && ![clientObj.probes containsObject:probeRequest.ssid]) {
            [clientObj.probes addObject:probeRequest.ssid];
        }
        
        [clientsTable reloadData];
    }
}

@end

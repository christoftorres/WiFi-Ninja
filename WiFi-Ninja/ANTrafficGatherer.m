//
//  ANTrafficGatherer.m
//  JamWiFi
//
//  Created by Alex Nichol on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ANTrafficGatherer.h"
#import "ANAppDelegate.h"
#import "ANClientKiller.h"
#import "ANBeaconFrame.h"
#import "ANProbeRequestFrame.h"

@implementation ANTrafficGatherer

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
    impersonateButton = [[NSButton alloc] initWithFrame:NSMakeRect(frame.size.width - 230, 10, 110, 24)];
    continueButton = [[NSButton alloc] initWithFrame:NSMakeRect(frame.size.width - 120, 10, 110, 24)];
        
    [backButton setBezelStyle:NSRoundedBezelStyle];
    [backButton setTitle:@"Back"];
    [backButton setFont:[NSFont systemFontOfSize:13]];
    [backButton setTarget:self];
    [backButton setAction:@selector(backButton:)];
    
    [impersonateButton setBezelStyle:NSRoundedBezelStyle];
    [impersonateButton setTitle:@"Impersonate"];
    [impersonateButton setFont:[NSFont systemFontOfSize:13]];
    [impersonateButton setTarget:self];
    [impersonateButton setAction:@selector(impersonateButton:)];
    [impersonateButton setEnabled:NO];
    
    [continueButton setBezelStyle:NSRoundedBezelStyle];
    [continueButton setTitle:@"Jam"];
    [continueButton setFont:[NSFont systemFontOfSize:13]];
    [continueButton setTarget:self];
    [continueButton setAction:@selector(continueButton:)];
    
    NSTableColumn * checkedColumn = [[NSTableColumn alloc] initWithIdentifier:@"enabled"];
    [[checkedColumn headerCell] setStringValue:@""];
    [checkedColumn setWidth:20];
    [checkedColumn setEditable:YES];
    [clientsTable addTableColumn:checkedColumn];
    
    NSTableColumn * stationColumn = [[NSTableColumn alloc] initWithIdentifier:@"station"];
    [[stationColumn headerCell] setStringValue:@"Station"];
    [stationColumn setWidth:120];
    [stationColumn setEditable:NO];
    [clientsTable addTableColumn:stationColumn];
    
    NSTableColumn * bssidColumn = [[NSTableColumn alloc] initWithIdentifier:@"bssid"];
    [[bssidColumn headerCell] setStringValue:@"BSSID"];
    [bssidColumn setWidth:120];
    [bssidColumn setEditable:NO];
    [clientsTable addTableColumn:bssidColumn];
    
    NSTableColumn * packetsColumn = [[NSTableColumn alloc] initWithIdentifier:@"count"];
    [[packetsColumn headerCell] setStringValue:@"Packets"];
    [packetsColumn setWidth:60];
    [packetsColumn setEditable:NO];
    [clientsTable addTableColumn:packetsColumn];
    
    NSTableColumn * probesColumn = [[NSTableColumn alloc] initWithIdentifier:@"probes"];
    [[probesColumn headerCell] setStringValue:@"Probes"];
    [probesColumn setWidth:90];
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
    [self addSubview:continueButton];
    [self addSubview:impersonateButton];
    [self addSubview:backButton];
    
    [self setAutoresizesSubviews:YES];
    [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [clientsScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [continueButton setAutoresizingMask:(NSViewMinXMargin)];
    [impersonateButton setAutoresizingMask:(NSViewMinXMargin)];
}

- (void)backButton:(id)sender {
    [sniffer stop];
    [sniffer setDelegate:nil];
    sniffer = nil;
    [(ANAppDelegate *)[NSApp delegate] showNetworkList];
}

- (void)impersonateButton:(id)sender {
    [[clientsTable selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        CWInterface * interface = [CWInterface interface];
        ANClient * client = [allClients objectAtIndex:idx];
        @try {
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:@"/sbin/ifconfig"];
            [task setArguments:@[interface.interfaceName, @"ether", MACToString(client.macAddress)]];
            [task launch];
        } @catch (NSException *e) {
            NSRunAlertPanel(@"Impersonation Failed", @"The MAC address of %@ could not be changed at this time.\nReason: %@", interface.interfaceName, [e reason], @"OK", nil, nil);
        }
    }];
}

- (void)continueButton:(id)sender {
    ANClientKiller * killer = [[ANClientKiller alloc] initWithFrame:self.bounds sniffer:sniffer networks:networks clients:allClients];
    [(ANAppDelegate *)[NSApp delegate] pushView:killer direction:ANViewSlideDirectionForward];
}

#pragma mark - Table View -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [allClients count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    ANClient * client = [allClients objectAtIndex:row];
    if ([[tableColumn identifier] isEqualToString:@"station"]) {
        return MACToString(client.macAddress);
    } else if ([[tableColumn identifier] isEqualToString:@"bssid"]) {
        return MACToString(client.bssid);
    } else if ([[tableColumn identifier] isEqualToString:@"count"]) {
        return [NSNumber numberWithInt:client.packetCount];
    } else if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
        return [NSNumber numberWithBool:client.enabled];
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

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    ANClient * client = [allClients objectAtIndex:row];
    if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
        client.enabled = [object boolValue];
    }
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
        NSButtonCell * cell = [[NSButtonCell alloc] init];
        [cell setButtonType:NSSwitchButton];
        [cell setTitle:@""];
        return cell;
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if ([[clientsTable selectedRowIndexes] count] == 1) {
        [impersonateButton setEnabled:YES];
    } else {
        [impersonateButton setEnabled:NO];
    }
}

#pragma mark - WiFi -

- (BOOL)includesBSSID:(const unsigned char *)bssid {
    for (CWNetwork * network in networks) {
        if ([MACToString(bssid) isEqualToString:network.bssid]) {
            return YES;
        }
    }
    return NO;
}

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
    
    // Probe Request
    if (packet.macHeader->frame_control.type    == 0x0 &&
        packet.macHeader->frame_control.subtype == 0x4) {
        ANProbeRequestFrame * probeRequest = [[ANProbeRequestFrame alloc] initWithPacket:packet];
        if (probeRequest.ssid.length > 0) {
            ANClient * clientObj = [[ANClient alloc] initWithMac:packet.macHeader->mac2 bssid:packet.macHeader->mac3];
            if ([allClients containsObject:clientObj]) {
                ANClient * origClient = [allClients objectAtIndex:[allClients indexOfObject:clientObj]];
                if (![origClient.probes containsObject:probeRequest.ssid]) {
                    [origClient.probes addObject:probeRequest.ssid];
                }
            }
        }
    }
    
    // Beacon
    /*if (packet.macHeader->frame_control.type    == 0x0 &&
        packet.macHeader->frame_control.subtype == 0x4) {
        NSLog(@"Beacon");
        ANBeaconFrame * beacon = [[ANBeaconFrame alloc] initWithPacket:packet];
        NSLog(@"channel: %lu", (unsigned long)beacon.channel
              );
        NSLog(@"essid: %@", beacon.essid
              );
    }*/
    
    if (packet.macHeader->frame_control.from_ds == 0 && packet.macHeader->frame_control.to_ds == 1) {
        memcpy(bssid, packet.macHeader->mac1, 6);
        if (![self includesBSSID:bssid]) return;
        memcpy(client, packet.macHeader->mac2, 6);
        hasClient = YES;
    } else if (packet.macHeader->frame_control.from_ds == 0 && packet.macHeader->frame_control.to_ds == 0) {
        memcpy(bssid, packet.macHeader->mac3, 6);
        if (![self includesBSSID:bssid]) return;
        if (memcmp(packet.macHeader->mac2, packet.macHeader->mac3, 6) != 0) {
            memcpy(client, packet.macHeader->mac2, 6);
            hasClient = YES;
        }
    } else if (packet.macHeader->frame_control.from_ds == 1 && packet.macHeader->frame_control.to_ds == 0) {
        memcpy(bssid, packet.macHeader->mac2, 6);
        if (![self includesBSSID:bssid]) return;
        memcpy(client, packet.macHeader->mac1, 6);
        hasClient = YES;
    }
    if (client[0] == 0x33 && client[1] == 0x33) hasClient = NO;
    if (client[0] == 0x01 && client[1] == 0x00) hasClient = NO;
    if (client[0] == 0xFF && client[1] == 0xFF) hasClient = NO;
    if (hasClient) {
        ANClient * clientObj = [[ANClient alloc] initWithMac:client bssid:bssid];
        if (![allClients containsObject:clientObj]) {
            [allClients addObject:clientObj];
        } else {
            ANClient * origClient = [allClients objectAtIndex:[allClients indexOfObject:clientObj]];
            origClient.packetCount += 1;
            origClient.rssi = (float)packet.rssi;
        }
        [clientsTable reloadData];
    }
}

@end

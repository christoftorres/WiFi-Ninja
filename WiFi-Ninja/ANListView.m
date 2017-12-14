//
//  ANListView.m
//  JamWiFi
//
//  Created by Alex Nichol on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ANListView.h"
#import "ANAppDelegate.h"

@interface ANListView (Private)

- (void)handleScanError;
- (void)handleScanSuccess:(NSArray *)theNetworks;

@end

@implementation ANListView

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        networksScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 52, frame.size.width - 20, frame.size.height - 62)];
        networksTable = [[NSTableView alloc] initWithFrame:[[networksScrollView contentView] bounds]];
        probesButton = [[NSButton alloc] initWithFrame:NSMakeRect(110, 10, 100, 24)];
        scanButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, 10, 100, 24)];
        resetButton = [[NSButton alloc] initWithFrame:NSMakeRect(210, 10, 100, 24)];
        progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(330, 14, 16, 16)];
        nextButton = [[NSButton alloc] initWithFrame:NSMakeRect(frame.size.width - 110, 10, 100, 24)];
        
        [progressIndicator setControlSize:NSSmallControlSize];
        [progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
        [progressIndicator setDisplayedWhenStopped:NO];
        
        [scanButton setBezelStyle:NSRoundedBezelStyle];
        [scanButton setTitle:@"Scan"];
        [scanButton setTarget:self];
        [scanButton setAction:@selector(scanButton:)];
        [scanButton setFont:[NSFont systemFontOfSize:13]];
        
        [resetButton setBezelStyle:NSRoundedBezelStyle];
        [resetButton setTitle:@"Reset"];
        [resetButton setTarget:self];
        [resetButton setAction:@selector(resetButton:)];
        [resetButton setFont:[NSFont systemFontOfSize:13]];
        
        [probesButton setBezelStyle:NSRoundedBezelStyle];
        [probesButton setTitle:@"Probes"];
        [probesButton setTarget:self];
        [probesButton setAction:@selector(probesButton:)];
        [probesButton setFont:[NSFont systemFontOfSize:13]];
        
        [nextButton setBezelStyle:NSRoundedBezelStyle];
        [nextButton setTitle:@"Next"];
        [nextButton setTarget:self];
        [nextButton setAction:@selector(nextButton:)];
        [nextButton setFont:[NSFont systemFontOfSize:13]];
        [nextButton setEnabled:NO];
        
        NSTableColumn * channelColumn = [[NSTableColumn alloc] initWithIdentifier:@"channel"];
        [[channelColumn headerCell] setStringValue:@"CH"];
        [channelColumn setWidth:40];
        [channelColumn setEditable:YES];
        [networksTable addTableColumn:channelColumn];
        
        NSTableColumn * essidColumn = [[NSTableColumn alloc] initWithIdentifier:@"essid"];
        [[essidColumn headerCell] setStringValue:@"ESSID"];
        [essidColumn setWidth:170];
        [essidColumn setEditable:YES];
        [networksTable addTableColumn:essidColumn];
        
        NSTableColumn * bssidColumn = [[NSTableColumn alloc] initWithIdentifier:@"bssid"];
        [[bssidColumn headerCell] setStringValue:@"BSSID"];
        [bssidColumn setWidth:120];
        [bssidColumn setEditable:YES];
        [networksTable addTableColumn:bssidColumn];
        
        NSTableColumn * encColumn = [[NSTableColumn alloc] initWithIdentifier:@"enc"];
        [[encColumn headerCell] setStringValue:@"Security"];
        [encColumn setWidth:60];
        [encColumn setEditable:YES];
        [networksTable addTableColumn:encColumn];
      
        NSTableColumn * rssiColumn = [[NSTableColumn alloc] initWithIdentifier:@"rssi"];
        [[rssiColumn headerCell] setStringValue:@"RSSI"];
        [rssiColumn setWidth:60];
        [rssiColumn setEditable:YES];
        [networksTable addTableColumn:rssiColumn];
      
        [networksScrollView setDocumentView:networksTable];
        [networksScrollView setBorderType:NSBezelBorder];
        [networksScrollView setHasVerticalScroller:YES];
        [networksScrollView setHasHorizontalScroller:YES];
        [networksScrollView setAutohidesScrollers:NO];
        
        [networksTable setDataSource:self];
        [networksTable setDelegate:self];
        [networksTable setAllowsMultipleSelection:YES];
        [networksTable setSortDescriptors:[NSArray arrayWithObjects: [NSSortDescriptor sortDescriptorWithKey:@"rssi" ascending:YES selector:@selector(compare:)], nil]];
        
        [self addSubview:networksScrollView];
        [self addSubview:scanButton];
        [self addSubview:resetButton];
        [self addSubview:probesButton];
        [self addSubview:progressIndicator];
        [self addSubview:nextButton];
        
        [self setAutoresizesSubviews:YES];
        [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [networksScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [nextButton setAutoresizingMask:(NSViewMinXMargin)];
    }
    return self;
}

- (void)scanButton:(id)sender {
    [progressIndicator startAnimation:self];
    [scanButton setEnabled:NO];
    [networks removeAllObjects];
    [networksTable reloadData];
    [self scanInBackground];
}

- (void)resetButton:(id)sender {
    CWInterface * interface = [CWInterface interface];
    @try {
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/sbin/ifconfig"];
        [task setArguments:@[interface.interfaceName, @"ether", interface.hardwareAddress]];
        [task launch];
    } @catch (NSException *e) {
        NSRunAlertPanel(@"Reset Failed", @"The network interface %@ could not be reset at this time.\nReason: %@", interface.interfaceName, [e reason], @"OK", nil, nil);
    }
}

- (void)probesButton:(id)sender {
    if (networks.count > 0) {
        ANWiFiSniffer * sniffer = [[ANWiFiSniffer alloc] initWithInterfaceName:interfaceName];
        ANProbes * probes = [[ANProbes alloc] initWithFrame:self.bounds sniffer:sniffer networks:networks];
        [(ANAppDelegate *)[NSApp delegate] pushView:probes direction:ANViewSlideDirectionForward];
    }
}

- (void)nextButton:(id)sender {
    NSMutableArray * theNetworks = [NSMutableArray array];
    [[networksTable selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [theNetworks addObject:[networks objectAtIndex:idx]];
    }];
    
    ANWiFiSniffer * sniffer = [[ANWiFiSniffer alloc] initWithInterfaceName:interfaceName];
    ANTrafficGatherer * gatherer = [[ANTrafficGatherer alloc] initWithFrame:self.bounds sniffer:sniffer networks:theNetworks];
    [(ANAppDelegate *)[NSApp delegate] pushView:gatherer direction:ANViewSlideDirectionForward];
}

- (void)scanInBackground {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __weak id weakSelf = self;
    dispatch_async(queue, ^{
        CWInterface * interface = [CWInterface interface];
        interfaceName = interface.interfaceName;
        NSError * error = nil;
        NSArray * nets = [[interface scanForNetworksWithSSID:nil error:&error] allObjects];
        if (error) NSLog(@"wifi scan error: %@", error);
        if (!nets) {
            [weakSelf performSelectorOnMainThread:@selector(handleScanError) withObject:nil waitUntilDone:NO];
        } else {
            [weakSelf performSelectorOnMainThread:@selector(handleScanSuccess:) withObject:nets waitUntilDone:NO];
        }
    });
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [networks count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    CWNetwork * network = [networks objectAtIndex:row];
    
    if ([[tableColumn identifier] isEqualToString:@"channel"]) {
        return [NSNumber numberWithInt:(int)network.wlanChannel.channelNumber];
    } else if ([[tableColumn identifier] isEqualToString:@"essid"]) {
        return network.ssid;
    } else if ([[tableColumn identifier] isEqualToString:@"bssid"]) {
        return network.bssid;
    } else if ([[tableColumn identifier] isEqualToString:@"enc"]) {
        return [self securityTypeString:network];
    } else if ([[tableColumn identifier] isEqualToString:@"rssi"]) {
        return [[NSNumber numberWithInteger:network.rssiValue] description];
    }
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if ([[networksTable selectedRowIndexes] count] > 0) {
        [nextButton setEnabled:YES];
    } else {
        [nextButton setEnabled:NO];
    }
}

- (NSString *)securityTypeString:(CWNetwork *)network {
    if ([network supportsSecurity:kCWSecurityDynamicWEP]) {
        return @"WEP";
    } else if ([network supportsSecurity:kCWSecurityNone]) {
        return @"Open";
    } else if ([network supportsSecurity:kCWSecurityEnterprise]) {
        return @"Enterprise";
    } else {
        return @"WPA";
    }
}

#pragma mark - Private -

- (void)handleScanError {
    [progressIndicator stopAnimation:self];
    [scanButton setEnabled:YES];
    NSRunAlertPanel(@"Scan Failed", @"A network scan could not be completed at this time.",
                    @"OK", nil, nil);
}

- (void)handleScanSuccess:(NSArray *)theNetworks {
    NSMutableArray * newNetworks = [theNetworks mutableCopy];
    for (CWNetwork * network in networks) {
        if (![newNetworks containsObject:network]) {
            [newNetworks addObject:network];
        }
    }
    [progressIndicator stopAnimation:self];
    [scanButton setEnabled:YES];
    networks = newNetworks;
    [networksTable reloadData];
}

@end

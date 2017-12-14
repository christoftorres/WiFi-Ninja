//
//  ANProbes.h
//  JamWiFi
//
//  Created by Alex Nichol on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreWLAN/CoreWLAN.h>
#import "ANWiFiSniffer.h"
#import "ANClient.h"
#import "MACParser.h"

@interface ANProbes : NSView <ANWiFiSnifferDelegate, NSTableViewDelegate, NSTableViewDataSource> {
    ANWiFiSniffer * sniffer;
    NSArray * networks;
    NSArray * channels;
    int channelIndex;
    NSTimer * hopTimer;
    NSMutableArray * allClients;
    
    NSTableView * clientsTable;
    NSScrollView * clientsScrollView;
    
    NSButton * backButton;
}

- (id)initWithFrame:(NSRect)frameRect sniffer:(ANWiFiSniffer *)aSniffer networks:(NSArray *)theNetworks;
- (void)configureUI;

- (void)hopChannel;

- (void)backButton:(id)sender;

@end

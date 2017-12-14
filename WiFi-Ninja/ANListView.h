//
//  ANListView.h
//  JamWiFi
//
//  Created by Alex Nichol on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreWLAN/CoreWLAN.h>
#import "ANTrafficGatherer.h"
#import "ANProbes.h"

@interface ANListView : NSView <NSTableViewDelegate, NSTableViewDataSource> {
    NSString * interfaceName;
    NSMutableArray * networks;
    
    NSButton * scanButton;
    NSButton * probesButton;
    NSButton * resetButton;
    NSButton * nextButton;

    NSProgressIndicator * progressIndicator;
    NSScrollView * networksScrollView;
    NSTableView * networksTable;
}

- (void)scanInBackground;
- (void)scanButton:(id)sender;
- (void)probesButton:(id)sender;
- (void)resetButton:(id)sender;
- (void)nextButton:(id)sender;

- (NSString *)securityTypeString:(CWNetwork *)network;

@end

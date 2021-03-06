//
//  InterfaceController.h
//  WatchTrack Extension
//
//  Created by Jason Ji on 11/4/15.
//  Copyright © 2015 Jason Ji. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "AddEntryInterfaceController.h"

@interface TotalInterfaceController : WKInterfaceController<EntryDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *totalLabel;

@end

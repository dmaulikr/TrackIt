//
//  AddEntryInterfaceController.h
//  TrackIt
//
//  Created by Jason Ji on 11/4/15.
//  Copyright © 2015 Jason Ji. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "WatchSessionDelegate.h"

@protocol EntryDelegate <NSObject>

-(void)newEntryAdded:(NSNumber *)newTotal;

@end

@interface AddEntryInterfaceController : WKInterfaceController

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfacePicker *dollarPicker;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfacePicker *centsPicker;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *valueLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *noteLabel;

@property (weak, nonatomic) id<EntryDelegate>delegate;

@end
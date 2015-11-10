//
//  WatchSessionDelegate.h
//  TrackIt
//
//  Created by Jason Ji on 11/5/15.
//  Copyright © 2015 Jason Ji. All rights reserved.
//

#import <Foundation/Foundation.h>
@import WatchConnectivity;
#import "EntriesModel.h"

@interface WatchSessionDelegate : NSObject<WCSessionDelegate>

-(void)sendTotalToWatch:(NSNumber *)total;
@property (strong, nonatomic) EntriesModel *model;

@end
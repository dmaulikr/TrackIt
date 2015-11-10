//
//  WatchSessionDelegate.m
//  TrackIt
//
//  Created by Jason Ji on 11/5/15.
//  Copyright © 2015 Jason Ji. All rights reserved.
//

#import "WatchSessionDelegate.h"
#import "AppDelegate.h"

@implementation WatchSessionDelegate

-(EntriesModel *)model {
    if(!_model) {
        _model = [[EntriesModel alloc] initWithTimePeriod:@7];
    }
    return _model;
}

-(void)sendTotalToWatch:(NSNumber *)total {
    NSError *error;
    WCSession *session = [WCSession defaultSession];
    if(session.isPaired && session.isWatchAppInstalled) {
        [session updateApplicationContext:@{@"total" : total} error:&error];
        if(error) {
            NSLog(@"%@", error.localizedDescription);
        }
    }
}

#pragma mark - WCSessionDelegate

-(void)sessionWatchStateDidChange:(WCSession *)session {
    
}

-(void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo {
    
}

-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        replyHandler(@{@"error" : @"expired"});
        [[UIApplication sharedApplication] endBackgroundTask:identifier];
    }];
    if([message[@"request"] isEqualToString:@"total"]) {
        [self.model refreshEntries];
        replyHandler(@{@"total" : [self.model totalSpending]});
        [[UIApplication sharedApplication] endBackgroundTask:identifier];
    }
    else if([message[@"request"] isEqualToString:@"newEntry"]) {
        NSNumber *value = message[@"value"];
        NSString *note = message[@"note"];
        NSError *error;
        NSManagedObjectContext *context = ((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
        [Entry entryWithAmount:value note:note date:[NSDate date] inManagedObjectContext:context];
        
        [context save:&error];
        
        [self.model refreshEntries];
        
        // TODO: post notifications for new total spending and to refresh table of entries
        
        replyHandler(@{@"newTotal" : [self.model totalSpending]});
        [[UIApplication sharedApplication] endBackgroundTask:identifier];
    }
}

@end
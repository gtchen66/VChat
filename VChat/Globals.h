//
//  Globals.h
//  VChat
//
//  Created by Joey Lin on 2/20/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RGB2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

extern NSString *const UserLogoutNotification;

extern NSString *const SenderCountKey;
extern NSString *const ListenCountKey;
extern NSString *const RecordingObjectName;

extern BOOL GlobalRepeatTimerFlag;

@interface Globals : NSObject

@end

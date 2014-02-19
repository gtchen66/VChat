//
//  VChatDrawingView.h
//  VChat
//
//  Created by George Chen on 2/16/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VChatDrawingView : UIView

// abs(duration) is message in seconds.  negative is self-generated
@property (nonatomic, assign) int duration;

// indicates color/thickness.
@property (nonatomic, assign) int countdown;

@end

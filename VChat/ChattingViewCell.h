//
//  ChattingViewCell.h
//  VChat
//
//  Created by George Chen on 2/17/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VChatDrawingView.h"

@interface ChattingViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *myChattingViewCellTimeLabel;
@property (weak, nonatomic) IBOutlet VChatDrawingView *myChattingViewCellDrawing;

@property (nonatomic, assign) int duration;
@property (nonatomic, assign) int countdown;

-(void) redisplay;

@end

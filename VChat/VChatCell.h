//
//  VChatCell.h
//  VChat
//
//  Created by George Chen on 2/14/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VChatDrawingView.h"

@protocol VChatCellDelegate
@optional
- (void) onVChatCellButton:(id)sender;

@end

@interface VChatCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *myVChatCellLabel;
@property (weak, nonatomic) IBOutlet UILabel *myVChatCellTimeLabel;
// @property (weak, nonatomic) IBOutlet UIView *myVChatCellView;
@property (weak, nonatomic) IBOutlet VChatDrawingView *myVChatDrawingView;

@property (nonatomic, assign) int duration;
@property (nonatomic, assign) int countdown;

-(void)redisplay;

@property (nonatomic, strong) id delegate;

@end

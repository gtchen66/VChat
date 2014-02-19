//
//  ChattingViewCell.m
//  VChat
//
//  Created by George Chen on 2/17/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "ChattingViewCell.h"

@implementation ChattingViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setCountdown:(int)countdown {
    _countdown = countdown;
    self.myChattingViewCellDrawing.countdown = countdown;
}

- (void) setDuration:(int)duration {
    _duration = duration;
    self.myChattingViewCellDrawing.duration = duration;
    [self setNeedsDisplay];
}

- (void) redisplay {
    [self.myChattingViewCellDrawing setNeedsDisplay];
}

@end

//
//  VChatDrawingView.m
//  VChat
//
//  Created by George Chen on 2/16/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "VChatDrawingView.h"

@implementation VChatDrawingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

// duration is passed down.  duration has to be > 0 or < 0.  It cannot
// be 0.  if duration > 0, then message was received by user. if duration
// is < 0, then it was sent by user.
// left side for received
// right side for sent.
- (void)drawRect:(CGRect)rect
{
    float height = self.frame.size.height;
    float width = self.frame.size.width - 1;
    float leftX = 1.0;
    float rightX = 4*self.duration;
    CGContextRef context = UIGraphicsGetCurrentContext();

    
    float thickness = 0.35*height;             // radius, as fraction of frame height.
    float thickrem = (height*0.5 - thickness);
        
    // 120 seconds is the full duration.
    if (self.duration > 0) {
        // left side
        leftX = thickness+1;
        rightX = MIN(self.duration*(width/120) + leftX, width-thickness);

    } else {
        // right side.  duration is negative.
        rightX = width - thickness;
        leftX = MAX(width + self.duration*(width/120) - thickness, thickness+1);
    }
    
    CGFloat purple[4] = {1.0f, 0.0f, 1.0f, 1.0f};
    CGContextSetStrokeColor(context, purple);
    CGContextSetFillColor(context, purple);
    CGContextBeginPath(context);

    // start straight path, from left corner.
    CGContextMoveToPoint(context, leftX, thickrem);
    CGContextAddLineToPoint(context, rightX, thickrem);
    
    //CGContextAddLineToPoint(context, rightX, 0.65*height);
    CGContextAddArc(context, rightX, 0.5*height, thickness, -(M_PI_2), M_PI_2, 0);
    
    CGContextAddLineToPoint(context, leftX, height-thickrem);
    
    // CGContextAddLineToPoint(context, leftX, (0.5+thickness)*height);
    CGContextAddArc(context, leftX, 0.5*height, thickness, M_PI_2, -(M_PI_2), 0);
    
    // CGContextFillPath(context);
    CGContextStrokePath(context);
    NSLog(@"VChatDrawingView : drawRect - from %.0f to %.0f",leftX,rightX);

}


@end

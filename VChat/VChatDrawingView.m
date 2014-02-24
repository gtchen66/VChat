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
    float width = self.frame.size.width - 3;
    float leftX = 2.0;
    float rightX = 4*self.duration;
    
    // was 120.
    float widthInSeconds = 60;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // countdown = 0 - undelivered, solid - full color edge, color1 inside
    // countdown = 1 - delivered, same as 0
    // countdown = 2 - heard, color edge, color2 inside
    // countdown = 3 - heard, color edge, empty
    
    CGFloat emptyColor[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    
    CGFloat leftColor[4] = {1.0f, 0.0f, 1.0f, 1.0f};     // full color
    CGFloat leftColor1[4] = {1.0f, 0.5f, 1.0f, 1.0f};    // getting lighter
    CGFloat leftColor2[4] = {1.0f, 0.75f, 1.0f, 1.0f};   // light color
    
    CGFloat rightColor[4] = {0.0f, 1.0f, 0.0f, 1.0f};
    CGFloat rightColor1[4] = {0.5f, 1.0f, 0.5f, 1.0f};
    CGFloat rightColor2[4] = {0.75f, 1.0f, 0.75f, 1.0f};
    
    if (self.duration < 0) {
        CGContextSetStrokeColor(context, rightColor);
        if (self.countdown < 2) {
            CGContextSetFillColor(context, rightColor1);
        } else if (self.countdown == 2) {
            CGContextSetFillColor(context, rightColor2);
        } else {
            CGContextSetFillColor(context, emptyColor);
        }
    } else {
        CGContextSetStrokeColor(context, leftColor);
        if (self.countdown < 2) {
            CGContextSetFillColor(context, leftColor1);
        } else if (self.countdown == 2) {
            CGContextSetFillColor(context, leftColor2);
        } else {
            CGContextSetFillColor(context, emptyColor);
        }
    }
    
//    if (self.countdown >= 1) {
//        CGContextSetLineWidth(context, 2.0f);
//    } else {
        CGContextSetLineWidth(context, 1.0f);
//    }
    
    if (NO) {
        
        
        float thickness = 0.35*height;             // radius, as fraction of frame height.
        float thickrem = (height*0.5 - thickness);
        
        // 120 seconds is the full duration.
        if (self.duration > 0) {
            // left side
            leftX = thickness+2;
            rightX = MIN(self.duration*(width/widthInSeconds) + leftX, width-thickness);
            
        } else {
            // right side.  duration is negative.
            rightX = width - thickness;
            leftX = MAX(width + self.duration*(width/widthInSeconds) - thickness, thickness+2);
        }
        
        
        // circle method
        CGContextBeginPath(context);
        
        // start straight path, from left corner.
        CGContextMoveToPoint(context, leftX, thickrem);
        CGContextAddLineToPoint(context, rightX, thickrem);
        
        //CGContextAddLineToPoint(context, rightX, 0.65*height);
        CGContextAddArc(context, rightX, 0.5*height, thickness, -(M_PI_2), M_PI_2, 0);
        
        CGContextAddLineToPoint(context, leftX, height-thickrem);
        
        // CGContextAddLineToPoint(context, leftX, (0.5+thickness)*height);
        CGContextAddArc(context, leftX, 0.5*height, thickness, M_PI_2, -(M_PI_2), 0);
        
        CGContextStrokePath(context);
        
        // Repeat, for fillin.
        
        if (self.countdown >= 2) {
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, leftX, thickrem);
            CGContextAddLineToPoint(context, rightX, thickrem);
            CGContextAddArc(context, rightX, 0.5*height, thickness, -(M_PI_2), M_PI_2, 0);
            CGContextAddLineToPoint(context, leftX, height-thickrem);
            CGContextAddArc(context, leftX, 0.5*height, thickness, M_PI_2, -(M_PI_2), 0);
            CGContextFillPath(context);
        }
    } else {
        // rounded rectangle
        
        float thick1 = 0.1*height;
        float thick2 = 0.2*height;
        
        // 120 seconds is the full duration.
        if (self.duration > 0) {
            // left side
            leftX = thick1 + thick2 + 2;
            rightX = MIN(self.duration*(width/widthInSeconds) + leftX, width-thick1-thick2-2);
            rightX = MIN(rightX, 0.333*width);
            
        } else {
            // right side.  duration is negative.
            rightX = width - thick1-thick2-2;
            leftX = MAX(width + self.duration*(width/widthInSeconds) - thick2, thick1+thick2+2);
            leftX = MAX(leftX, 0.666*width);
        }
        
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, leftX, thick1);
        CGContextAddLineToPoint(context, rightX, thick1);
        CGContextAddArc(context, rightX, thick1+thick2, thick2, -(M_PI_2), 0, 0);
        CGContextAddLineToPoint(context, rightX+thick2, height-thick1-thick2);
        CGContextAddArc(context, rightX, height-thick1-thick2, thick2, 0, M_PI_2,0);
        CGContextAddLineToPoint(context, leftX, height-thick1);
        CGContextAddArc(context, leftX, height-thick1-thick2, thick2, M_PI_2, M_PI, 0);
        CGContextAddLineToPoint(context,leftX-thick2,thick1+thick2);
        CGContextAddArc(context, leftX, thick1+thick2, thick2, M_PI, M_PI*1.5, 0);
        CGContextStrokePath(context);
        
        if (self.countdown <= 3) {
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, leftX, thick1);
            CGContextAddLineToPoint(context, rightX, thick1);
            CGContextAddArc(context, rightX, thick1+thick2, thick2, -(M_PI_2), 0, 0);
            CGContextAddLineToPoint(context, rightX+thick2, height-thick1-thick2);
            CGContextAddArc(context, rightX, height-thick1-thick2, thick2, 0, M_PI_2,0);
            CGContextAddLineToPoint(context, leftX, height-thick1);
            CGContextAddArc(context, leftX, height-thick1-thick2, thick2, M_PI_2, M_PI, 0);
            CGContextAddLineToPoint(context,leftX-thick2,thick1+thick2);
            CGContextAddArc(context, leftX, thick1+thick2, thick2, M_PI, M_PI*1.5, 0);
            CGContextFillPath(context);
        }
    }
    //    NSLog(@"VChatDrawingView : drawRect - from %.0f to %.0f",leftX,rightX);
    
}

@end

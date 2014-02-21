//
//  VChatCell.m
//  VChat
//
//  Created by George Chen on 2/14/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "VChatCell.h"
#import "VChatViewController.h"

//
// in-line a uiview to have a drawing
//
//@interface SimpleBlock : UIView
//@property (nonatomic, assign) int simpleDuration;
//@end
//
//@implementation SimpleBlock
//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    NSLog(@"VChatCell : SimpleBlock : initWithFrame");
//    if (self) {
//        [self setBackgroundColor:[UIColor clearColor]];
//    }
//    return self;
//}
//
//- (void)drawRect:(CGRect)rect {
//    float width = self.frame.size.width;
//    float height = self.frame.size.height;
//    float leftX = MAX(0, width - (2*self.simpleDuration));
//    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    NSLog(@"VChatCell : SimpleBlock : drawRect : CG: %@ x,y= %.1f,%.1f -> %d",context, width, height, self.simpleDuration);
//
//    CGFloat blue[4] = {0.0f, 0.0f, 1.0f, 1.0f};
//    CGContextSetStrokeColor(context, blue);
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, leftX, 1.0f);
//    CGContextAddLineToPoint(context, width, 1.0f);
//    CGContextAddLineToPoint(context, width, height);
//    CGContextAddLineToPoint(context, leftX, height);
//    CGContextAddLineToPoint(context, leftX, 1.0);
////    CGContextFillPath(context);
//    CGContextStrokePath(context);
//}
//
//-(void)setSimpleDuration:(int)simpleDuration {
//    NSLog(@"VChatCell : SimpleBlock : setSimpleDuration with %d",simpleDuration);
//    _simpleDuration = simpleDuration;
//    [self setNeedsDisplay];
//}
//
//@end

@implementation VChatCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    NSLog(@"VChatCell : initWithStyle");
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
//    NSLog(@"VChatCell : setSelected");

}

- (void) setCountdown:(int)countdown {
    _countdown = countdown;
    self.myVChatDrawingView.countdown = countdown;
}

- (void) setDuration:(int)duration {
//    NSLog(@"VChatCell : setDuration with %d",duration);
    _duration = duration;
    
    self.myVChatDrawingView.duration = duration;
    
    [self setNeedsDisplay];
}
- (IBAction)onVChatCellButton:(id)sender {
    NSLog(@"VChatCell : onVChatCellButton");
    
    [self.delegate onVChatCellButton:self];
}

- (void) redisplay {
    [self.myVChatDrawingView setNeedsDisplay];
}

//- (void)drawRect:(CGRect)rect {
//    NSLog(@"VChatCell : drawRect : %.1f, %.1f",self.frame.size.width, self.frame.size.height);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGFloat red[4] = {1.0f, 0.0f, 0.0f, 1.0f};
//    CGContextSetStrokeColor(context, red);
//    CGContextSetLineWidth(context, 10.0f);
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, 1.0f, 1.0f);
//    CGContextAddLineToPoint(context, 300, 5.0f);
//    CGContextStrokePath(context);
//    [self setNeedsDisplay];
//    
//}


@end

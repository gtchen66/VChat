//
//  VChatCell.m
//  VChat
//
//  Created by George Chen on 2/14/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "VChatCell.h"

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
    NSLog(@"VChatCell : setSelected");

//    int precount = self.subviews.count;
//    float labelsize = self.myVChatCellLabel.frame.size.width;
//    
//    SimpleBlock *simpleView = [[SimpleBlock alloc] initWithFrame:CGRectMake(180, 8, labelsize-180, 28)];
//    simpleView.simpleDuration = self.duration;
//    [self addSubview:simpleView];
//    SimpleBlock *leftBlock = [[SimpleBlock alloc] initWithFrame:CGRectMake(0, 12, labelsize, 20)];
//    [self addSubview:leftBlock];
//    
//    NSLog(@"size of label is %.0f, from %d to %d subviews",labelsize, precount, self.subviews.count);
//    // Configure the view for the selected state
//    
//    NSLog(@"There are %d subviews",self.subviews.count);
//    int i;
//    for (i=0; i<self.subviews.count; i++) {
//        NSLog(@"%d: %@",i,self.subviews[i]);
//    }
}

- (void) setDuration:(int)duration {
    NSLog(@"VChatCell : setDuration with %d",duration);
    _duration = duration;
    
    self.myVChatDrawingView.duration = duration;
    
    [self setNeedsDisplay];
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

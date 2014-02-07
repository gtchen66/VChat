//
//  NearbyUserCell.m
//  VChat
//
//  Created by Joey Lin on 2/2/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "NearbyUserCell.h"
#import "ChattingViewController.h"

@implementation NearbyUserCell

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

- (IBAction)onClickAddButton:(id)sender {
    NSLog(@"NearbyUserCell : onClickAddButton");
}

- (IBAction)onClickChatButton:(id)sender {
    NSLog(@"NearbyUserCell : onClickChatbutton");
    NSLog(@"This is row %d",((UIButton *)sender).tag);
    
    // go to chatting window
    //[self.navigationController pushViewController:[[ChattingViewController alloc] init] animated:YES];
}
@end

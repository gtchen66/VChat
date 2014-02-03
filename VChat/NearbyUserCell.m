//
//  NearbyUserCell.m
//  VChat
//
//  Created by Joey Lin on 2/2/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "NearbyUserCell.h"

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
}
@end

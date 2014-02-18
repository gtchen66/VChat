//
//  ContactsCell.m
//  VChat
//
//  Created by Joey Lin on 2/17/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "ContactsCell.h"

@implementation ContactsCell

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

- (IBAction)onClickAcceptRequestButton:(id)sender {
    NSLog(@"ContactsCell : onClickAcceptRequestButton");
    
    [self.delegate onClickAcceptRequestButton:self];
}
@end

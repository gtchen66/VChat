//
//  NearbyUserCell.h
//  VChat
//
//  Created by Joey Lin on 2/2/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NearbyUserCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (strong, nonatomic) PFUser *user;

- (IBAction)onClickAddButton:(id)sender;

@end

//
//  NearbyUserCell.h
//  VChat
//
//  Created by Joey Lin on 2/2/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NearbyUserCellDelegate
@optional
- (void)onClickChatButton:(id)sender;

@end

@interface NearbyUserCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (strong, nonatomic) PFUser *user;

- (IBAction)onClickAddButton:(id)sender;
// - (IBAction)onClickChatButton:(id)sender;
// @property (weak, nonatomic) IBOutlet UIButton *clickChatButton;

@property (nonatomic, strong) id delegate;

@end

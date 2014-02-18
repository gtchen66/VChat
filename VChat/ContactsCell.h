//
//  ContactsCell.h
//  VChat
//
//  Created by Joey Lin on 2/17/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ContactsCellDelegate
@optional

- (void)onClickAcceptRequestButton:(id)sender;

@end

@interface ContactsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *acceptRequestButton;

- (IBAction)onClickAcceptRequestButton:(id)sender;

@property (nonatomic, strong) id delegate;


@end

//
//  ContactsViewController.h
//  VChat
//
//  Created by Joey Lin on 2/13/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactsCell.h"

@interface ContactsTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, ContactsCellDelegate>

@end

//
//  NearbyTableViewController.h
//  VChat
//
//  Created by George Chen on 1/22/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NearbyUserCell.h"
#import "MBProgressHUD.h"

@interface NearbyTableViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, NearbyUserCellDelegate, MBProgressHUDDelegate>

@end

//
//  NearbyTableViewController.m
//  VChat
//
//  Created by George Chen on 1/22/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "NearbyTableViewController.h"
#import "NearbyUserCell.h"
#import "ChattingViewController.h"
#import "UIImageView+AFNetworking.h"
// #import <objc/runtime.h>

@interface NearbyTableViewController ()

@property (nonatomic, strong) NSMutableArray *nearbyUsers;
@property (nonatomic, strong) NSMutableArray *friends;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) MBProgressHUD *refreshHUD;
@property (nonatomic, assign) bool refreshing;

- (void)loadData;
- (void)modifyAddButton:(NSString *)title;
- (void)refresh:(UIRefreshControl *)refresh;
- (void)cleanUp;

@end

NSString* const CELL_IDENTIFIER = @"NearbyUserCell";

@implementation NearbyTableViewController

// for use with associatedObjects
//static char indexPathKey;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Subscribe to log out notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanUp) name:UserLogoutNotification object:nil];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.nearbyUsers count] == 0 || self.nearbyUsers == nil) {
        [self loadData];
    }
}

- (void)viewDidLoad
{
    // Load list of nearby users and friends
    [super viewDidLoad];
    self.title = @"Nearby";
    self.refreshing = false;
//    [self loadData];
    
    // Register custom NearbyUserCell
    UINib *customNib = [UINib nibWithNibName:CELL_IDENTIFIER bundle:nil];
    [self.tableView registerNib:customNib forCellReuseIdentifier:CELL_IDENTIFIER];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Setup Refresh Control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // obtain list of nearby folks
    // User's location

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.nearbyUsers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NearbyUserCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER];
    PFUser *user = self.nearbyUsers[indexPath.row];
    cell.userNameLabel.text = (user[@"displayName"] && ![user[@"displayName"] isEqual: @""]) ? user[@"displayName"] : user.username;
    cell.affiliationLabel.text = user[@"affiliation"];
    cell.positionLabel.text = user[@"position"];
    NSLog(@"profile image");
    // search for image file in parse, then facebook, otherwise show default
    if (!cell.profileImageView.image) {
        NSLog(@"NearbyTableViewController : cellForRowAtIndexPath : looking for image for %@",user.username);
        PFQuery *query = [PFQuery queryWithClassName:@"UserPhoto"];
        [query whereKey:@"user" equalTo:user];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            NSLog(@"%@", objects);
            if (!error) {
                // If no profile image exist, look for facebook image, otherwise set default image
                if ([objects count] == 0 || objects == nil) {
                    if (user[@"profileImage"] && ![user[@"profileImage"] isEqualToString:@""]) {
                        NSLog(@"found image for %@ at 1",user.username);
                        [cell.profileImageView setImageWithURL:[NSURL URLWithString:user[@"profileImage"]]];
                    } else {
                        NSLog(@"found image for %@ at 2",user.username);
                        [cell.profileImageView setImage:[UIImage imageNamed:@"DefaultProfileIcon"]];
                    }
                } else {
                    NSLog(@"found image for %@ at 3",user.username);
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        PFFile *imageFile = [objects[0] objectForKey:@"imageFile"];
                        NSData *imageData = [imageFile getData];
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            UIImage *image = [UIImage imageWithData:imageData];
                            [cell.profileImageView setImage:image];
                            [self.tableView beginUpdates];
                            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                            [self.tableView endUpdates];
                        });
                    });
                }
            }
        }];
    }
    
    // Update the Add button to the appropriate status if there is already a friend relations
    NSPredicate *toPredicate = [NSPredicate predicateWithFormat:@"to.objectId = %@",user.objectId];
    NSPredicate *fromPredicate = [NSPredicate predicateWithFormat:@"from.objectId = %@",user.objectId];
    NSArray *toArray = [self.friends filteredArrayUsingPredicate:toPredicate];

    // Need more work if we are going to distinguish between request sent and accept request
    if ([toArray count] != 0) {
        PFObject *friend = toArray[0];
        if ([friend[@"status"] isEqualToString:@"blocked"] == NO) {
            cell.addButton.backgroundColor = [UIColor whiteColor];
            [cell.addButton setEnabled:NO];
            [cell.addButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [cell.addButton setTitle:friend[@"status"] forState:UIControlStateNormal];
        }
    } else {
        NSArray *fromArray = [self.friends filteredArrayUsingPredicate:fromPredicate];

        if ([fromArray count] != 0) {
            // Show button text "
            PFObject *friend = fromArray[0];
            if ([friend[@"status"] isEqualToString:@"blocked"] == NO) {
                cell.addButton.backgroundColor = [UIColor whiteColor];
                [cell.addButton setEnabled:NO];
                [cell.addButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [cell.addButton setTitle:friend[@"status"] forState:UIControlStateNormal];
            } else {
                cell.addButton.backgroundColor = RGB2UIColor(158, 135, 193);
                [cell.addButton setEnabled:YES];
                [cell.addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [cell.addButton setTitle:@"Add" forState:UIControlStateNormal];
            }
        }
    }
    
    cell.delegate = self;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72;
}

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Nearby User Cell delegate
-(void)onClickChatButton:(id)sender{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    
    PFUser *user = self.nearbyUsers[indexPath.row];
    
    // open the chat window.
    ChattingViewController *cvc = [[ChattingViewController alloc] init];
    cvc.remoteUser = user;
    
    [self.navigationController pushViewController:cvc animated:YES];

}

- (void)onClickAddButton:(id)sender {
    // TODO - present friend request text
    
    /* Create a relationship record with status pending */
    
    //
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    PFUser *userToAdd = self.nearbyUsers[indexPath.row];
    
    PFObject *friend = [PFObject objectWithClassName:@"Friend"];
    [friend setObject:[PFUser currentUser] forKey:@"from"];
    [friend setObject:userToAdd forKey:@"to"];
    [friend setObject:@"pending" forKey:@"status"];
    [friend saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // Change Add Button to Cancel button
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]];
        NearbyUserCell *nearbyCell = (NearbyUserCell* )((id)cell);
        nearbyCell.addButton.backgroundColor = [UIColor grayColor];
        [nearbyCell.addButton setEnabled:NO];
        [nearbyCell.addButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [nearbyCell.addButton setTitle:@"Pending" forState:UIControlStateNormal];
        
    }];
}

#pragma mark - MBProgressHUD delegate
- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD hides
    [self.HUD removeFromSuperview];
    self.HUD = nil;
}


- (void)loadData {
    
    PFUser *currentUser = [PFUser currentUser];
    
    // Show loading HUD only if not refreshing
    if (!self.refreshing) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.refreshing = false;
    }
    // populate friends list so we can determine whether to show the Add button or not later on
    PFQuery *fromQuery = [PFQuery queryWithClassName:@"Friend"];
    [fromQuery whereKey:@"from" equalTo:currentUser];
    
    PFQuery *toQuery = [PFQuery queryWithClassName:@"Friend"];
    [toQuery whereKey:@"to" equalTo:currentUser];
    
    PFQuery *friendQuery = [PFQuery orQueryWithSubqueries:@[fromQuery, toQuery]];
    [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.friends = [[NSMutableArray alloc] initWithArray:objects];
        }
    }];

    
    self.nearbyUsers = [[NSMutableArray alloc] init];
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (!error) {
            // do something with the new geoPoint
            //                NSLog(@"%f, %f", geoPoint.latitude, geoPoint.longitude);
            currentUser[@"location"] = geoPoint;
            [currentUser saveInBackground];
            
            // Find users near a given location
            PFQuery *userQuery = [PFUser query];
            [userQuery whereKey:@"location"
                   nearGeoPoint:geoPoint
                    withinMiles:10.0];
            userQuery.limit = 10;
            [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                // Remove current user from user list
                // TODO - remove blocked users from showing up
                for (PFUser *eachUser in objects) {
                    if ([eachUser.objectId isEqualToString:currentUser.objectId] == YES) {
                    } else {
                        [self.nearbyUsers addObject:eachUser];
                    }
                }
                
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [self.tableView reloadData];
                
            }];

        } else {
            [MBProgressHUD hideHUDForView:self.view animated:YES];

        }
    }];
    }

- (void)modifyAddButton:(NSString *)title {
    
}

- (void)refresh:(UIRefreshControl *)refresh {
    self.refreshing = true;
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing data..."];
    self.nearbyUsers = nil;
    self.friends = nil;
    [self loadData];
    [self.tableView reloadData];
    [refresh endRefreshing];
}

- (void)cleanUp {
    // clear data for log out
    self.nearbyUsers = nil;
    self.friends = nil;
}

@end

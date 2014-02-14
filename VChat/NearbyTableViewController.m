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

- (void)loadData;
- (void)modifyAddButton:(NSString *)title;

@end

NSString* const CELL_IDENTIFIER = @"NearbyUserCell";

@implementation NearbyTableViewController

// for use with associatedObjects
//static char indexPathKey;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"NearbyTableViewController : viewDidLoad");
    [super viewDidLoad];
    self.title = @"Nearby";
    self.nearbyUsers = [[NSMutableArray alloc] init];
    [self loadData];
    
    UINib *customNib = [UINib nibWithNibName:CELL_IDENTIFIER bundle:nil];
    [self.tableView registerNib:customNib forCellReuseIdentifier:CELL_IDENTIFIER];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

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
//    NSLog(@"calling number of sections");
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    NSLog(@"calling number of rows");
//    NSLog(@"%lu", (unsigned long)[self.nearbyUsers count]);
    // Return the number of rows in the section.
    return [self.nearbyUsers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"generating cell");
    NearbyUserCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER];
    PFUser *user = self.nearbyUsers[indexPath.row];
    cell.userNameLabel.text = (user[@"displayName"] && ![user[@"displayName"] isEqual: @""]) ? user[@"displayName"] : user.username;
    cell.affiliationLabel.text = user[@"affiliation"];
    cell.positionLabel.text = user[@"position"];
    if (!user[@"profileImage"]) {
        [cell.profileImageView setImage:[UIImage imageNamed:@"DefaultProfileIcon"]];
    } else {
        [cell.profileImageView setImageWithURL:[NSURL URLWithString:user[@"profileImage"]]];
    }
    
    NSLog(@"looping through friends");
    // Update the Add button to the appropriate status if there is already a friend relations
    // perhaps find a better way to find user in the array than to loop through every friend
    for (PFObject *friend in self.friends) {
        NSLog(@"%@", friend);
        PFUser *to = [friend objectForKey:@"to"];
        PFUser *from = [friend objectForKey:@"from"];
        if ([user.objectId isEqualToString:from.objectId] || [user.objectId isEqualToString:to.objectId]) {
            NSLog(@"friend found");
            // if user is not blocked, display either "Pending" or "Friends"
            if ([friend[@"status"] isEqualToString:@"blocked"] == NO) {
                cell.addButton.backgroundColor = [UIColor whiteColor];
                [cell.addButton setEnabled:NO];
                [cell.addButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [cell.addButton setTitle:friend[@"status"] forState:UIControlStateNormal];
            }
        }
    }
    
//    cell.clickChatButton.tag = indexPath.row;
    
//    objc_setAssociatedObject(cell.userNameLabel, &indexPathKey, indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

//    NSLog(@"%@", cell.userNameLabel.text);
    
    cell.delegate = self;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72;
}

#pragma mark Nearby User Cell delegate
-(void)onClickChatButton:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSLog(@"NearbyTableViewController : onClickChatButton - index is %d",indexPath.row);
    
    PFUser *user = self.nearbyUsers[indexPath.row];
    NSLog(@"Open conversation with %@",user.username);
    
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
        NSLog(@"friend request sent");
        
        // fade Add button and show "friends" instead
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]];
        NearbyUserCell *nearbyCell = (NearbyUserCell* )((id)cell);
        nearbyCell.addButton.backgroundColor = [UIColor whiteColor];
        [nearbyCell.addButton setEnabled:NO];
        [nearbyCell.addButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [nearbyCell.addButton setTitle:@"Pending" forState:UIControlStateNormal];
        
    }];
}


/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];

    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
 
 */


- (void)loadData {
    PFUser *currentUser = [PFUser currentUser];
    
    // populate friends list so we can determine whether to show the Add button or not later on
    PFQuery *fromQuery = [PFQuery queryWithClassName:@"Friend"];
    [fromQuery whereKey:@"from" equalTo:currentUser];
    
    PFQuery *toQuery = [PFQuery queryWithClassName:@"Friend"];
    [toQuery whereKey:@"to" equalTo:currentUser];
    
    PFQuery *friendQuery = [PFQuery orQueryWithSubqueries:@[fromQuery, toQuery]];
    [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.friends = [[NSMutableArray alloc] initWithArray:objects];
        //NSLog(@"%@", self.friends);
    }];

    
    /****** SHOULD PROBABLY QUERY FOR LOCATION AGAIN INSTEAD OF READING USER OBJECT *********/
    PFGeoPoint *userGeoPoint = currentUser[@"location"];
    // Find users near a given location
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"location"
           nearGeoPoint:userGeoPoint
            withinMiles:10.0];
    userQuery.limit = 10;
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//        NSLog(@"updating nearbyusers.  returned objects has %d entries",objects.count);
        
        // Remove current user from user list
        // TODO - remove blocked users from showing up
        for (PFUser *eachUser in objects) {
//            NSLog(@"Checking %@ (%@) against %@ (%@)",eachUser.objectId, eachUser.username, currentUser.objectId, currentUser.username);
            if ([eachUser.objectId isEqualToString:currentUser.objectId] == YES) {
                NSLog(@"Skipping %@",eachUser.username);
            } else {
                [self.nearbyUsers addObject:eachUser];
            }
        }

        [self.tableView reloadData];
        
    }];
}

- (void)modifyAddButton:(NSString *)title {
    
}

@end

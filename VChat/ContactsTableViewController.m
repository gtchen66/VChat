//
//  ContactsViewController.m
//  VChat
//
//  Created by Joey Lin on 2/13/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "ContactsTableViewController.h"
#import "ChattingViewController.h"

@interface ContactsTableViewController ()

@property (nonatomic, strong) NSMutableArray *contacts;
@property (nonatomic, strong) NSMutableDictionary *sections;

- (void)loadData;

@end

NSString* const CONTACTS_CELL_IDENTIFIER = @"ContactsCell";
NSString* const CONTACTS_KEY = @"contacts";


@implementation ContactsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [self loadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"ContactsTableViewController: viewDidLoad");
    self.title = @"Contacts";
    
    // Register custom ContactsCell
    UINib *customNib = [UINib nibWithNibName:CONTACTS_CELL_IDENTIFIER bundle:nil];
    [self.tableView registerNib:customNib forCellReuseIdentifier:CONTACTS_CELL_IDENTIFIER];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    // Return the number of sections.
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    NSLog(@"numberOfRowsInSection");
//    // Return the number of rows in the section.
//    return [self.contacts count];
//}

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.sections allKeys] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section]] count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactsCell *cell = [tableView dequeueReusableCellWithIdentifier:CONTACTS_CELL_IDENTIFIER];
//    NSDictionary *userDictionary = [self.contacts objectAtIndex:indexPath.row];
    NSDictionary *userDictionary = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];

    cell.nameLabel.text = userDictionary[@"displayName"];
    // determine whether to show "accept request" button, or show "request sent" status
    if ([userDictionary[@"status"] isEqualToString:@"accept request"]) {
        cell.acceptRequestButton.hidden = NO;
        cell.backgroundColor = RGB2UIColor(252, 247, 200);
    } else if ([userDictionary[@"status"] isEqualToString:@"request sent"]) {
        cell.acceptRequestButton.hidden = NO;
        [cell.acceptRequestButton setEnabled:NO];
        [cell.acceptRequestButton setTitle:@"Request Sent" forState:UIControlStateNormal];
        cell.backgroundColor = RGB2UIColor(252, 247, 200);
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    // Attempting to make the background color of the section index on the right non-opaque
    for(UIView *view in [tableView subviews])  {
        if([[[view class] description] isEqualToString:@"UITableViewIndex"])    {
            [view setBackgroundColor:[UIColor clearColor]];
            [view setAlpha:0.5];
            [view setOpaque:NO];
        }
    }
    
    cell.delegate = self;
    return cell;
}

#pragma mark - ContactsCellDelegate
- (void)onClickAcceptRequestButton:(id)sender {
    // Change state of relation to "friends" in DB and on local cache
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    
    // Get the data object from self.sections (pick the right section by key, then the right array by index)
    NSArray *keys = [self.sections allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingSelector: @selector (compare:)];
    id sectionKey = [sortedKeys objectAtIndex:indexPath.section];
    NSArray *sectionArray = [self.sections objectForKey:sectionKey];
    NSDictionary *userDictionary = [sectionArray objectAtIndex:indexPath.row];
    PFQuery *query = [PFQuery queryWithClassName:@"Friend"];
    
    NSLog(@"%@", userDictionary);
    [query getObjectInBackgroundWithId:userDictionary[@"objectId"] block:^(PFObject *friend, NSError *error) {
        if (!error) {
            friend[@"status"] = @"friends";
            // update object
            [friend saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    NSLog(@"friend update succeeded");
                    // Hide the accept request button
                    ContactsCell *cell = (ContactsCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                    CATransition *animation = [CATransition animation];
                    animation.type = kCATransitionFade;
                    animation.duration = 0.4;
                    [cell.acceptRequestButton.layer addAnimation:animation forKey:nil];
                    cell.acceptRequestButton.hidden = YES;
                    cell.backgroundColor = [UIColor whiteColor];
                } else {
                    NSLog(@"friend update failed");
                }
            }];
        }
    }];
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"ContactsTableViewController : didSelectRowAtIndexPath - index is %d",indexPath.row);
    
    NSDictionary *userDictionary = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];

    // If not friends, don't allow chat
    if (![userDictionary[@"status"] isEqualToString:@"friends"]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Action Required" message:@"You must be friends to chat with someone." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        // Fetch for user object and pass to ChattingViewController
        PFQuery *query = [PFUser query];
        [query getObjectInBackgroundWithId:userDictionary[@"userId"] block:^(PFObject *object, NSError *error) {
            PFUser *user = (PFUser *)object;
            NSLog(@"Open conversation with %@",user.username);
            // open the chat window.
            ChattingViewController *cvc = [[ChattingViewController alloc] init];
            cvc.remoteUser = user;
            
            [self.navigationController pushViewController:cvc animated:YES];
        }];
    }
    
}
 

- (void)loadData {
    self.contacts = nil;
    self.sections = nil;
    NSLog(@"ContactsViewController: loadData");
    PFUser *me = [PFUser currentUser];
    
    // Load contacts list from NSUserDefaults first, then find newer relations after latest time stamp.
    // If NSUserDefaults is empty, fetch from Parse. Alternative is to use cached query
    
    // TODO - REFACTOR NSUserDeafult GET AND SET
    
    self.contacts = [[NSMutableArray alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *cachedContacts = [defaults arrayForKey:CONTACTS_KEY];
    if (!cachedContacts || cachedContacts == nil || cachedContacts.count == 0) {
        
        // TODO - REFACTOR RELATIONS FETCH SINCE THIS IS DONE IN NEARBY LIST AS WELL
        
        PFQuery *fromQuery = [PFQuery queryWithClassName:@"Friend"];
        [fromQuery whereKey:@"from" equalTo:me];
        
        PFQuery *toQuery = [PFQuery queryWithClassName:@"Friend"];
        [toQuery whereKey:@"to" equalTo:me];
        
        PFQuery *friendQuery = [PFQuery orQueryWithSubqueries:@[fromQuery, toQuery]];
        
        // include the two user objects
        [friendQuery includeKey:@"to"];
        [friendQuery includeKey:@"from"];
        
        // make the query cached
        friendQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            // save the objectId, display name, user name, and status (request sent, accept request, friends)
//            NSLog(@"%@", objects);
            if ([self.contacts count] != 0 && self.contacts != nil) {
                self.contacts = nil;
                self.contacts = [[NSMutableArray alloc] init];
            }
            NSLog(@"friend query returns");
            if (!error) {
                for (PFObject *friend in objects) {
                    // if friending request was from other person, check if need to show "accept request" button
                    PFUser *to = [friend objectForKey:@"to"];
                    PFUser *from = [friend objectForKey:@"from"];
//                    NSLog(@"%@", to);
//                    NSLog(@"%@", from);
                    if ([me.objectId isEqualToString:to.objectId]) {
                        if ([friend[@"status"] isEqualToString:@"pending"]) {
                            NSDictionary *userDictionary = @{ @"objectId" : friend.objectId,
                                                              @"username" : from.username,
                                                              @"userId" :   from.objectId,
                                                              @"displayName" : from[@"displayName"] ? from[@"displayName"] : from[@"username"],
                                                              @"status" : @"accept request"
                                                              };
                            [self.contacts addObject:userDictionary];
                        } else {
                            NSDictionary *userDictionary = @{ @"objectId" : friend.objectId,
                                                              @"username" : from.username,
                                                              @"userId" :   from.objectId,
                                                              @"displayName" : from[@"displayName"] ? from[@"displayName"] : from[@"username"],
                                                              @"status" : @"friends"
                                                              };
                            [self.contacts addObject:userDictionary];
                        }
                    } else {
//                        NSLog(@"from id matches");
                        if ([friend[@"status"] isEqualToString:@"pending"]) {
//                            NSLog((@"status from id pending"));
                            NSDictionary *userDictionary = @{ @"objectId" : friend.objectId,
                                                              @"username" : to.username,
                                                              @"userId" :   to.objectId,
                                                              @"displayName" : to[@"displayName"] ? to[@"displayName"] : to[@"username"],
                                                              @"status" : @"request sent"
                                                              };
                            [self.contacts addObject:userDictionary];
                        } else {
                            NSDictionary *userDictionary = @{ @"objectId" : friend.objectId,
                                                              @"username" : to.username,
                                                              @"userId" :   to.objectId,
                                                              @"displayName" : to[@"displayName"] ? to[@"displayName"] : to[@"username"],
                                                              @"status" : @"friends"
                                                              };
                            [self.contacts addObject:userDictionary];
                        }
                    }
                }
            } else {
                NSLog(@"%@", error);
            }
            
            // process array to show section headers with first alphabet
            self.sections = [[NSMutableDictionary alloc] init];
            bool found;
            for (NSDictionary *contact in self.contacts)    {
                found = NO;
                NSString *c = [[contact objectForKey:@"displayName"] substringToIndex:1];
                c = [c lowercaseString];
                for (NSString *str in [self.sections allKeys])  {
                    if ([str isEqualToString:c])    {
                        found = YES;
                    }
                }
                if (!found) {
                    [self.sections setValue:[[NSMutableArray alloc] init] forKey:c];
                }
            }
            
            // Loop again and sort the contacts into their respective keys
            for (NSDictionary *contact in self.contacts)    {
                NSString *sectionLetter = [[contact objectForKey:@"displayName"] substringToIndex:1];
                sectionLetter = [sectionLetter lowercaseString];
                [[self.sections objectForKey:sectionLetter] addObject:contact];
            }
            
            // Sort each section array
            for (NSString *key in [self.sections allKeys])  {
                [[self.sections objectForKey:key] sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES]]];
            }
            
//            NSLog(@"sections:");
//            NSLog(@"%@", self.sections);
            
            [self.tableView reloadData];
        }];

        
    } else {
//        self.contacts = [[NSMutableArray alloc] initWithArray:cachedContacts];
        // fetch for newly created relations
    }
    
    
}

@end

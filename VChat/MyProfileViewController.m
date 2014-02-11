//
//  MyProfileViewController.m
//  VChat
//
//  Created by Joey Lin on 2/8/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "MyProfileViewController.h"
#import "MyProfileCell.h"
#import "EditFieldViewController.h"

@interface MyProfileViewController ()

@property (nonatomic, strong) NSMutableArray *profileInfo;

- (void)populateProfileInfoArray;

@end

@implementation MyProfileViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = @"My Profile";
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"MyProfileView: viewDidAppear");
    [self populateProfileInfoArray];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
//    NSLog(@"MyProfileView: viewDidLoad");
    [super viewDidLoad];
    UINib *customNib = [UINib nibWithNibName:@"MyProfileCell" bundle:nil];
    [self.tableView registerNib:customNib forCellReuseIdentifier:@"MyProfileCell"];
    [self populateProfileInfoArray];


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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//    NSLog(@"MyProfileView: numberofSectionsInTableView");
    // Return the number of sections.
    int numberOfSections = self.profileInfo.count;
//    NSLog(@"numberOfSections: %i", numberOfSections);
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    NSLog(@"MyProfileView: numberOfRowsInSection");
    // Return the number of rows in the section.
    NSArray *segment = [self.profileInfo objectAtIndex:section];
//    NSLog(@"%@,",segment);
//    NSLog(@"segment[0]: %@", segment[0]);
//    if (segment[1])
//        NSLog(@"segment[1]: %@", segment[1]);
//    NSLog(@"segment.count: %i", segment.count);
    return segment.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"MyProfileView: cellForRowAtIndexPath");
    MyProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyProfileCell"];
    
    // make user name cell unclickable
    if (!(indexPath.section == 0 && indexPath.row == 0)) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Configure the cell...
    NSMutableArray *profileSection = [self.profileInfo objectAtIndex:indexPath.section];
    NSString *profileField = [profileSection objectAtIndex:indexPath.row];
//    NSLog(@"profileField: %@", profileField);
    NSArray *keyValue = [profileField componentsSeparatedByString:@":"];
//    NSLog(@"keyValue: %@", keyValue);
    if ([keyValue[0] isEqualToString:@"displayName"]) {
        cell.fieldNameLabel.text = @"Display Name";
    } else if ([keyValue[0] isEqualToString:@"username"]) {
        cell.fieldNameLabel.text = @"User Name";
    }   else {
        cell.fieldNameLabel.text = [keyValue[0] capitalizedString];
    }
    cell.fieldValueLabel.text = keyValue[1];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section {
    
    return 20.0f;
}

////asks the delegate for the height to use for the footer of a particular section
//- (CGFloat) tableView:(UITableView *)tableView
//heightForFooterInSection:(NSInteger)section{
//    if (section > 0)
//        return 20.0f;
//    else
//        return 0;
//}

//informs the delegate that the user tapped the accessory view associated with a given row
- (void) tableView:(UITableView *)tableView
accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    
    NSLog(@"MyProfileView: accessoryButtonTapped");
    NSLog(@"indexPath.section: %i", indexPath.section);
    if (indexPath.section != 0) {
        EditFieldViewController *efvc = [[EditFieldViewController alloc] init];
        [self.navigationController pushViewController:efvc animated:YES];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"MyProfileView: didSelectRowAtIndexPath");
    NSLog(@"indexPath.section: %i", indexPath.section);
    if (!(indexPath.section == 0 && indexPath.row == 0)) {
        NSMutableArray *profileSection = [self.profileInfo objectAtIndex:indexPath.section];
        NSString *profileField = [profileSection objectAtIndex:indexPath.row];
        //    NSLog(@"profileField: %@", profileField);
        NSArray *keyValue = [profileField componentsSeparatedByString:@":"];
        //    NSLog(@"keyValue: %@", keyValue);
        NSString *fieldName = keyValue[0];
        NSString *fieldValue = keyValue[1];
        EditFieldViewController *efvc = [[EditFieldViewController alloc] init];
        efvc.fieldName = fieldName;
        efvc.fieldValue = fieldValue;
        if ([fieldName isEqualToString:@"displayName"]) {
            efvc.title = @"Display Name";
        }
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:efvc];
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


- (void)populateProfileInfoArray {
//    NSLog(@"MyProfileView: populateProfileInfoArray");
    // Build an array with section name and field name and value
    PFUser *currentUser = [PFUser currentUser];
    self.profileInfo = [[NSMutableArray alloc] init];
    NSMutableArray *basicInfoFields = [[NSMutableArray alloc] init];
    NSString *userName = [NSString stringWithFormat:@"%@", [currentUser objectForKey:@"username"]];
    NSString *displayName = [NSString stringWithFormat:@"%@",[currentUser objectForKey:@"displayName"] ? [currentUser objectForKey:@"displayName"] : @""];

    [basicInfoFields addObject:[NSString stringWithFormat:@"username:%@", userName]];
    [basicInfoFields addObject:[NSString stringWithFormat:@"displayName:%@", displayName]];
    [self.profileInfo addObject:basicInfoFields];
    
    NSMutableArray *affiliationInfoFields = [[NSMutableArray alloc] init];

    NSString *affiliation = [NSString stringWithFormat:@"%@",[currentUser objectForKey:@"affiliation"] ? [currentUser objectForKey:@"affiliation"] : @""];
    NSString *position = [NSString stringWithFormat:@"%@", [currentUser objectForKey:@"position"] ? [currentUser objectForKey:@"position"] : @""];
    
    [affiliationInfoFields addObject:[NSString stringWithFormat:@"affiliation:%@",affiliation]];
    [affiliationInfoFields addObject:[NSString stringWithFormat:@"position:%@", position]];
    [self.profileInfo addObject:affiliationInfoFields];
    
    NSLog(@"%@", self.profileInfo);
}

@end

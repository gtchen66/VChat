//
//  MyProfileViewController.m
//  VChat
//
//  Created by Joey Lin on 2/8/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "MyProfileViewController.h"
#import "MyProfileCell.h"
#import "EditPhotoCell.h"
#import "EditFieldViewController.h"
#import "UIImageView+AFNetworking.h"


@interface MyProfileViewController ()

@property (nonatomic, strong) NSMutableArray *profileInfo;

- (void)uploadImage:(NSData *)imageData;
- (void)populateProfileInfoArray;

@end

MBProgressHUD *HUD;
MBProgressHUD *refreshHUD;

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
    UINib *photoNib = [UINib nibWithNibName:@"EditPhotoCell" bundle:nil];
    [self.tableView registerNib:customNib forCellReuseIdentifier:@"MyProfileCell"];
    [self.tableView registerNib:photoNib forCellReuseIdentifier:@"EditPhotoCell"];
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
    return segment.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Special custom cell for profile photo
    if (indexPath.section == 0 && indexPath.row == 0) {
        EditPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EditPhotoCell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        // Set the profile image view
        PFQuery *query = [PFQuery queryWithClassName:@"UserPhoto"];
        PFUser *user = [PFUser currentUser];
        [query whereKey:@"user" equalTo:user];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                NSLog(@"fetching image");
                NSLog(@"%@", objects);
                // If no profile image exist, look for facebook image, otherwise set default image
                if ([objects count] == 0 || objects == nil) {
                    PFUser *currentUser = [PFUser currentUser];
                    if (currentUser[@"profileImage"] && ![currentUser[@"profileImage"] isEqualToString:@""]) {
                        [cell.profileImageView setImageWithURL:[NSURL URLWithString:user[@"profileImage"]]];
                    } else {
                        [cell.profileImageView setImage:[UIImage imageNamed:@"DefaultProfileIcon"]];
                    }
                } else {
                    PFFile *theImage = [objects[0] objectForKey:@"imageFile"];
                    NSData *imageData = [theImage getData];
                    UIImage *image = [UIImage imageWithData:imageData];
                    [cell.profileImageView setImage:image];
                }
            }
        }];
        return cell;
    } else {
    
        MyProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyProfileCell"];
        
        // Make user name cell unclickable
        if (!(indexPath.section == 0 && indexPath.row == 1)) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        // Configure the cell...
        NSMutableArray *profileSection = [self.profileInfo objectAtIndex:indexPath.section];
        NSString *profileField = [profileSection objectAtIndex:indexPath.row];
        NSArray *keyValue = [profileField componentsSeparatedByString:@":"];
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
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        return 70;
    }
    
    return 45;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
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


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"MyProfileView: didSelectRowAtIndexPath");
    NSLog(@"indexPath.section: %i, indexPath.row: %i", indexPath.section, indexPath.row);
    
    // Special handling for Profile Photo cell
    if (indexPath.section == 0 && indexPath.row == 0) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == YES){
            
            NSLog(@"Create image picker");
            // Create image picker controller
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            
            // Set source to the photo album
            imagePicker.sourceType =  UIImagePickerControllerSourceTypeSavedPhotosAlbum;
            
            // Delegate is self
            imagePicker.delegate = self;
            
            // Show image picker
            [self presentViewController:imagePicker animated:YES completion:nil];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        if (!(indexPath.section == 0 && indexPath.row == 1)) {
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
}

# pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD hides
    [HUD removeFromSuperview];
    HUD = nil;
}

# pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Access the uncropped image from info dictionary
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    // Dismiss controller
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    // Resize image
    UIGraphicsBeginImageContext(CGSizeMake(640, 960));
    [image drawInRect: CGRectMake(0, 0, 640, 960)];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Upload image
    NSData *imageData = UIImageJPEGRepresentation(smallImage, 0.05f);
    [self uploadImage:imageData];
}


- (void)uploadImage:(NSData *)imageData {
    PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:imageData];
    
    //HUD
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Uploading";
    [HUD show:YES];
    
    // Save PFFile
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // Hide old HUD, show completed HUD
            [HUD hide:YES];
            
            // Create a PFObject around a PFFile and associate it with the current user
            PFQuery *query = [PFQuery queryWithClassName:@"UserPhoto"];
            PFUser *currentUser = [PFUser currentUser];
            [query whereKey:@"user" equalTo:currentUser];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    // delete if photo already exists
                    if ([objects count] != 0) {
                        PFObject *object = objects[0];
                        [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (!error) {
                                NSLog(@"old profile picture delete");
                            }
                        }];
                    }
                }
            }];
            
            PFObject *userPhoto = [PFObject objectWithClassName:@"UserPhoto"];
            [userPhoto setObject:imageFile forKey:@"imageFile"];
            // Set the access control list to current user for security purposes
            userPhoto.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            [userPhoto setObject:currentUser forKey:@"user"];
            [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [self.tableView reloadData];
                } else {
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
        } else {
            [HUD hide:YES];
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    } progressBlock:^(int percentDone) {
        // Update your progress spinner here. percentDone will be between 0 and 100.
        HUD.progress = (float)percentDone/100;
    }];
}

- (void)populateProfileInfoArray {
//    NSLog(@"MyProfileView: populateProfileInfoArray");
    // Build an array with section name and field name and value
    PFUser *currentUser = [PFUser currentUser];
    self.profileInfo = [[NSMutableArray alloc] init];
    NSMutableArray *basicInfoFields = [[NSMutableArray alloc] init];
    
    [basicInfoFields addObject:@"Profile Picture"];
    NSString *userName;
    // Display a default user name if facebook user
    if ([PFFacebookUtils isLinkedWithUser:currentUser]) {
        userName = @"[FB User]";
    } else {
        userName = [NSString stringWithFormat:@"%@", [currentUser objectForKey:@"username"]];
    }
    
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

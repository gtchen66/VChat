//
//  VChatViewController.m
//  VChat
//
//  Created by George Chen on 1/22/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "VChatViewController.h"
#import "ChatsTableViewController.h"
#import "LogInViewController.h"
#import "SignupViewController.h"

@interface VChatViewController ()

@property (nonatomic, strong) LogInViewController *logInViewController;
@property (strong, nonatomic) IBOutlet UITableView *myVChatTableView;

@property (strong, nonatomic) NSMutableArray *latestToUserArray;
@property (strong, nonatomic) NSMutableArray *latestFromUserArray;

@property (strong, nonatomic) NSString *pathLocalToFile;
@property (strong, nonatomic) NSString *pathLocalFromFile;

- (void)logOutButtonTapAction;
- (void)initLogInController;

@end

// this should be in one location, and this should use the same value.
// for now, comment it out and use it explicitly
// NSString* const RECORDING_CLASSNAME = @"UserRecording";

@implementation VChatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.myVChatTableView.delegate = self;
    self.myVChatTableView.dataSource = self;
    
    self.pathLocalToFile = @"/tmp/localFile1.plist";
    self.pathLocalFromFile = @"/tmp/localFile2";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    NSLog(@"VChatViewController : viewDidAppear");

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sign Out" style:UIBarButtonItemStylePlain target:self action:@selector(logOutButtonTapAction)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"PlusIcon"] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.title = @"Chats";
    
    [self initLogInController];
    
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser) { // No user logged in
        // Present the log in view controller
        [self presentViewController:self.logInViewController animated:YES completion:NULL];
    } else {
//        NSLog(@"user logged in");
        // update user location
        [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
            if (!error) {
                // do something with the new geoPoint
                //                NSLog(@"%f, %f", geoPoint.latitude, geoPoint.longitude);
                NSLog(@"VChatViewController: update location");
                currentUser[@"location"] = geoPoint;
                [currentUser saveInBackground];
            } 
        }];
        
        FBRequest *request = [FBRequest requestForMe];
        
        // Send request to Facebook
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                // result is a dictionary with the user's Facebook data
                NSDictionary *userData = (NSDictionary *)result;
                BOOL missingData = NO;
                
                NSString *facebookID = userData[@"id"];
                if (!currentUser[@"displayName"]) {
                    NSLog(@"display name missing");
                    NSString *name = userData[@"name"];
                    currentUser[@"displayName"] = name;
//                    NSLog(@"name: %@", name);
                    missingData = YES;
                }
                if (!currentUser[@"profileImage"]) {
                    NSLog(@"profile image missing");
                    NSString * pictureString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID];
//                    NSLog(@"pictureURL: %@", pictureURL);
                    missingData = YES;
                    currentUser[@"profileImage"] = pictureString;
                }
//                NSLog(@"%@", currentUser);
                if (missingData) {
                    NSLog(@"updating facebook data for user");
                    [currentUser saveInBackground];
                }
            }
        }];
        
        // initialize the chat table w/ recent chats
        [self loadChattingDataFromRepository];
    }
}

#pragma mark - TableView Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSLog(@"VChatViewController : numberOfSectionsInTableView");
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"VChatViewController : numberOfRowsInSection");
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chatViewCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"chatViewCell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"chat with %d",indexPath.row];
    
    return cell;
}

// Pulls chatting data from repository, appends to local-data
- (void) loadChattingDataFromRepository {
    
    // Parse implementation.
    PFQuery *query = [PFQuery queryWithClassName:@"UserRecording"];
    PFUser *user = [PFUser currentUser];
    NSDate *lastRetrieved = user[@"lastRetrieved"];
    NSDate *currentDate = [[NSDate alloc] init];
    
    NSString *docsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    self.pathLocalToFile = [docsDir stringByAppendingPathComponent:@"localToFile.plist"];
    self.pathLocalFromFile = [docsDir stringByAppendingPathComponent:@"localFromFile.plist"];
    
//    if (lastRetrieved == nil) {
        lastRetrieved = [[NSDate alloc] initWithTimeIntervalSince1970:0];
//    }
    
    [query whereKey:@"toUser" equalTo:user.username];
    [query whereKey:@"timestamp" greaterThan:lastRetrieved];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.latestToUserArray = [NSMutableArray array];
        if (objects.count > 0) {
            for (PFObject *eachObject in objects) {
                NSMutableDictionary *vchat = [[NSMutableDictionary alloc] init];

                [vchat setValue:[eachObject objectForKey:@"toUser"] forKey:@"toUser"];
                [vchat setValue:[eachObject objectForKey:@"fromUser"] forKey:@"fromUser"];
                [vchat setValue:[eachObject objectForKey:@"timestamp"] forKey:@"timestamp"];

                // recording...
                PFFile *thisFile = [eachObject objectForKey:@"recording"];
                [vchat setValue:thisFile.url forKey:@"recordingURL"];

                [self.latestToUserArray addObject:vchat];
            }
            NSLog(@"Found %d new messages to this user", self.latestToUserArray.count);
            BOOL result = [self.latestToUserArray writeToFile:self.pathLocalToFile atomically:YES];
            NSLog(@"Result of write is %hhd",result);
            NSLog(@"Wrote to %@",self.pathLocalToFile);
            NSLog(@"To data is %@",self.latestToUserArray);
            
        }
        else {
            NSLog(@"Found no new messages to this user");
            return;
        }
    }];
    
    // Do I need to do this to reset the query
    query = [PFQuery queryWithClassName:@"UserRecording"];
    
    [query whereKey:@"fromUser" equalTo:user.username];
    [query whereKey:@"timestamp" greaterThan:lastRetrieved];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.latestFromUserArray = [NSMutableArray array];
        if (objects.count > 0) {
            for (PFObject *eachObject in objects) {
                NSMutableDictionary *vchat = [[NSMutableDictionary alloc] init];
                
                [vchat setValue:[eachObject objectForKey:@"toUser"] forKey:@"toUser"];
                [vchat setValue:[eachObject objectForKey:@"fromUser"] forKey:@"fromUser"];
                [vchat setValue:[eachObject objectForKey:@"timestamp"] forKey:@"timestamp"];
                
                PFFile *thisFile = [eachObject objectForKey:@"recording"];
                [vchat setValue:thisFile.url forKey:@"recordingURL"];
                [self.latestFromUserArray addObject:vchat];
            }
            NSLog(@"Found %d new messages from this user", self.latestFromUserArray.count);
            BOOL result = [self.latestFromUserArray writeToFile:self.pathLocalFromFile atomically:YES];
            NSLog(@"Result of from_write is %hhd",result);
            NSLog(@"from_Wrote to %@",self.pathLocalFromFile);
            NSLog(@"From data is %@",self.latestFromUserArray);
        }
        else {
            NSLog(@"Found no new messages from this user");
            return;
        }
    }];
    
    // Update user's lastRetrieved date
    user[@"lastRetrieved"] = currentDate;
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"Updated user with lastRetrieved timestamp of %@",currentDate);
        } else {
            NSLog(@"Error while updating user: %@",error);
        }
    }];
    
}

// Build displayable list of chats


#pragma mark - PFLogInViewControllerDelegate

// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    if (username && password && username.length && password.length) {
        return YES;
    }
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"Make sure you fill out all of the information!", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    return NO;
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    NSLog(@"User successfully logs in");
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    NSLog(@"User dismissed the logInViewController");
    //[self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - PFSignUpViewControllerDelegate

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) {
            informationComplete = NO;
            break;
        }
    }
    
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"Make sure you fill out all of the information!", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    NSLog(@"Failed to sign up...");
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    NSLog(@"User dismissed the signUpViewController");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initLogInController {
    // Create the log in view controller
    self.logInViewController = [[LogInViewController alloc] init];
    [self.logInViewController setDelegate:self]; // Set ourselves as the delegate
    [self.logInViewController setFacebookPermissions:[NSArray arrayWithObjects:@"friends_about_me", nil]];
    [self.logInViewController setFields:PFLogInFieldsUsernameAndPassword
     | PFLogInFieldsFacebook
     | PFLogInFieldsSignUpButton];
    
    // Create the sign up view controller
    SignupViewController *signUpViewController = [[SignupViewController alloc] init];
    [signUpViewController setDelegate:self]; // Set ourselves as the delegate
    
    // Assign our sign up controller to be displayed from the login controller
    [self.logInViewController setSignUpController:signUpViewController];
}

- (void)logOutButtonTapAction {
    NSLog(@"User logged out");
    [PFUser logOut];
    if (self.logInViewController) {
        [self presentViewController:self.logInViewController animated:YES completion:NULL];

    } else {
        NSLog(@"loginviewcontroller is nil");
    }
}
@end

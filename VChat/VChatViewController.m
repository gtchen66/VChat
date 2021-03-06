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
#import "VChatCell.h"
#import "ChattingViewController.h"

@interface VChatViewController () {
    dispatch_queue_t myQueue;
}

@property (nonatomic, strong) LogInViewController *logInViewController;
@property (strong, nonatomic) IBOutlet UITableView *myVChatTableView;

@property (strong, nonatomic) NSMutableArray *latestToUserArray;
@property (strong, nonatomic) NSMutableArray *latestFromUserArray;

@property (strong, nonatomic) NSMutableArray *allChatArray;

@property (strong, nonatomic) NSString *pathLocalToFile;
@property (strong, nonatomic) NSString *pathLocalFromFile;
@property (strong, nonatomic) NSString *pathLocalStorage;

@property (strong, nonatomic) NSIndexPath *playingIndexPath;
@property NSInteger rowIsPlaying;

@property (strong, nonatomic) NSMutableDictionary *mapUsernameToObjectId;
@property (strong, nonatomic) NSMutableDictionary *mapObjectIdToDisplayName;
@property (strong, nonatomic) NSMutableDictionary *mapObjectIdToPFUser;

@property NSInteger periodicCounter;
@property NSTimer *myTimer;
// @property BOOL isPlaying;

- (void)logOutButtonTapAction;
- (void)initLogInController;
- (void)updateContacts;

- (void) periodicTimerMethod:(NSTimer *)timer;

@end

// AVAudioPlayer *audioPlayer;

// this should be in one location, and this should use the same value.
// for now, comment it out and use it explicitly
// NSString* const RECORDING_CLASSNAME = @"UserRecording";

@implementation VChatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logOutButtonTapAction) name:UserLogoutNotification object:nil];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UINib *customNib = [UINib nibWithNibName:@"VChatCell" bundle:nil];
    [self.myVChatTableView registerNib:customNib forCellReuseIdentifier:@"VChatCell"];
    
    self.myVChatTableView.delegate = self;
    self.myVChatTableView.dataSource = self;
    
    self.pathLocalToFile = @"/tmp/sound.caf";
    self.pathLocalFromFile = @"/tmp/localFile2";
    
    NSString *docsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    self.pathLocalToFile = [docsDir stringByAppendingPathComponent:@"localToFile.plist"];
    self.pathLocalFromFile = [docsDir stringByAppendingPathComponent:@"localFromFile.plist"];
    self.pathLocalStorage = [docsDir stringByAppendingPathComponent:@"localStorage.plist"];

    self.allChatArray = [[NSMutableArray alloc] init];
    
//    audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:self.pathLocalToFile] error:nil];
//    audioPlayer.delegate = self;
    
//    audioPlayer.delegate = self;
//    self.isPlaying = NO;
    self.rowIsPlaying = -1;
    
    self.mapUsernameToObjectId = [[NSMutableDictionary alloc] init];
    self.mapObjectIdToDisplayName = [[NSMutableDictionary alloc] init];
    self.mapObjectIdToPFUser = [[NSMutableDictionary alloc] init];

//    self.periodicCounter = 0;
//    self.myTimer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(periodicTimerMethod:) userInfo:nil repeats:YES];
    
    // Check and update contacts (This should be refactored out of this controller so things aren't so cluttered!)
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"VChatViewController : viewDidAppear");

//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sign Out" style:UIBarButtonItemStylePlain target:self action:@selector(logOutButtonTapAction)];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"PlusIcon"] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.title = @"Recent";
    
    // Instantiate the login and signup controllers
    [self initLogInController];
    
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser) { // No user logged in
        // Present the log in view controller
        [self presentViewController:self.logInViewController animated:YES completion:NULL];
    } else {
        
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
        self.title = @"Recent";
    }
    if (GlobalRepeatTimerFlag == YES) {
        NSLog(@"VChatViewController : Activating NSTimer");
        self.periodicCounter = 0;
        self.myTimer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(periodicTimerMethod:) userInfo:nil repeats:YES];
    } else {
        NSLog(@"Skipping NStimer activation");
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"VChatViewController : viewWillDisappear");
    [self.myTimer invalidate];
}


#pragma mark - TableView Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    NSLog(@"VChatViewController : numberOfSectionsInTableView");
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    NSLog(@"VChatViewController : numberOfRowsInSection = %d",self.allChatArray.count);
    return self.allChatArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *vChatCellIdentifier = @"VChatCell";
    int messageDuration;
    
    VChatCell *vcell = [tableView dequeueReusableCellWithIdentifier:vChatCellIdentifier];
    if (vcell == nil) {
        NSLog(@"WARNING - vcell was nil");
        vcell = [[VChatCell alloc] init];
    }
    
    NSDictionary *chat = [self.allChatArray objectAtIndex:indexPath.row];

    NSString *cellString = [[NSString alloc] init];
    NSDate *timestamp = [chat objectForKey:@"timestamp"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"E, MM/dd HH:mm"];
    NSString *shortTime = [dateFormatter stringFromDate:timestamp];
    
    messageDuration = round([[chat objectForKey:@"duration"] floatValue]);
    if (messageDuration == 0) {
        NSData *soundData = [chat objectForKey:@"sound"];
        
        // recording is done at 8000 x 16bit x 2channels.
        messageDuration = soundData.length/32000.0;
        
        // TODO:  this duration should be pushed back to Parse, as this data wasn't in the original
        // code.  however, eventually this will not be necessary, so this is a low priority
        // for now.
        
    }

    NSString *durationString = [NSString stringWithFormat:@"%ds",messageDuration];
    NSMutableString *statusString = [[NSMutableString alloc] init];
    
    // make duration negative to indicate this was self-sent.
    NSString *directionString;
    if ([[chat objectForKey:@"fromUser"] isEqualToString:[PFUser currentUser].username]) {
        //
        // Outgoing message.  Username/status on left side.  Chat length on right.  Chat icon on right.
        messageDuration = -messageDuration;
        directionString = @"sent to";
        vcell.myVChatCellLabel.textAlignment = NSTextAlignmentLeft;
        vcell.myVChatCellStatusLabel.textAlignment = NSTextAlignmentLeft;
        vcell.myVChatCellTimeLabel.textAlignment = NSTextAlignmentRight;
        vcell.countdown = [chat[SenderCountKey] integerValue];
        int listenCount = [chat[ListenCountKey] integerValue];
        statusString = [NSMutableString stringWithFormat:@"sent %@",shortTime];
        if (listenCount == 1) {
            [statusString appendString:@" - delivered"];
        } else if (listenCount > 1) {
            [statusString appendString:@" - heard"];
        }
    } else {
        vcell.myVChatCellLabel.textAlignment = NSTextAlignmentRight;
        vcell.myVChatCellStatusLabel.textAlignment = NSTextAlignmentRight;
        vcell.myVChatCellTimeLabel.textAlignment = NSTextAlignmentLeft;
        directionString = @"received from";
        vcell.countdown = [chat[ListenCountKey] integerValue];
        
        statusString = [NSMutableString stringWithFormat:@"received %@",shortTime];

    }
    
    // this is slow.  fill this in during the loaddata background thread instead
    // cellString = [self findDisplayNameforObjectid:chat[@"remoteId"]];
    cellString = chat[@"displayName"];
    
    vcell.myVChatCellLabel.text = cellString;
    vcell.myVChatCellStatusLabel.text = statusString;
    vcell.myVChatCellTimeLabel.text = durationString;
    
    vcell.duration = messageDuration;
    
    [vcell redisplay];
    vcell.delegate = self;
    
    return vcell;
}

#pragma mark - TableView Delegates
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"VChatViewController : didSelectRowAtIndexPath (%d)", indexPath.row);
    
    // playback message.  if currently playing a message, then immediately ignore.
    if (self.rowIsPlaying > -1) {
        // playback is occurring.
        if (self.rowIsPlaying == indexPath.row) {
            // stop current playback.
            // TODO - enable a method for pausing playback, not just stopping.

            [chatPlayer stop];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            self.rowIsPlaying = -1;
            return;
        }
    }
    
//    if (self.isPlaying == YES) {
//        NSLog(@"currently playing.  skipping");
//        [tableView deselectRowAtIndexPath:indexPath animated:YES];
//        return;
//    }
    
    NSLog(@"Playback message");
    NSDictionary *chat = [self.allChatArray objectAtIndex:indexPath.row];
    // check to see if this should be disabled.
    int count;
    if ([chat[@"remoteId"] isEqualToString:chat[@"toId"]]) {
        // I am the sender
        count = [chat[SenderCountKey] integerValue];
    } else {
        // I am the reciepient
        count = [chat[ListenCountKey] integerValue];
    }
    if (count >= 3) {
        // played too often, skipping
        NSLog(@"playback disabled at (%d)",count);
        [self.myVChatTableView deselectRowAtIndexPath:indexPath animated:YES];
        
        // instead of returning, treat this as a request to go to the Chatting page.
        
        PFUser *remoteUser = [self findPFUserForObjectid:chat[@"remoteId"]];
        
        ChattingViewController *cvc = [[ChattingViewController alloc] init];
        cvc.remoteUser = remoteUser;
        
        [self.navigationController pushViewController:cvc animated:YES];
        
        // the return is so that this doesn't try to playback.
        return;
    }
    
    
    // TODO: do something clever if recording is bad...
    NSData *soundData = [chat objectForKey:@"sound"];
    NSError *outError;

    chatPlayer = [[AVAudioPlayer alloc] initWithData:soundData error:&outError];
//    NSLog(@"Error - %@",outError);
    
    if (chatPlayer == nil) {
        NSLog(@"Error trying to play %@.",[chat objectForKey:@"timestamp"]);
        [self.myVChatTableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        chatPlayer.delegate = self;
        self.playingIndexPath = indexPath;
        NSLog(@"Playing returned %d",[chatPlayer play]);
        self.rowIsPlaying = indexPath.row;
    }
    
    // now deselect this row.
    // [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // TODO: Playback did start.  Update Cloud DB with playback.  Should identify if this
    // is the recipient or the sender.
    
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"VChatViewController : didDeselectRowAtIndexPath (%d)",indexPath.row);
}

- (void)incrementListenCountForIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *chat = [self.allChatArray objectAtIndex:indexPath.row];
    int listenCount = [chat[@"listenCount"] integerValue];
    int senderCount = [chat[@"senderCount"] integerValue];

    if ([[chat objectForKey:@"fromUser"] isEqualToString:[PFUser currentUser].username]) {
        senderCount++;
        chat[@"senderCount"] = @(senderCount);
    } else {
        listenCount++;
        chat[@"listenCount"] = @(listenCount);
    }
    
    NSLog(@"Updating listenCount to %d, senderCount to %d", listenCount, senderCount);
    
    PFQuery *query = [PFQuery queryWithClassName:@"UserRecording"];
    [query getObjectInBackgroundWithId:chat[@"objectId"] block:^(PFObject *object, NSError *error) {
        object[@"listenCount"] = @(listenCount);
        object[@"senderCount"] = @(senderCount);
        [object saveInBackground];
    }];
    [self.myVChatTableView reloadData];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"Playback finished");
    [self.myVChatTableView deselectRowAtIndexPath:self.playingIndexPath animated:YES];
    [self incrementListenCountForIndexPath:self.playingIndexPath];
    
    self.playingIndexPath = 0;
//    self.isPlaying = NO;
    self.rowIsPlaying = -1;
}

- (void)onVChatCellButton:(id) sender {
    NSIndexPath *indexPath = [self.myVChatTableView indexPathForCell:sender];
    NSLog(@"VChatViewController : onVChatCellButton (%d)",indexPath.row);
    
    // open a chat window.  need to provide the remote user.
    NSDictionary *dict = self.allChatArray[indexPath.row];
    
    PFUser *remoteUser = [self findPFUserForObjectid:dict[@"remoteId"]];
    
    ChattingViewController *cvc = [[ChattingViewController alloc] init];
    cvc.remoteUser = remoteUser;
    
    [self.navigationController pushViewController:cvc animated:YES];
}

// Pulls chatting data from repository, appends to local-data
- (void)loadChattingDataFromRepository {
    // Parse implementation.
    //    PFQuery *query = [PFQuery queryWithClassName:@"UserRecording"];
    PFUser *user = [PFUser currentUser];
    
    NSDate *lastRetrieved = user[@"lastRetrieved"];
    NSDate *currentDate = [[NSDate alloc] init];
    
    NSString *docsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    self.pathLocalStorage = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"localStorage.%@.plist",user.username]];
    
    //    if (lastRetrieved == nil) {
    lastRetrieved = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    //    }
    
    NSLog(@"path: %@",self.pathLocalStorage);
//    NSLog(@"last retrieved: %@",lastRetrieved);
    
    //    [self.allChatArray removeAllObjects];
    self.allChatArray = [[NSMutableArray alloc] initWithContentsOfFile:self.pathLocalStorage];
    NSLog(@"allChatArray now contains %d rows",self.allChatArray.count);
    
    NSMutableDictionary *dictToArrayIndex = [[NSMutableDictionary alloc] init];
    if (self.allChatArray == nil) {
        NSLog(@"allChatArray is nil");
        self.allChatArray = [[NSMutableArray alloc] init];
        
        // there's no data.  reset lastRetrieved to epoch.
        lastRetrieved = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    } else {
        // create a dictionary based on the objectId that returns an index into
        // the array.
        int i;
        for (i=0; i<self.allChatArray.count; i++) {
            NSDictionary *dict = [self.allChatArray objectAtIndex:i];
            if (dict[@"objectId"] == nil) {
                // this is an older, incompatible, object.  delete it.
                NSLog(@"WARNING: cleaning up old file, removing object at %d",i);
                [self.allChatArray removeObjectAtIndex:i];
                i--;
            } else {
                [dictToArrayIndex setValue:@(i) forKey:dict[@"objectId"]];
            }
        }
    }
    
    // find recordings sent to me OR sent by me.
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(toUser = %@) OR (fromUser = %@)",user.username,user.username];
//    NSLog(@"Predicate %@",predicate);
    
    // set lastRetrieved to current time, then run query
    user[@"lastRetrieved"] = currentDate;
    
    PFQuery *query = [PFQuery queryWithClassName:@"UserRecording" predicate:predicate];
    
    //    [query whereKey:@"toUser" equalTo:user.username];
    [query whereKey:@"timestamp" greaterThan:lastRetrieved];
    // this pust most recent in front.  Use Ascending to make most recent at the bottom.
    [query orderByDescending:@"timestamp"];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.latestToUserArray = [NSMutableArray array];
        if (objects.count > 0) {
            for (PFObject *eachObject in objects) {
                //                NSLog(@"-- %@",eachObject);
                //                NSLog(@"objectid? %@",eachObject.objectId);
                
                // does this object already exist?
                if ([dictToArrayIndex objectForKey:eachObject.objectId] != nil) {
                    // just update a few fields
                    // NSLog(@"objectid %@ already exists in db",eachObject.objectId);
                    
                    // retrieve listen-counts from cloud.
                    
                    int listenCount = [eachObject[@"listenCount"] integerValue];
                    int senderCount = [eachObject[@"senderCount"] integerValue];
                    if (senderCount == 0){
                        senderCount++;
                    }
                    
                    int objIndex = [[dictToArrayIndex objectForKey:eachObject.objectId] integerValue];
                    NSMutableDictionary *mydict = [self.allChatArray objectAtIndex:objIndex];
                                        
                    // fix.  earlier versions did not have remoteId set, so set it now.
                    if (mydict[@"remoteId"] == nil) {
                        if ([user.objectId isEqualToString:mydict[@"fromId"]]) {
                            mydict[@"remoteId"] = mydict[@"toId"];
                        } else {
                            mydict[@"remoteId"] = mydict[@"fromId"];
                        }
                        NSLog(@"missing remote user id.  Setting to %@",mydict[@"remoteId"]);
                    }
                    
                    if (listenCount == 0) {
                        NSLog(@"found listenCount == 0 for msg at %@",mydict[@"timestamp"]);
                        if ([mydict[@"remoteId"] isEqualToString:mydict[@"fromId"]]) {
                            listenCount++;
                            NSLog(@"existing %@ had listenCount set to 0, changing",mydict[@"timestamp"]);
                            eachObject[ListenCountKey] = @(1);
                            [eachObject saveInBackground];
                        }
                    }

                    mydict[ListenCountKey] = @(listenCount);
                    mydict[SenderCountKey] = @(senderCount);

                    
                } else {
                    // new data.
                    
                    NSMutableDictionary *vchat = [[NSMutableDictionary alloc] init];
                    
                    [vchat setValue:eachObject.objectId forKey:@"objectId"];
                    [vchat setValue:[eachObject objectForKey:@"toUser"] forKey:@"toUser"];
                    [vchat setValue:[eachObject objectForKey:@"fromUser"] forKey:@"fromUser"];
                    [vchat setValue:[eachObject objectForKey:@"timestamp"] forKey:@"timestamp"];
                    [vchat setValue:[eachObject objectForKey:ListenCountKey] forKey:ListenCountKey];
                    [vchat setValue:[eachObject objectForKey:SenderCountKey] forKey:SenderCountKey];
                    if (vchat[SenderCountKey] == 0) {
                        vchat[SenderCountKey] = @(1);
                    }

                    NSString *fromId = eachObject[@"fromId"];
                    NSString *toId = eachObject[@"toId"];
                    NSString *remoteId = fromId;
                    
                    // Backwards compatibility.  Earlier version of the recording did not have object_id
                    // embedded.  This will embed them.
                    
                    if ((toId == nil) || ([toId isEqualToString:@"unknown"])) {
                        // these values were not set for this recording.  Find the right user and set it.
                        
                        if ([user.username isEqualToString:vchat[@"toUser"]]) {
                            // already the toUser, find the fromUser
                            toId = user.objectId;
                            fromId = [self findObjectIdForUsername:vchat[@"fromUser"]];
                            remoteId = fromId;
                        } else {
                            fromId = user.objectId;
                            toId = [self findObjectIdForUsername:vchat[@"toUser"]];
                            remoteId = toId;
                        }
                        
                        PFQuery *query = [PFQuery queryWithClassName:@"UserRecording"];
                        [query getObjectInBackgroundWithId:eachObject.objectId block:^(PFObject *object, NSError *error) {
                            object[@"toId"] = toId;
                            object[@"fromId"] = fromId;
                            [object saveInBackground];
                        }];
                        
                        NSLog(@"from/to Id missing, found. from %@ to %@",fromId,toId);
                    } else {
                        if ([user.objectId isEqualToString:fromId]) {
                            remoteId = toId;
                        }
                    }
                    
                    [vchat setValue:fromId forKey:@"fromId"];
                    [vchat setValue:toId forKey:@"toId"];
                    [vchat setValue:remoteId forKey:@"remoteId"];
                    
                    // link to recording...
                    [vchat setValue:[eachObject objectForKey:@"recording"] forKey:@"thisFile"];
                    [vchat setValue:@"NO" forKey:@"readyToPlay"];
                    
                    [vchat setValue:[eachObject objectForKey:@"duration"] forKey:@"duration"];
                    
                    // get Display Name of the sender/receipient
                    // first identify which, then find user.
                    
                    NSLog(@"msg: from %@ to %@ at %@ (%@) %@", vchat[@"fromUser"], vchat[@"toUser"], vchat[@"timestamp"], vchat[@"objectId"], vchat[@"duration"]);
                    
                    // all new objects, check for listenCount.  if listenCount == 0, then increment
                    if (vchat[ListenCountKey] == 0) {
                        if ([remoteId isEqualToString:fromId]) {
                            // I am the receiver, aka the listener
                            vchat[ListenCountKey] = @(1);
                            eachObject[ListenCountKey] = @(1);
                            [eachObject saveInBackground];
                        }
                    }
                    
                    [self.latestToUserArray addObject:vchat];
                }
                // put here paramters to retrieve, regardless of whether this user
                // is already in the system or not.
            }
            NSLog(@"Found %d new messages to this user", self.latestToUserArray.count);
            
            [self.allChatArray addObjectsFromArray:self.latestToUserArray];
            [self arrangeData];
            [self backgroundOperationGetDisplayName];
            [self backgroundOperation];
            [self.myVChatTableView reloadData];
            
        }
        else {
            NSLog(@"Found no new messages to this user");
            return;
        }
    }];
    
    
    // Update user's lastRetrieved date
//    user[@"lastRetrieved"] = currentDate;
    NSLog(@"Updating timestamp to %@",user[@"lastRetrieved"]);
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"Updated user with lastRetrieved timestamp of %@",currentDate);
        } else {
            NSLog(@"Error while updating user: %@",error);
        }
    }];
    [self.myVChatTableView reloadData];
    
    // if descending, no content offset needed
    
    // if ascending then, offset needed
    // [self.myVChatTableView setContentOffset:CGPointMake(0, self.myVChatTableView.contentSize.height - self.myVChatTableView.frame.size.height+50)];
    //    NSLog(@"%@",[self.myVChatTableView contentOffset]);
    

}

- (NSString *)findObjectIdForUsername:(NSString *)username {
    
    if (username == nil) {
        NSLog(@"ERROR! attempting to find objectid for username null");
        return @"unknown";
    }
    
    NSString *objid = [self.mapUsernameToObjectId objectForKey:username];
    
    if (objid == nil) {
        // query parse.
        
        PFQuery *query = [PFUser query];
        [query whereKey:@"username" equalTo:username];
        NSArray *foundUser = [query findObjects];
        if (foundUser.count != 1) {
            NSLog(@"Unexpected error, number of users with from username %@ is %d",username,foundUser.count);
        }
        PFUser *testPFUser = [foundUser objectAtIndex:0];
        objid = testPFUser.objectId;
        [self.mapUsernameToObjectId setObject:objid forKey:username];
    }
    return objid;
}

- (NSString *)findDisplayNameforObjectid:(NSString *)objectid {
    // return username if display name does not exist.
    if (objectid == nil) {
        NSLog(@"ERROR! attempting to find display name for nil objectid");
        return @"Unknown User";
    }
    NSString *displayName = [self.mapObjectIdToDisplayName objectForKey:objectid];
    
    if (displayName == nil) {
        
        PFUser *testPFUser = [self findPFUserForObjectid:objectid];
        displayName = testPFUser[@"displayName"];
        
        if (displayName == nil) {
            displayName = testPFUser[@"username"];
        }
        
        NSLog(@"Parse returned %@ for objectId %@", displayName, objectid);
        [self.mapObjectIdToDisplayName setObject:displayName forKey:objectid];
        
    } else {
//        NSLog(@"existing %@ for objectId %@", displayName, objectid);
    }
    
    return displayName;
}

- (PFUser *)findPFUserForObjectid:(NSString *)objectid {
    if (objectid == nil) {
        NSLog(@"ERROR! attempting to find PFUser for nil objectid");
        return nil;
    }
    PFUser *user = [self.mapObjectIdToPFUser objectForKey:objectid];
    if (user == nil) {
        PFQuery *query = [PFUser query];
        [query whereKey:@"objectId" equalTo:objectid];
        // TODO: background this process, or don't run in main thread.
        NSArray *foundUser = [query findObjects];
        
        if (foundUser.count != 1) {
            NSLog(@"Unexpected error, number of users with objectid %@ is %d", objectid, foundUser.count);
        }
        user = [foundUser objectAtIndex:0];
        [self.mapObjectIdToPFUser setObject:user forKey:objectid];
    }
    
    return user;
}

- (void)backgroundOperation {
    if (!myQueue) {
        myQueue = dispatch_queue_create("load.parse.data", NULL);
    }
    dispatch_async(myQueue, ^{[self downloadData];});
    NSLog(@"started downloadData");
}

- (void)downloadData {
    // go through the latestFromUserArray and fix things.
    for (NSMutableDictionary *vchat in self.allChatArray) {

        if ([[vchat objectForKey:@"readyToPlay"] isEqualToString:@"NO"]) {
            // need to download

            PFFile *thisFile = [vchat objectForKey:@"thisFile"];
            NSData *playData = [thisFile getData];
            [vchat setValue:playData forKey:@"sound"];
            
            // there is an error here  if sound < 1 second.  8000 is actually
            // .25 seconds, but okay for now.
            if (playData.length < 8000) {
                // unable to remove because this is a datasource.
                // TODO: abstract datasource from tableview, so we can
                // manipulate data without crashing the tableview.
                [vchat setValue:@(0.5) forKey:@"duration"];
                // [self.allChatArray removeObject:vchat];
                NSLog(@"Error with sound file at %@, deleting",vchat[@"timestamp"]);
                
                // TODO: should I set this to readyToPlay?
                
            }
                // this allows the file to be written.
                [vchat setValue:NULL forKey:@"thisFile"];
                [vchat setValue:@"YES" forKey:@"readyToPlay"];
                NSLog(@"finished downloading %@ msg",[vchat objectForKey:@"timestamp"]);
           
        } else {
//            NSLog(@"already downloaded %@ msg",[vchat objectForKey:@"timestamp"]);
        }
    }
    [self.allChatArray writeToFile:self.pathLocalStorage atomically:YES];
    NSLog(@"saved downloaded to %@",self.pathLocalStorage);
    
}

- (void)backgroundOperationGetDisplayName {
    if (!myQueue) {
        myQueue = dispatch_queue_create("load.parse.data", NULL);
    }
    dispatch_async(myQueue, ^{
        for (NSMutableDictionary *vchat in self.allChatArray) {
            [vchat setValue:[self findDisplayNameforObjectid:vchat[@"remoteId"]] forKey:@"displayName"];
//            NSLog(@"got %@", vchat[@"displayName"]);
        }
//        NSLog(@"finished getting Display names");
        // this should run back in main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.myVChatTableView reloadData];
        });
        
    });
    NSLog(@"started getting display names");
    
}

- (void)arrangeData {
    // sort the data from oldest to newest.  or not :-)
    
//    NSLog(@"Presort:");
//    // before sort
//    for (NSDictionary *eachObj in self.allChatArray) {
//        NSLog(@"time: %@",[eachObj objectForKey:@"timestamp"]);
//    }
    
    [self.allChatArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        // each object is a NSDictionary with a timestamp value
        NSDate *date1 = [obj1 objectForKey:@"timestamp"];
        NSDate *date2 = [obj2 objectForKey:@"timestamp"];
        
        // Use for descending (latest at top)
        return (NSComparisonResult)[date2 compare:date1];

        // Use for ascending (latest at bottom)
        // return (NSComparisonResult)[date1 compare:date2];
    }];
    
//    NSLog(@"Post sort:");
//    // before sort
//    for (NSDictionary *eachObj in self.allChatArray) {
//        NSLog(@"time: %@",[eachObj objectForKey:@"timestamp"]);
//    }

}

// Timer operation.  In lieu of push notification.
- (void)periodicTimerMethod:(NSTimer *)timer {
    NSLog(@"\n\nVChatViewController : periodicTimerMethod (%d)",self.periodicCounter);
    self.periodicCounter++;
    
    [self loadChattingDataFromRepository];
}

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
    NSLog(@"sign up info");
    NSLog(@"%@", info);
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
    if (user[@"additional"] && ![user[@"additional"] isEqualToString:@""]) {
        user[@"displayName"] = user[@"additional"];
        [user saveInBackground];
    }
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
    [signUpViewController setFields:PFSignUpFieldsDefault | PFSignUpFieldsAdditional];
    
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

- (void)updateContacts {
    
}

@end

//
//  ChattingViewController.m
//  VChat
//
//  Created by George Chen on 2/6/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "ChattingViewController.h"
#import "ChattingViewCell.h"

@interface ChattingViewController () {
    dispatch_queue_t myQueue;
    dispatch_queue_t myQueueDataload;
}

@property (weak, nonatomic) IBOutlet UIButton *pushToRecordButton;
@property (nonatomic, strong) NSMutableArray *latestRecordingArray;
@property (weak, nonatomic) IBOutlet UITableView *myChattingTable;

@property (nonatomic, strong) NSMutableArray *allChatArray;
@property (nonatomic, strong) NSMutableArray *userChatArray;

@property (nonatomic, strong) NSString *pathLocalStorage;

@property float startRecordingTime;
@property float endRecordingTime;
@property int indexForPlayback;
@property NSTimeInterval durationRecording;
@property NSInteger rowIsPlaying;
@property (nonatomic, strong) NSIndexPath *playingIndexPath;

// @property (nonatomic, strong) PFUser *user;

- (IBAction)onDownPushToTalk:(id)sender;
- (IBAction)onUpPushToTalk:(id)sender;
- (IBAction)onPlayButton:(id)sender;
- (IBAction)onSendButton:(id)sender;

- (IBAction)onTestButton:(id)sender;
@end

NSString* const RECORDING_CLASSNAME = @"UserRecording";

@implementation ChattingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        NSLog(@"ChattingViewController : initWithNibName");
//        self.localUser = [[PFUser alloc]init];
        self.localUser = [PFUser currentUser];
        self.remoteUser = [[PFUser alloc]init];
        
//        [self.pushToRecordButton setTitle:@"Release to Stop" forState:UIControlStateHighlighted];
//        [self.pushToRecordButton setTitle:@"Hold to Record" forState:UIControlStateNormal];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"ChattingViewController : viewDidLoad");
    // Do any additional setup after loading the view from its nib.
    
    UINib *customNib = [UINib nibWithNibName:@"ChattingViewCell" bundle:nil];
    [self.myChattingTable registerNib:customNib forCellReuseIdentifier:@"ChattingViewCell"];
    
    // Hook up table view
    self.myChattingTable.delegate = self;
    self.myChattingTable.dataSource = self;
    
    // configue the audio system
    
    NSLog(@"chatting between local %@ and remote %@",self.localUser.username, self.remoteUser.username);
    self.title = self.remoteUser.username;
    
    NSString *docsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    self.pathLocalStorage = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"localStorage.%@.plist",self.localUser.username]];

    
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sound.caf"];
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSLog(@"soundFileURL is %@",soundFilePath);
    
    NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:AVAudioQualityMin], AVEncoderAudioQualityKey,
                                    [NSNumber numberWithInt:16], AVEncoderBitRateKey,
                                    [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                                    [NSNumber numberWithFloat:8000.0], AVSampleRateKey,
                                    nil, nil];
    
    NSError *error = nil;
    
    audioRecorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings:recordSettings error:&error];

    [self.pushToRecordButton setTitle:@"Release to Stop" forState:UIControlStateHighlighted];
    [self.pushToRecordButton setTitle:@"Hold to Record" forState:UIControlStateNormal];
    
    self.userChatArray = [[NSMutableArray alloc] init];
    [self loadChatBetweenUsers];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"ChattingViewController : viewWillAppear");
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"ChattingViewController : viewDidAppear");
    [self.myChattingTable setContentOffset:CGPointMake(0, self.myChattingTable.contentSize.height - self.myChattingTable.frame.size.height)];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark TableView Section

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userChatArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ChattingViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChattingViewCell"];
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        NSLog(@"cell was nil, getting a real one");
        cell = [[ChattingViewCell alloc] init];
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    NSDictionary *chat = [self.userChatArray objectAtIndex:indexPath.row];
    
    NSDate *timestamp = [chat objectForKey:@"timestamp"];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd HH:mm"];
    NSString *shortTime = [dateFormatter stringFromDate:timestamp];

    
    
    cell.myChattingViewCellTimeLabel.text = shortTime;
    
    int messageDuration = round([[chat objectForKey:@"duration"] floatValue]);
    if (messageDuration == 0) {
        NSData *soundData = [chat objectForKey:@"sound"];
        messageDuration = soundData.length/32000.0;
        // TODO.  Clean up duration in parse.
    }

    if ([[chat objectForKey:@"fromUser"] isEqualToString:self.localUser.username]) {
        // message from me.  right side.
        messageDuration = -messageDuration;
    }
    cell.myChattingViewCellDrawing.countdown = 4 - [chat[@"listenCount"] integerValue];
    cell.myChattingViewCellDrawing.duration = messageDuration;
    [cell redisplay];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.rowIsPlaying > -1) {
        // playback is occurring.
        if (self.rowIsPlaying == indexPath.row) {
            // stop current playback.
            // TODO - enable a method for pausing playback, not just stopping.
            
            [audioPlayer stop];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            self.rowIsPlaying = -1;
            return;
        }
    }
    
    NSDictionary *chat = [self.userChatArray objectAtIndex:indexPath.row];
    NSData *soundData = [chat objectForKey:@"sound"];
    NSError *outError;
    
    audioPlayer = [[AVAudioPlayer alloc] initWithData:soundData error:&outError];
    
    if (audioPlayer == nil) {
        NSLog(@"Error trying to play %@.",[chat objectForKey:@"timestamp"]);
    } else {
        audioPlayer.delegate = self;
        self.playingIndexPath = indexPath;
        NSLog(@"Playing returned %d",[audioPlayer play]);
        self.rowIsPlaying = indexPath.row;
        [self incrementUserListenCountForIndexPath:indexPath];
    }
}

- (void)incrementUserListenCountForIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *chat = [self.userChatArray objectAtIndex:indexPath.row];
    int listenCount = [chat[@"listenCount"] integerValue];
    listenCount++;
    chat[@"listenCount"] = @(listenCount);
    NSLog(@"Updating listenCount to %d",listenCount);
    
    PFQuery *query = [PFQuery queryWithClassName:@"UserRecording"];
    [query getObjectInBackgroundWithId:chat[@"objectId"] block:^(PFObject *object, NSError *error) {
        object[@"listenCount"] = @(listenCount);
        [object saveInBackground];
    }];
    [self.myChattingTable reloadData];
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"Playback finished");
    if (self.rowIsPlaying > -1) {
        [self.myChattingTable deselectRowAtIndexPath:self.playingIndexPath animated:YES];
    }
    self.playingIndexPath = 0;
    self.rowIsPlaying = -1;
}

//
// load conversation between these two users
//
-(void) loadChatBetweenUsers {
    NSLog(@"ChattingViewController : loadChatBetweenUsers");
    
    self.allChatArray = [[NSMutableArray alloc] initWithContentsOfFile:self.pathLocalStorage];
    
    NSDate *latest_timestamp;
    latest_timestamp = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    
    for (NSDictionary *entry in self.allChatArray) {
        NSString *fromUser = entry[@"fromUser"];
        NSString *toUser = entry[@"toUser"];
        if ([fromUser isEqualToString:self.remoteUser.username] ||
            [toUser isEqualToString:self.remoteUser.username]) {
            
            [self.userChatArray addObject:entry];
            NSDate *timestamp = entry[@"timestamp"];
            if ([timestamp laterDate:latest_timestamp]) {
                latest_timestamp = timestamp;
            }
        }
    }
    NSMutableDictionary *dictToArrayIndex = [[NSMutableDictionary alloc] init];
    if (self.userChatArray.count > 0) {
        int i;
        for (i=0; i<self.userChatArray.count; i++) {
            NSDictionary *dict = [self.userChatArray objectAtIndex:i];
            [dictToArrayIndex setValue:@(i) forKey:dict[@"objectId"]];
        }
    }
 
    // TODO: add more users directly from Parse....
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((fromUser = %@) AND (toUser = %@)) OR ((fromUser = %@) AND (toUser = %@))",self.localUser.username,self.remoteUser.username,self.remoteUser.username,self.localUser.username];
    NSLog(@"Predicate (chatting) %@",predicate);
    NSLog(@"latest_timestamp %@",latest_timestamp);

    // Parse is treating greaterThan like greaterThanOrEqual, so increment timestamp
    latest_timestamp = [latest_timestamp dateByAddingTimeInterval:1];
    
    PFQuery *query = [PFQuery queryWithClassName:@"UserRecording" predicate:predicate];
    [query whereKey:@"timestamp" greaterThan:latest_timestamp];
    [query orderByAscending:@"timestamp"];
    // do not update user's lastRetrieved date.
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (objects.count > 0) {
            for (PFObject *eachObject in objects) {
                
                // does this object already exist?
                if ([dictToArrayIndex objectForKey:eachObject.objectId] != nil) {
                    // just update a few fields
                    NSLog(@"objectid %@ already exists in db",eachObject.objectId);
                    int listenCount = [eachObject[@"listenCount"] integerValue];
                    int objIndex = [[dictToArrayIndex objectForKey:eachObject.objectId] integerValue];
                    NSMutableDictionary *mydict = [self.allChatArray objectAtIndex:objIndex];
                    
                    mydict[@"listenCount"] = @(listenCount);
                } else {
                    
                    NSMutableDictionary *cchat = [[NSMutableDictionary alloc] init];
                    
                    [cchat setValue:eachObject.objectId forKey:@"objectId"];
                    [cchat setValue:[eachObject objectForKey:@"toUser"] forKey:@"toUser"];
                    [cchat setValue:[eachObject objectForKey:@"fromUser"] forKey:@"fromUser"];
                    [cchat setValue:[eachObject objectForKey:@"timestamp"] forKey:@"timestamp"];
                    [cchat setValue:[eachObject objectForKey:@"listenCount"] forKey:@"listenCount"];
                    
                    // link to recording...
                    [cchat setValue:[eachObject objectForKey:@"recording"] forKey:@"thisFile"];
                    [cchat setValue:@"NO" forKey:@"readyToPlay"];
                    
                    [cchat setValue:[eachObject objectForKey:@"duration"] forKey:@"duration"];
                    
                    NSLog(@"msg: from %@ to %@ at%@", cchat[@"fromUser"], cchat[@"toUser"], cchat[@"timestamp"]);
                    
                    [self.userChatArray addObject:cchat];
                }
            }
            // load data
            [self backgroundOperation];
            [self.myChattingTable reloadData];
            
        }
        else {
            NSLog(@"Found no new messages to this user");
            return;
        }
    }];
    
    [self.myChattingTable reloadData];
    [self.myChattingTable setContentOffset:CGPointMake(0, self.myChattingTable.contentSize.height - self.myChattingTable.frame.size.height+50)];
    
}

- (void) backgroundOperation {
    if (!myQueueDataload) {
        myQueueDataload = dispatch_queue_create("load.chat.data", NULL);
    }
    dispatch_async(myQueueDataload, ^{
        [self downloadChatData];
    });
}

- (void) downloadChatData {
    for (NSMutableDictionary *cchat in self.userChatArray) {
        if ([cchat[@"readyToPlay"] isEqualToString:@"NO"]) {
            // download
            PFFile *thisFile = cchat[@"thisFile"];
            NSData *playData = [thisFile getData];
            [cchat setValue:playData forKey:@"sound"];
            [cchat setValue:@"YES" forKey:@"readyToPlay"];
            NSLog(@"finished downloading %@ chat",cchat[@"timestamp"]);
        } else {
            NSLog(@"already downloaded %@ chat",cchat[@"timestamp"]);
        }
    }
}


#pragma mark Audio Section

- (IBAction)onDownPushToTalk:(id)sender {
    // Started holding button
//    self.pushToRecordButton.titleLabel.text = @"Release to stop";
    self.startRecordingTime = [audioRecorder deviceCurrentTime];
    NSLog(@"Recording to %@ at time %.2f",[audioRecorder url],self.startRecordingTime);
    
    [audioRecorder record];
}

- (IBAction)onUpPushToTalk:(id)sender {
    // Stopped holding button
    [audioRecorder stop];
    self.endRecordingTime = [audioRecorder deviceCurrentTime];
    // get duration
    self.durationRecording = self.endRecordingTime - self.startRecordingTime;
    
    NSLog(@"Recording finished at %.2f, delta is %.2f",self.endRecordingTime,self.durationRecording);
    
}

- (IBAction)onPlayButton:(id)sender {
    // Replay last recording
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioRecorder.url error:nil];
    audioPlayer.delegate = self;
    [audioPlayer play];
    NSLog(@"Playback routine started");
}

- (IBAction)onSendButton:(id)sender {
    // Okay to send...
    NSData *recordingData = [[NSData alloc] initWithContentsOfURL:audioRecorder.url];
    NSLog(@"Sending to Parse.  Length of data is %d",recordingData.length);

    // Seems that parse can handle binary data.  That's good because
    // the data would be smaller then.
//    NSString *encodedString = [nsdata base64EncodedStringWithOptions:0];
//    NSLog(@"length of encoded string is %d",[encodedString length]);

    NSString *recordingName = [[NSString alloc] initWithFormat:@"%@_%@_%.1f.caf",self.localUser.username, self.remoteUser.username, self.startRecordingTime];
    NSLog(@"recording name is %@",recordingName);
    PFFile *newFile = [PFFile fileWithName:recordingName data:recordingData];
    
    [newFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"Completed saving of %@",recordingName);
            NSLog(@"Some meta data:\n");
            NSLog(@"is Data Available: %hhd",newFile.isDataAvailable);
            NSLog(@"is Dirty: %hhd", newFile.isDirty);
            NSLog(@"name: %@",newFile.name);
            NSLog(@"url: %@",newFile.url);
            
            // Create an object to facilitate easy retrieval
            PFObject *newRecording = [PFObject objectWithClassName:RECORDING_CLASSNAME];
            [newRecording setObject:newFile forKey:@"recording"];
            [newRecording setObject:self.localUser.username forKey:@"fromUser"];
            [newRecording setObject:self.remoteUser.username forKey:@"toUser"];
            
            [newRecording setObject:self.localUser.objectId forKey:@"fromId"];
            [newRecording setObject:self.remoteUser.objectId forKey:@"toId"];
            
            NSDate *currentTime = [[NSDate alloc]init];
            [newRecording setObject:currentTime forKey:@"timestamp"];
            
            // duration is not strictly necessary, since it can be more accurately
            // calculated from the size of the data.
            [newRecording setObject:@(self.durationRecording) forKey:@"duration"];
            
            // counts how many times the receipient heard the msg
            [newRecording setObject:@(0) forKey:@"listenCount"];
            
            [newRecording saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    NSLog(@"Successfully saved block");
                    [self loadChatBetweenUsers];
                }
                else {
                    NSLog(@"Error saving meta-object for recording: %@ %@", error, [error userInfo]);
                }
            }];
        }
        else {
            NSLog(@"Error during save: %@ %@", error, [error userInfo]);
        }
    }];
}

- (IBAction)onTestButton:(id)sender {
    NSLog(@"PLACEHOLDER FUNCTION - playback the all messages for this user in the last 10 minutes");
    
    // Test to see all users:
    PFQuery *userQuery = [PFUser query];
    userQuery.limit = 20;
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"Found %d nearby users",objects.count);
        
    }];
    
    
    // Form a query for this user.
    PFQuery *query = [PFQuery queryWithClassName:RECORDING_CLASSNAME];
    PFUser *user = [PFUser currentUser];

    NSDate *tenMinutesAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:-600];
    
    [query whereKey:@"toUser" equalTo:user.username];
    [query whereKey:@"timestamp" greaterThan:tenMinutesAgo];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.latestRecordingArray = [NSMutableArray array];
        if (objects.count > 0) {
            for (PFObject *eachObject in objects) {
                [self.latestRecordingArray addObject:eachObject];
            }
            NSLog(@"Found %d messages in the last 10 minutes.  Starting playback.",self.latestRecordingArray.count);
            [self playbackAsBackground];
        }
        else {
            NSLog(@"Found no recordings for the last 10 minutes");
            return;
        }
    }];
}

-(void)playbackAsBackground {
    if (!myQueue) {
        myQueue = dispatch_queue_create("playback.background", NULL);
    }
    dispatch_async(myQueue, ^{
        [self playback];
    });
}

-(void)playback {
    NSLog(@"Playing in background");
    self.indexForPlayback = 0;
    [self playNext];
}

-(void)playNext {
    NSLog(@"Playing next entry");
    if (self.indexForPlayback < self.latestRecordingArray.count) {
        PFFile *thisFile = [self.latestRecordingArray[self.indexForPlayback] objectForKey:@"recording"];
        NSData *playData = [thisFile getData];
        NSLog(@"length of data is %d",playData.length);
        audioPlayer = [[AVAudioPlayer alloc] initWithData:playData error:nil];
        audioPlayer.delegate = self;
        [audioPlayer play];
        NSLog(@"Started playback");
        self.indexForPlayback++;
    }
}

//
// This file should be refactored to use a class that deals with recordings
// and sending the recording to/from Parse.
// 


//- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
//    NSLog(@"Playback completed");
//    [self playNext];
//}


@end

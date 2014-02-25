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
@property (weak, nonatomic) IBOutlet UILabel *recordingSecondLabel;
@property (weak, nonatomic) IBOutlet UIButton *mySendButton;

@property (nonatomic, strong) NSMutableArray *allChatArray;
@property (nonatomic, strong) NSMutableArray *userChatArray;

@property NSDate *latestTimeStamp;

@property (nonatomic, strong) NSString *pathLocalStorage;

@property int recordingTimeInSeconds;
@property float startRecordingTime;
@property float endRecordingTime;
@property int indexForPlayback;
@property NSTimeInterval durationRecording;
@property NSInteger rowIsPlaying;
@property (nonatomic, strong) NSIndexPath *playingIndexPath;

// @property (nonatomic, strong) PFUser *user;

@property NSInteger periodicChattingCounter;
@property NSTimer *myChattingRepeatTimer;

- (IBAction)onDownPushToTalk:(id)sender;
- (IBAction)onUpPushToTalk:(id)sender;
- (IBAction)onPlayButton:(id)sender;
- (IBAction)onSendButton:(id)sender;

- (IBAction)onTestButton:(id)sender;

- (void)periodicChattingTimerMethod:(NSTimer *)timer;

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
    
    self.recordingSecondLabel.text = @"";
    
    // Hook up table view
    self.myChattingTable.delegate = self;
    self.myChattingTable.dataSource = self;
    
    // configue the audio system
    
    NSLog(@"chatting between local %@ and remote %@",self.localUser.username, self.remoteUser.username);
    self.title = self.remoteUser[@"displayName"] ? self.remoteUser[@"displayName"] : self.remoteUser.username;
    
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
    
    self.mySendButton.enabled = NO;
    
    self.latestTimeStamp = [[NSDate alloc] initWithTimeIntervalSince1970:0];

    self.userChatArray = [[NSMutableArray alloc] init];
    [self loadInitialChatDataBeteeenUsers];
    [self loadChatBetweenUsers];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"ChattingViewController : viewWillAppear");
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"ChattingViewController : viewDidAppear");
    [self.myChattingTable setContentOffset:CGPointMake(0, self.myChattingTable.contentSize.height - self.myChattingTable.frame.size.height)];
    
    if (GlobalRepeatTimerFlag == YES) {
        NSLog(@"ChattingViewController : Activating NSTimer");
        self.periodicChattingCounter = 0;
        self.myChattingRepeatTimer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(periodicChattingTimerMethod:) userInfo:nil repeats:YES];
    } else {
        NSLog(@"Skipping NStimer activation");
    }
}

- (void)periodicChattingTimerMethod:(NSTimer *)timer {
    NSLog(@"\n\nChatting repeat timer (%d)",self.periodicChattingCounter);
    self.periodicChattingCounter++;
    [self loadChatBetweenUsers];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"ChattingViewController : viewWillDisappear");
    [self.myChattingRepeatTimer invalidate];
    
    [self.navigationController popViewControllerAnimated:YES];
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

    int senderCount = [chat[SenderCountKey] integerValue];
    int listenCount = [chat[ListenCountKey] integerValue];

    
    NSDate *timestamp = [chat objectForKey:@"timestamp"];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"E, MM/dd HH:mm"];
    NSString *shortTime = [dateFormatter stringFromDate:timestamp];
    
    cell.myChattingViewCellTimeLabel.text = shortTime;
    
    int messageDuration = round([[chat objectForKey:@"duration"] floatValue]);
    if (messageDuration == 0) {
        NSData *soundData = [chat objectForKey:@"sound"];
        messageDuration = soundData.length/32000.0;
        // TODO.  Clean up duration in parse.
    }
    
    NSString *labelDuration = [NSString stringWithFormat:@"%ds",messageDuration];
    NSMutableString *statusString = [[NSMutableString alloc]init];

    if ([[chat objectForKey:@"fromUser"] isEqualToString:self.localUser.username]) {
        // message from me.  right side.
        messageDuration = -messageDuration;
        cell.myChattingViewCellDrawing.countdown = senderCount;
        cell.myChattingViewCellTimeLabel.textAlignment = NSTextAlignmentRight;
        cell.myChattingViewCellStatusLabel.textAlignment = NSTextAlignmentLeft;
        statusString = [NSMutableString stringWithFormat:@"sent %@", shortTime];
        
        if (listenCount == 1) {
            [statusString appendString:@" - delivered"];
        } else if (listenCount > 1) {
            [statusString appendString:@" - heard"];
        }
        
    } else {
        cell.myChattingViewCellDrawing.countdown = listenCount;
        cell.myChattingViewCellTimeLabel.textAlignment = NSTextAlignmentLeft;
        cell.myChattingViewCellStatusLabel.textAlignment = NSTextAlignmentRight;
        statusString = [NSMutableString stringWithFormat:@"received %@",shortTime];
    }
    cell.myChattingViewCellDrawing.duration = messageDuration;
    cell.myChattingViewCellTimeLabel.text = labelDuration;
    cell.myChattingViewCellStatusLabel.text = statusString;
    
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
    
    int count = 0;
    if ([[chat objectForKey:@"fromUser"] isEqualToString:self.localUser.username]) {
        // message from me.  right side.
        count = [chat[SenderCountKey] integerValue];
    } else {
        count = [chat[ListenCountKey] integerValue];
    }
    if (count >= 3) {
        NSLog(@"Playback disabled, count = %d",count);
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        return;
    }
    
    NSData *soundData = [chat objectForKey:@"sound"];
    NSError *outError;
    
    audioPlayer = [[AVAudioPlayer alloc] initWithData:soundData error:&outError];
    
    if (audioPlayer == nil) {
        NSLog(@"Error trying to play %@.",[chat objectForKey:@"timestamp"]);
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

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
    int senderCount = [chat[SenderCountKey] integerValue];
    int listenCount = [chat[ListenCountKey] integerValue];
    if (senderCount == 0) {
        senderCount++;
    }
    
    if ([[chat objectForKey:@"fromUser"] isEqualToString:self.localUser.username]) {
        // message from me.  right side.  update sender count
        senderCount++;
        chat[SenderCountKey] = @(senderCount);
    } else {
        listenCount++;
        chat[ListenCountKey] = @(listenCount);
    }
    NSLog(@"Update counts: listen=%d sender=%d", listenCount, senderCount);
    
    // TODO: optimize by only sending back the object being changed?  maybe it sends back everything anyway.
    PFQuery *query = [PFQuery queryWithClassName:@"UserRecording"];
    [query getObjectInBackgroundWithId:chat[@"objectId"] block:^(PFObject *object, NSError *error) {
        object[ListenCountKey] = @(listenCount);
        object[SenderCountKey] = @(senderCount);
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
-(void) loadInitialChatDataBeteeenUsers {
    NSLog(@"ChattingViewController : loadInitialChatDataBeteeenUsers");
    
    self.allChatArray = [[NSMutableArray alloc] initWithContentsOfFile:self.pathLocalStorage];
    self.userChatArray = [[NSMutableArray alloc] init];
    
    for (NSDictionary *entry in self.allChatArray) {
        NSString *fromUser = entry[@"fromUser"];
        NSString *toUser = entry[@"toUser"];
        if ([fromUser isEqualToString:self.remoteUser.username] ||
            [toUser isEqualToString:self.remoteUser.username]) {
            
            [self.userChatArray addObject:entry];
        }
    }
}

-(void) loadChatBetweenUsers {
    NSLog(@"ChattingViewController : loadChatBetweenUsers");
    
    // sort in ascending order, so latest goes on bottom
    [self.userChatArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        // each object is a NSDictionary with a timestamp value
        NSDate *date1 = [obj1 objectForKey:@"timestamp"];
        NSDate *date2 = [obj2 objectForKey:@"timestamp"];
            
        // Use for descending (latest at top)
        // return (NSComparisonResult)[date2 compare:date1];
            
        // Use for ascending (latest at bottom)
        return (NSComparisonResult)[date1 compare:date2];
    }];
    
    NSMutableDictionary *dictToArrayIndex = [[NSMutableDictionary alloc] init];
    if (self.userChatArray.count > 0) {
        
        // last item in sorted list is the newest.
//        latest_timestamp = [self.userChatArray objectAtIndex:(self.userChatArray.count - 1)][@"timestamp"];
        
        int i;
        for (i=0; i<self.userChatArray.count; i++) {
            NSDictionary *dict = [self.userChatArray objectAtIndex:i];
            [dictToArrayIndex setValue:@(i) forKey:dict[@"objectId"]];
//            NSLog(@"map in dictToArrayIndex key %@ to %d",dict[@"objectId"],i);
        }
    }
    NSLog(@"userChatArray has %d elements",self.userChatArray.count);
 
    // TODO: add more users directly from Parse....
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((fromUser = %@) AND (toUser = %@)) OR ((fromUser = %@) AND (toUser = %@))",self.localUser.username,self.remoteUser.username,self.remoteUser.username,self.localUser.username];
    NSLog(@"Predicate (chatting) %@",predicate);
//    NSLog(@"latest_timestamp %@",latest_timestamp);

    // Parse is treating greaterThan like greaterThanOrEqual, so increment timestamp
//    latest_timestamp = [latest_timestamp dateByAddingTimeInterval:1];
    
    PFQuery *query = [PFQuery queryWithClassName:@"UserRecording" predicate:predicate];
//    [query whereKey:@"timestamp" greaterThan:latest_timestamp];
    [query whereKey:@"updatedAt" greaterThan:self.latestTimeStamp];
    [query orderByAscending:@"timestamp"];
    // do not update user's lastRetrieved date.
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (objects.count > 0) {
            NSLog(@"Retrieved %d new objects",objects.count);
            for (PFObject *eachObject in objects) {
                NSLog(@"New object at timestamp %@ is newer than %@",eachObject[@"timestamp"], self.latestTimeStamp);
                
                // update latestTimeStamp to current
                self.latestTimeStamp = [self.latestTimeStamp laterDate:eachObject[@"updatedAt"]];
                
                NSMutableDictionary *cchat;
                
                // does this object already exist?
                if ([dictToArrayIndex objectForKey:eachObject.objectId] != nil) {
                    // just update a few fields
//                    NSLog(@"objectid %@ already exists in db",eachObject.objectId);
                    int listenCount = [eachObject[ListenCountKey] integerValue];
                    int senderCount = [eachObject[SenderCountKey] integerValue];
                    if (senderCount == 0) {
                        senderCount++;
                    }

                    int objIndex = [[dictToArrayIndex objectForKey:eachObject.objectId] integerValue];
                    cchat = [self.userChatArray objectAtIndex:objIndex];
//                    NSLog(@"object has index %d.  there are %d objects in allChatArray",objIndex, dictToArrayIndex.count);

                    cchat[ListenCountKey] = @(listenCount);
                    cchat[SenderCountKey] = @(senderCount);

                } else {
//                    NSLog(@"generating new recording object");
                    
                    cchat = [[NSMutableDictionary alloc] init];
                    
                    [cchat setValue:eachObject.objectId forKey:@"objectId"];
                    [cchat setValue:[eachObject objectForKey:@"toUser"] forKey:@"toUser"];
                    [cchat setValue:[eachObject objectForKey:@"fromUser"] forKey:@"fromUser"];
                    [cchat setValue:[eachObject objectForKey:@"timestamp"] forKey:@"timestamp"];
                    [cchat setValue:[eachObject objectForKey:ListenCountKey] forKey:ListenCountKey];
                    [cchat setValue:[eachObject objectForKey:SenderCountKey] forKey:SenderCountKey];
                    if ([cchat[SenderCountKey] integerValue] == 0) {
                        cchat[SenderCountKey] = @(1);
                    }
                    
                    // link to recording...
                    [cchat setValue:[eachObject objectForKey:@"recording"] forKey:@"thisFile"];
                    [cchat setValue:@"NO" forKey:@"readyToPlay"];
                    
                    [cchat setValue:[eachObject objectForKey:@"duration"] forKey:@"duration"];
                    
                    NSLog(@"msg: from %@ to %@ at%@", cchat[@"fromUser"], cchat[@"toUser"], cchat[@"timestamp"]);
                    
                    [self.userChatArray addObject:cchat];
                }
                
                if ([cchat[ListenCountKey] integerValue] == 0) {
                    NSLog(@"found listen=0 for msg at %@",cchat[@"timestamp"]);
                    // if I am the receipient, then increment this.
                    if ([cchat[@"toUser"] isEqualToString:self.localUser.username]) {
                        cchat[ListenCountKey] = @(1);
                        eachObject[ListenCountKey] = @(1);
                        [eachObject saveInBackground];
                        NSLog(@"Updating listenCount for object %@",eachObject.objectId);
                    }
                }
            }
            NSLog(@"Data retrieved");
            
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
//            NSLog(@"already downloaded %@ chat",cchat[@"timestamp"]);
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
    
    // start a counter with the number of seconds recorded.
    self.recordingTimeInSeconds = 0;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearRecordingCounter) object:nil];
    [self performSelector:@selector(incrementRecordingCounter) withObject:nil afterDelay:1];
}

- (void) incrementRecordingCounter {
    self.recordingTimeInSeconds++;
    self.recordingSecondLabel.alpha = 1.0f;
    self.recordingSecondLabel.text = [NSString stringWithFormat:@"%d sec",self.recordingTimeInSeconds];
    [self performSelector:@selector(incrementRecordingCounter) withObject:nil afterDelay:1];
}

- (void) clearRecordingCounter {
    self.recordingSecondLabel.text = @"";
}

- (IBAction)onUpPushToTalk:(id)sender {
    // Stopped holding button
    [audioRecorder stop];
    self.endRecordingTime = [audioRecorder deviceCurrentTime];
    // get duration
    self.durationRecording = self.endRecordingTime - self.startRecordingTime;

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(incrementRecordingCounter) object:nil];
    // fade out the time.
//    [self performSelector:@selector(clearRecordingCounter) withObject:nil afterDelay:3];
    
    NSLog(@"Recording finished at %.2f, delta is %.2f",self.endRecordingTime,self.durationRecording);
    if (self.durationRecording > 3.0) {
        self.mySendButton.enabled = YES;
    } else {
        self.mySendButton.enabled = NO;
        self.recordingSecondLabel.text = [NSString stringWithFormat:@"%d sec too short",self.recordingTimeInSeconds];
    }

    [UIView animateWithDuration:2.0 delay:2.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.recordingSecondLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.recordingSecondLabel.text = @"";
    }];
    
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
            [newRecording setObject:@(0) forKey:ListenCountKey];
            [newRecording setObject:@(1) forKey:SenderCountKey];

            [newRecording saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    NSLog(@"Successfully saved block.  Disabling Send again.");
                    self.mySendButton.enabled = NO;
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
    NSLog(@"HIDDEN TEST FUNCTION");
    if (GlobalRepeatTimerFlag == YES) {
        GlobalRepeatTimerFlag = NO;
        NSLog(@"Turned off GlobalRepeatTimer.");
    } else {
        GlobalRepeatTimerFlag = YES;
        NSLog(@"Turned on GlobalRepeatTimer.");
    }
    
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

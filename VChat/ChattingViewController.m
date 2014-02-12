//
//  ChattingViewController.m
//  VChat
//
//  Created by George Chen on 2/6/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "ChattingViewController.h"

@interface ChattingViewController () {
    dispatch_queue_t myQueue;
}

@property (weak, nonatomic) IBOutlet UIButton *pushToRecordButton;
@property (nonatomic, strong) NSMutableArray *latestRecordingArray;
@property (weak, nonatomic) IBOutlet UITableView *myChattingTable;

@property float startRecordingTime;
@property float endRecordingTime;
@property int indexForPlayback;

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
    
    // Hook up table view
    self.myChattingTable.delegate = self;
    self.myChattingTable.dataSource = self;
    
    // configue the audio system
    
    NSArray *dirPaths;
    NSString *docsDir;
    
    NSLog(@"chatting between local %@ and remote %@",self.localUser.username, self.remoteUser.username);
    self.title = self.remoteUser.username;
    
//    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
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
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        NSLog(@"cell was nil, getting a real one");
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"hello %d",indexPath.row];

    return cell;

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
    NSLog(@"Recording finished at %.2f, delta is %.2f",self.endRecordingTime,(self.endRecordingTime - self.startRecordingTime));
    
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
            
            NSDate *currentTime = [[NSDate alloc]init];
            [newRecording setObject:currentTime forKey:@"timestamp"];

            [newRecording saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    NSLog(@"Successfully saved block");
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


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"Playback completed");
    [self playNext];
}


@end

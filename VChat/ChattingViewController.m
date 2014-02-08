//
//  ChattingViewController.m
//  VChat
//
//  Created by George Chen on 2/6/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "ChattingViewController.h"

@interface ChattingViewController ()
@property (weak, nonatomic) IBOutlet UIButton *pushToRecordButton;

@property float startRecordingTime;
@property float endRecordingTime;

// @property (nonatomic, strong) PFUser *user;

- (IBAction)onDownPushToTalk:(id)sender;
- (IBAction)onUpPushToTalk:(id)sender;
- (IBAction)onPlayButton:(id)sender;
- (IBAction)onSendButton:(id)sender;
@end

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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"ChattingViewController : viewDidLoad");
    // Do any additional setup after loading the view from its nib.
    
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
    
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"ChattingViewController : viewWillAppear");

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onDownPushToTalk:(id)sender {
    // Started holding button
    self.pushToRecordButton.titleLabel.text = @"Release to stop";
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
}

- (IBAction)onSendButton:(id)sender {
    // Okay to send...
    NSLog(@"Sending to Parse... but first convert to base64");
    NSData *recordingData = [[NSData alloc] initWithContentsOfURL:audioRecorder.url];
    NSLog(@"length of data is %d",recordingData.length);

    // Seems that parse can handle binary data.  That's good because
    // the data would be smaller then.
//    NSString *encodedString = [nsdata base64EncodedStringWithOptions:0];
//    NSLog(@"length of encoded string is %d",[encodedString length]);

    NSString *recordingName = [[NSString alloc] initWithFormat:@"%@_%@_%.2f",self.localUser.username, self.remoteUser.username, self.startRecordingTime];
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
            
        }
        else {
            NSLog(@"Error during save: %@ %@", error, [error userInfo]);
        }
    }];
    
    
    
    
}

//
// This file should be refactored to use a class that deals with recordings
// and sending the recording to/from Parse.
// 


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"Playback completed");
}


@end

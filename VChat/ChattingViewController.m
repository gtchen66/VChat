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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // configue the audio system
    
    NSArray *dirPaths;
    NSString *docsDir;
    
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
    NSData *nsdata = [[NSData alloc] initWithContentsOfURL:audioRecorder.url];
    NSLog(@"length of data is %d",nsdata.length);
    NSString *encodedString = [nsdata base64EncodedStringWithOptions:0];
    NSLog(@"length of encoded string is %d",[encodedString length]);
    
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"Playback completed");
}


@end

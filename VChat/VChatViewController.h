//
//  VChatViewController.h
//  VChat
//
//  Created by George Chen on 1/22/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@interface VChatViewController : UIViewController <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate> {
    AVAudioPlayer *chatPlayer;
}

@end

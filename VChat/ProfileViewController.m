//
//  ProfileViewController.m
//  VChat
//
//  Created by George Chen on 1/22/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "ProfileViewController.h"
#import "ChattingViewController.h"

@interface ProfileViewController ()
- (IBAction)onGoToChatButton:(id)sender;

@end

@implementation ProfileViewController

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
    NSLog(@"ProfileViewController : viewDidLoad");
    
    self.title = @"My Profile";
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onGoToChatButton:(id)sender {
    // putting this here just so I can test things.
    // this action should be bound to the 'chat' button
    // inside the NearbyUserCell
    NSLog(@"ProfileViewController : onGoToChatButton");
    
    ChattingViewController *cvc = [[ChattingViewController alloc] init];
    [self.navigationController pushViewController:cvc animated:YES];

    
}
@end

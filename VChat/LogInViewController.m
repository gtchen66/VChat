//
//  LogInViewController.m
//  VChat
//
//  Created by Joey Lin on 1/26/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "LogInViewController.h"

@interface LogInViewController ()

@property (nonatomic, strong) UIImageView *fieldsBackground;

@end

@implementation LogInViewController

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
	// Do any additional setup after loading the view.
    
    [self.logInView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"MainBG.png"]]];
//    [self.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]]];
    UILabel *label = [[UILabel alloc] init];
    label.text = @"vChat";
    label.textColor = [UIColor darkGrayColor];
    label.font = [UIFont fontWithName:@"Helvetica Neue" size:40];
    label.textAlignment = NSTextAlignmentCenter;
    [label sizeToFit];
    self.logInView.logo = label;
    
    // Set buttons appearance
    self.logInView.dismissButton.hidden = YES;
//    [self.logInView.dismissButton setImage:[UIImage imageNamed:@"ExitDown.png"] forState:UIControlStateHighlighted];
    
//    [self.logInView.facebookButton setImage:nil forState:UIControlStateNormal];
//    [self.logInView.facebookButton setImage:nil forState:UIControlStateHighlighted];
//    [self.logInView.facebookButton setBackgroundImage:[UIImage imageNamed:@"FacebookDown.png"] forState:UIControlStateHighlighted];
//    [self.logInView.facebookButton setBackgroundImage:[UIImage imageNamed:@"Facebook.png"] forState:UIControlStateNormal];
//    [self.logInView.facebookButton setTitle:@"" forState:UIControlStateNormal];
//    [self.logInView.facebookButton setTitle:@"" forState:UIControlStateHighlighted];
    
//    [self.logInView.twitterButton setImage:nil forState:UIControlStateNormal];
//    [self.logInView.twitterButton setImage:nil forState:UIControlStateHighlighted];
//    [self.logInView.twitterButton setBackgroundImage:[UIImage imageNamed:@"Twitter.png"] forState:UIControlStateNormal];
//    [self.logInView.twitterButton setBackgroundImage:[UIImage imageNamed:@"TwitterDown.png"] forState:UIControlStateHighlighted];
//    [self.logInView.twitterButton setTitle:@"" forState:UIControlStateNormal];
//    [self.logInView.twitterButton setTitle:@"" forState:UIControlStateHighlighted];
    
    [self.logInView.signUpButton setBackgroundImage:[UIImage imageNamed:@"Signup.png"] forState:UIControlStateNormal];
    [self.logInView.signUpButton setBackgroundImage:[UIImage imageNamed:@"SignupDown.png"] forState:UIControlStateHighlighted];
    [self.logInView.signUpButton setTitle:@"" forState:UIControlStateNormal];
    [self.logInView.signUpButton setTitle:@"" forState:UIControlStateHighlighted];
    
    // Add login field background
    self.fieldsBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LoginFieldBG.png"]];
    [self.logInView addSubview:self.fieldsBackground];
    [self.logInView sendSubviewToBack:self.fieldsBackground];
    
    // Remove text shadow
    CALayer *layer = self.logInView.usernameField.layer;
    layer.shadowOpacity = 0.0f;
    layer = self.logInView.passwordField.layer;
    layer.shadowOpacity = 0.0f;
    
    // Set field text color
    [self.logInView.usernameField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    [self.logInView.passwordField setTextColor:[UIColor colorWithRed:135.0f/255.0f green:118.0f/255.0f blue:92.0f/255.0f alpha:1.0]];
    
    // Remove Annoying Labels
//    self.logInView.externalLogInLabel.hidden = YES;
//    self.logInView.signUpLabel.hidden = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Set frame for elements
//    [self.logInView.dismissButton setFrame:CGRectMake(10.0f, 10.0f, 87.5f, 45.5f)];
    [self.logInView.logo setFrame:CGRectMake(66.5f, 100.0f, 187.0f, 58.5f)];
    [self.logInView.usernameField setFrame:CGRectMake(35.0f, 165.0f, 250.0f, 50.0f)];
    [self.logInView.passwordField setFrame:CGRectMake(35.0f, 220.0f, 250.0f, 50.0f)];
    [self.fieldsBackground setFrame:CGRectMake(35.0f, 165.0f, 250.0f, 100.0f)];
    
    [self.logInView.externalLogInLabel setFrame:CGRectMake(35.0f, 317.0f, 250.0f, 20.0f)];
    [self.logInView.facebookButton setFrame:CGRectMake(35.0f, 337.0f, 250.0f, 40.0f)];
    [self.logInView.signUpLabel setFrame:CGRectMake(35.0f, 407.0f, 250.0f, 20.0f)];
    [self.logInView.signUpButton setFrame:CGRectMake(35.0f, 427.0f, 250.0f, 40.0f)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

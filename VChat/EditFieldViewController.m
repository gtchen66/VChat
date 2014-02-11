//
//  EditFieldViewController.m
//  VChat
//
//  Created by Joey Lin on 2/9/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import "EditFieldViewController.h"

@interface EditFieldViewController ()

@property (weak, nonatomic) IBOutlet UITextField *fieldValueTextField;

- (void)onSaveButton;
- (void)onCancelButton;

@end

@implementation EditFieldViewController

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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(onSaveButton)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(onCancelButton)];
    self.title = self.navTitle ? self.navTitle : [self.fieldName capitalizedString];
    self.fieldValueTextField.backgroundColor = [UIColor whiteColor];
    self.fieldValueTextField.text = self.fieldValue;
    NSString *version = [[UIDevice currentDevice] systemVersion];
    NSComparisonResult verComparison = [version compare:@"7.0"];
    if ((verComparison == NSOrderedSame) || (verComparison == NSOrderedDescending)) {
        // running 7.0 or higher.
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onCancelButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onSaveButton {
    // Update user information
    PFUser *currentUser = [PFUser currentUser];
    currentUser[self.fieldName] = [self.fieldValueTextField.text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"EditFieldView: profile updated");
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            NSLog(@"%@", error);
        }
    }];
    
}

@end

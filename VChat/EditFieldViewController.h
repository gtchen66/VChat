//
//  EditFieldViewController.h
//  VChat
//
//  Created by Joey Lin on 2/9/14.
//  Copyright (c) 2014 George Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditFieldViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) NSString *fieldName;
@property (nonatomic, strong) NSString *fieldValue;
@property (nonatomic, strong) NSString *navTitle;

@end

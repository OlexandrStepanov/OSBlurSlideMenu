//
//  MenuViewController.h
//  BlurSlideMenuDemo
//
//  Created by Alexandr Stepanov on 25.04.14.
//  Copyright (c) 2014 StartApp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

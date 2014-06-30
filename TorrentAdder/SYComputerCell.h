//
//  SYComputerCell.h
//  TorrentAdder
//
//  Created by rominet on 20/05/14.
//  Copyright (c) 2014 Syan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SYComputerModel;

@interface SYComputerCell : UITableViewCell

@property (weak,   nonatomic) IBOutlet UILabel *nameLabel;
@property (weak,   nonatomic) IBOutlet UILabel *ipLabel;
@property (weak,   nonatomic) IBOutlet UIView  *onlineView;
@property (weak,   nonatomic) IBOutlet UIView  *selectedBackgroundCustomView;
@property (weak,   nonatomic) IBOutlet UIActivityIndicatorView  *activityIndicator;

@property (strong, nonatomic) SYComputerModel  *computer;
@property (strong, atomic) void(^tapShort)(SYComputerModel* computer);
@property (strong, atomic) void(^tapLong )(SYComputerModel* computer);

@end

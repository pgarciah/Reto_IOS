//
//  RssTableViewCell.h
//  Reto
//
//  Created by Pablo García on 9/6/17.
//  Copyright © 2017 Pablo García. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageViewAsync.h"

@interface RssTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageViewAsync *iv_image;
@property (strong, nonatomic) IBOutlet UILabel *lbl_title;
@property (strong, nonatomic) IBOutlet UILabel *lbl_desc;


@end

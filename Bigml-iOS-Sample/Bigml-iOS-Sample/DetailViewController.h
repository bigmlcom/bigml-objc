//
//  DetailViewController.h
//  Bigml-iOS-Sample
//
//  Created by sergio on 29/03/16.
//  Copyright © 2016 BigML,  Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end


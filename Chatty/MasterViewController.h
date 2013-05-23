//
//  MasterViewController.h
//  Chatty
//
//  Created by Stephen Ryner Jr. on 5/23/13.
//
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@end

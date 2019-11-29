//
//  NINChoiceDialogRow.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 04/10/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import "NINChoiceDialogRow.h"
#import "NINUtils.h"

@interface NINChoiceDialogRow ()

@property (nonatomic, strong) IBOutlet UILabel* titleLabel;

@property (nonatomic, copy) emptyBlock pressedCallback;
@end

@implementation NINChoiceDialogRow

-(IBAction) buttonPressed:(UIButton*)button {
    self.pressedCallback();
}

+(NINChoiceDialogRow*) rowWithTitle:(NSString*)title pressedCallback:(emptyBlock)pressedCallback {
    NINChoiceDialogRow* row = (NINChoiceDialogRow*)loadFromNib(NINChoiceDialogRow.class);
    row.translatesAutoresizingMaskIntoConstraints = NO;

    row.pressedCallback = pressedCallback;

    // Add a faint border
    row.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.4].CGColor;
    row.layer.borderWidth = 0.5;

    row.titleLabel.text = title;

    return row;
}

-(void) dealloc {
    NSLog(@"%@ deallocated.", NSStringFromClass(self.class));
}

@end

//
//  AttributedLabel.h
//
//  Created by ev_mac5 on 04/09/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kWhiteSpaceCharacterSet         @" \n\r.,;:/\\|<>[]{}()~\"`!?$\%^&*+="

@class AttributedLabel;

@protocol AttributedLabelDelegate <NSObject>

- (void)AttributedLabelDidGetTap:(AttributedLabel *)AttributedLabel;
- (void)AttributedLabel:(AttributedLabel *)AttributedLabel didGetTapOnHashText:(NSString *)hashStr;
- (void)AttributedLabel:(AttributedLabel *)AttributedLabel didGetTapOnUserText:(NSString *)userNameStr;

@end


@interface AttributedLabel : UILabel

@property (nonatomic, weak) id<AttributedLabelDelegate> delegate;

- (void)setText:(NSString *)text;

@end

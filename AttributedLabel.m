//
//  AttributedLabel.m
//
//  Created by ev_mac5 on 04/09/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "AttributedLabel.h"

#define kAttributedLabelHashtagStyle      @"hashtagStyle"
#define kAttributedLabelUsernameStyle     @"usernameStyle"

typedef enum {
    
    kAttributedLabelStateNormal = 0,
    kAttributedLabelStateHashtag,
    kAttributedLabelStateUsename
    
} AttributedLabelState;


@interface AttributedLabel ()

@property (nonatomic, strong) NSLayoutManager *layoutManager;
@property (nonatomic, strong) NSTextStorage   *textStorage;
@property (nonatomic, weak)   NSTextContainer *textContainer;

@end


@implementation AttributedLabel

- (void)dealloc
{
    _delegate = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self setupTextSystem];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupTextSystem];
}

- (void)setupTextSystem
{
    self.userInteractionEnabled = YES;
    self.numberOfLines = 0;
    self.lineBreakMode = NSLineBreakByWordWrapping;
    
    self.layoutManager = [NSLayoutManager new];
    
    NSTextContainer *textContainer     = [[NSTextContainer alloc] initWithSize:self.bounds.size];
    textContainer.lineFragmentPadding  = 0;
    textContainer.maximumNumberOfLines = self.numberOfLines;
    textContainer.lineBreakMode        = self.lineBreakMode;
    textContainer.layoutManager        = self.layoutManager;
    
    [self.layoutManager addTextContainer:textContainer];
    self.textContainer = textContainer;
    
    self.textStorage = [NSTextStorage new];
    [self.textStorage addLayoutManager:self.layoutManager];
    self.layoutManager.textStorage = self.textStorage;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.textContainer.size = self.bounds.size;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    self.textContainer.size = self.bounds.size;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textContainer.size = self.bounds.size;
}

- (void)setText:(NSString *)text
{
    [super setText:nil];
    
    self.attributedText = [self attributedTextWithText:text];
    self.textStorage.attributedString = self.attributedText;
    
    [self.gestureRecognizers enumerateObjectsUsingBlock:^(UIGestureRecognizer *recognizer, NSUInteger idx, BOOL *stop) {
        if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) [self removeGestureRecognizer:recognizer];
    }];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(embeddedTextClicked:)]];
}

#pragma mark

- (NSMutableAttributedString *)attributedTextWithText:(NSString *)text
{
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = self.textAlignment;
    style.lineBreakMode = self.lineBreakMode;
    
    NSDictionary *hashStyle   = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:[self.font pointSize]],
                                   NSForegroundColorAttributeName : (self.highlightedTextColor ?: (self.textColor ?: [UIColor darkTextColor])),
                                   NSParagraphStyleAttributeName : style,
                                   kAttributedLabelHashtagStyle : @(YES) };
    
    NSDictionary *nameStyle   = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:[self.font pointSize]],
                                   NSForegroundColorAttributeName : (self.highlightedTextColor ?: (self.textColor ?: [UIColor darkTextColor])),
                                   NSParagraphStyleAttributeName : style,
                                   kAttributedLabelUsernameStyle : @(YES)  };
    
    NSDictionary *normalStyle = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:[self.font pointSize]],
                                   NSForegroundColorAttributeName : (self.textColor ?: [UIColor darkTextColor]),
                                   NSParagraphStyleAttributeName : style };
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:@"" attributes:normalStyle];
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:kWhiteSpaceCharacterSet];
    NSMutableString *token = [NSMutableString string];
    NSInteger length = text.length;
    AttributedLabelState state = kAttributedLabelStateNormal;
    
    for (NSInteger index = 0; index < length; index++)
    {
        unichar sign = [text characterAtIndex:index];
        
        if ([charSet characterIsMember:sign] && state)
        {
            [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:token attributes:state == kAttributedLabelStateHashtag ? hashStyle : nameStyle]];
            state = kAttributedLabelStateNormal;
            [token setString:[NSString stringWithCharacters:&sign length:1]];
        }
        else if (sign == '#' || sign == '@')
        {
            [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:token attributes:normalStyle]];
            state = sign == '#' ? kAttributedLabelStateHashtag : kAttributedLabelStateUsename;
            [token setString:[NSString stringWithCharacters:&sign length:1]];
        }
        else
        {
            [token appendString:[NSString stringWithCharacters:&sign length:1]];
        }
    }
    
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:token attributes:state ? (state == kAttributedLabelStateHashtag ? hashStyle : nameStyle) : normalStyle]];
    return attributedText;
}

- (void)embeddedTextClicked:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [recognizer locationInView:self];
        
        NSUInteger characterIndex = [self.layoutManager characterIndexForPoint:location
                                                               inTextContainer:self.textContainer
                                      fractionOfDistanceBetweenInsertionPoints:NULL];
        
        if (characterIndex < self.textStorage.length)
        {
            NSRange range;
            NSDictionary *attributes = [self.textStorage attributesAtIndex:characterIndex effectiveRange:&range];

            if ([attributes objectForKey:kAttributedLabelHashtagStyle])
            {
                NSString *value = [self.attributedText.string substringWithRange:range];
                [self.delegate AttributedLabel:self didGetTapOnHashText:[value stringByReplacingOccurrencesOfString:@"#" withString:@""]];
            }
            else if ([attributes objectForKey:kAttributedLabelUsernameStyle])
            {
                NSString *value = [self.attributedText.string substringWithRange:range];
                [self.delegate AttributedLabel:self didGetTapOnUserText:[value stringByReplacingOccurrencesOfString:@"@" withString:@""]];
            }
            else
            {
                [self.delegate AttributedLabelDidGetTap:self];
            }
        }
        else
        {
            [self.delegate AttributedLabelDidGetTap:self];
        }
    }
}

@end

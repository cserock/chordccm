//
//  TTTRegexAttributedLabel.h
//  TTTRegexAttributedLabel
//
//  Created by Rousseau Quentin on 02/10/12.
//  Copyright (c) 2013 Quentin Rousseau. All rights reserved.
//

#import "TTTRegexAttributedLabel.h"

@implementation TTTRegexAttributedLabel

- (void) setText:(id)text withFirstMatchRegex:(NSString*)regex withFont:(UIFont*)font
{
  [self setText:text withFirstMatchRegex:regex withFont:font withColor:nil];
}

- (void) setText:(id)text withFirstMatchRegex:(NSString*)regex withFont:(UIFont*)font withColor:(UIColor*)color
{
  [self setText:text withFirstMatchRegex:regex withRegexOptions:NSRegularExpressionCaseInsensitive withFont:font withColor:color];
}
  
- (void) setText:(id)text withFirstMatchRegex:(NSString*)regex withRegexOptions:(NSRegularExpressionOptions)regexOption withFont:(UIFont*)font withColor:(UIColor*)color
{
  NSRegularExpression *rg = [NSRegularExpression regularExpressionWithPattern:regex options:regexOption error:nil];
  NSTextCheckingResult *match = [rg firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
  
  [self setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
    CTFontRef customFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    if (customFont)
    {
      [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)customFont range:match.range];
      if (color)
        [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)color.CGColor range:match.range];
      CFRelease(customFont);
    }
    return mutableAttributedString;
  }];
}

- (void) setText:(id)text withRegex:(NSString*)regex withFont:(UIFont*)font
{
  [self setText:text withRegex:regex withFont:font withColor:nil];
}

- (void) setText:(id)text withRegex:(NSString*)regex withFont:(UIFont*)font withColor:(UIColor*)color
{
  [self setText:text withRegex:regex withRegexOptions:NSRegularExpressionCaseInsensitive withFont:font withColor:color];
}
  
- (void) setText:(id)text withRegex:(NSString*)regex withRegexOptions:(NSRegularExpressionOptions)regexOption withFont:(UIFont*)font withColor:(UIColor*)color
{
  
  NSRegularExpression *rg = [NSRegularExpression regularExpressionWithPattern:regex options:regexOption error:nil];
  
  NSArray *matches = [rg matchesInString:text options:0 range:NSMakeRange(0, [text length])];
  
  [self setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString)
  {
    CTFontRef customFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    
    for (NSTextCheckingResult *match in matches)
    {
      if (customFont)
      {
        [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)customFont range:match.range];
        if(color)
          [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)color.CGColor range:match.range];

      }
    }
    CFRelease(customFont);
    return mutableAttributedString;
  }];
}

- (void) setLyricText:(id)text withBeatCountInBar:(int)beatCount
{
    
    [self setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString)
     {
         
         float spacing = 1.0f;
         
         if([self isPad]){
             
             spacing = 2.4f;
             
             if(beatCount == 6){
                 
                 if(([text length] > 6) && ([text length] < 8)){
                     spacing = -1.2f;
                 } else if(([text length] >= 8) && ([text length] < 10)){
                     spacing = -3.6f;
                 } else if(([text length] >= 10) && ([text length] < 12) ){
                     spacing = -4.8f;
                 } else if([text length] >= 12){
                     spacing = -6.0f;
                 }
                 
                 
             } else {
                 if(([text length] > 8) && ([text length] < 10)){
                     spacing = 0.4f;
                 } else if(([text length] >= 10) && ([text length] < 12) ){
                     spacing = -3.0f;
                 } else if([text length] >= 12){
                     spacing = -4.0f;
                 }
             }
         } else {
             
             if(beatCount == 6){
                 
                 if(([text length] > 6) && ([text length] < 8)){
                     spacing = -1.0f;
                 } else if(([text length] >= 8) && ([text length] < 10)){
                     spacing = -1.6f;
                 } else if(([text length] >= 10) && ([text length] < 12) ){
                     spacing = -2.0f;
                 } else if([text length] >= 12){
                     spacing = -2.4f;
                 }
                 
             } else {
             
                 if(([text length] > 8) && ([text length] < 10)){
                     spacing = 0.0f;
                 } else if(([text length] >= 10) && ([text length] < 12) ){
                     spacing = -1.4f;
                 } else if([text length] >= 12){
                     spacing = -1.6f;
                 }
             }
         }
         
         [mutableAttributedString addAttribute:NSKernAttributeName
                                         value:@(spacing)
                                         range:NSMakeRange(0, [text length])];
         
         NSRegularExpression *rg = [NSRegularExpression regularExpressionWithPattern:@"☐" options:NSRegularExpressionCaseInsensitive error:nil];
         
         NSArray *matches = [rg matchesInString:text options:0 range:NSMakeRange(0, [text length])];
         
         for (NSTextCheckingResult *match in matches)
         {
             [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor clearColor] range:match.range];
         }
         
         return mutableAttributedString;
     }];
}

- (BOOL) isPad {
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 30200)
    if ([[UIDevice currentDevice] respondsToSelector: @selector(userInterfaceIdiom)])
        return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
#endif
    return NO;
}

@end

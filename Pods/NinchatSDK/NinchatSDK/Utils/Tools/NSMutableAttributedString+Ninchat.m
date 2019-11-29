//
//  NSMutableAttributedString+Ninchat.m
//  NinchatSDK
//
//  Created by Matti Dahlbom on 22/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

@import UIKit;

#import "NSMutableAttributedString+Ninchat.h"

/*
 extension NSMutableAttributedString {

 /// Replaces the base font (typically Times) with the given font, while preserving traits like bold and italic
 func setBaseFont(baseFont: UIFont, preserveFontSizes: Bool = false) {
 let baseDescriptor = baseFont.fontDescriptor
 let wholeRange = NSRange(location: 0, length: length)
 beginEditing()
 enumerateAttribute(.font, in: wholeRange, options: []) { object, range, _ in
 guard let font = object as? UIFont else { return }
 // Instantiate a font with our base font's family, but with the current range's traits
 let traits = font.fontDescriptor.symbolicTraits
 guard let descriptor = baseDescriptor.withSymbolicTraits(traits) else { return }
 let newSize = preserveFontSizes ? descriptor.pointSize : baseDescriptor.pointSize
 let newFont = UIFont(descriptor: descriptor, size: newSize)
 self.removeAttribute(.font, range: range)
 self.addAttribute(.font, value: newFont, range: range)
 }
 endEditing()
 }
 }*/

@implementation NSMutableAttributedString (Ninchat)

-(void) overrideFont:(UIFont*)overrideFont {
    [self beginEditing];
    NSRange completeRange = NSMakeRange(0, self.length);

    // Process all font attributes in the string and replace them with the overrideFont
    [self enumerateAttribute:NSFontAttributeName inRange:completeRange options:0 usingBlock:^(id _Nullable value, NSRange range, BOOL* _Nonnull stop) {
        UIFont* font = (UIFont*)value;
        if (![font isKindOfClass:UIFont.class]) {
            return;
        }

        UIFontDescriptor* newDescriptor = [overrideFont.fontDescriptor fontDescriptorWithSymbolicTraits:font.fontDescriptor.symbolicTraits];
        UIFont* newFont = [UIFont fontWithDescriptor:newDescriptor size:overrideFont.fontDescriptor.pointSize];

        [self removeAttribute:NSFontAttributeName range:range];
        [self addAttribute:NSFontAttributeName value:newFont range:range];
    }];

    [self endEditing];
}

@end

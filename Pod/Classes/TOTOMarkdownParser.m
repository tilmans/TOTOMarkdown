//
//  Copyright (c) 2014 Tilman Schlenkr. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TOTOMarkdownParser.h"
#import "TOTOParagraph.h"
#import "TOTOLine.h"

@implementation TOTOMarkdownParser {
    NSDictionary* _regex;
    NSDictionary* _header1;
    NSDictionary* _header2;
    NSDictionary* _header3;
    NSDictionary* _header4;
    NSDictionary* _header5;
    NSDictionary* _header6;
    NSDictionary* _regular;
    NSDictionary* _unknownFormat;
    NSDictionary* _code;
    NSDictionary* _list;
    NSDictionary* _listLastItem;
    
    NSParagraphStyle* _hrParagraph;
    
    NSArray* _lines;
    NSMutableArray* _paragraphs;
    LineType _currentType;
    NSMutableArray* _lineBuffer;
    NSMutableAttributedString* _parsedString;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.textColor = [UIColor whiteColor];
        self.blackHR = NO;
    }
    return self;
}

-(void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    [self setupFonts];
}

-(void)clear {
    _lines = [NSArray array];
    _paragraphs = [NSMutableArray array];
    _currentType = Unknown;
    _lineBuffer = [NSMutableArray array];
}

-(NSAttributedString*)parseMarkdown {
    [self clear];
    [self splitTextToLines];
    [self parseLines];
    
    NSTextAttachment* hrAttachment = [NSTextAttachment new];
    NSString* imageName;
    if (self.blackHR) {
        imageName = @"hrBlack";
    } else {
        imageName = @"hrWhite";
    }
    
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    if (screenScale > 2) {
        imageName = [imageName stringByAppendingString:@"@3x"];
    } else if (screenScale > 1) {
        imageName = [imageName stringByAppendingString:@"@2x"];
    }
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"TOTOMarkdown" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *imagePath = [bundle pathForResource:imageName ofType:@"png"];
    UIImage* image = [UIImage imageWithContentsOfFile:imagePath];
    
    hrAttachment.image = image;
    
    _parsedString = [[NSMutableAttributedString alloc] init];
    for (int it = 0; it<_paragraphs.count; it++) {
        TOTOParagraph* p = _paragraphs[it];
        
        NSDictionary* attributes = [self getStyleForParagraph:p];
        NSString* text;
        if(p.type == List) {
            //TODO: Handle different indent levels
            text = [NSString stringWithFormat:@"•\t%@\n",p.text];
            if (it<(_paragraphs.count-1) && ((TOTOParagraph*)_paragraphs[it+1]).type != List) {
                attributes = _listLastItem;
            }
            [_parsedString appendAttributedString:[[NSAttributedString alloc] initWithString:text
                                                                                  attributes:attributes]];
        } else if (p.type == HR) {
            NSAttributedString* hr = [NSAttributedString attributedStringWithAttachment:hrAttachment];
            NSMutableAttributedString* hrString = [[NSMutableAttributedString alloc] initWithAttributedString:hr];
            [hrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            [hrString addAttribute:NSParagraphStyleAttributeName value:_hrParagraph range:NSMakeRange(0, hrString.string.length)];
            [_parsedString appendAttributedString:hrString];
        } else {
            text = [NSString stringWithFormat:@"%@\n",p.text];
            [_parsedString appendAttributedString:[[NSAttributedString alloc] initWithString:text
                                                                                  attributes:attributes]];
        }
    }
    [self parseInlineMarkup];
    [self unescapeSpecialCharacter:@"(\\\\\\*)" with:@"*"];
    [self unescapeSpecialCharacter:@"(\\\\_)" with:@"_"];
    
    return [[NSAttributedString alloc] initWithAttributedString:_parsedString];
}

-(void)splitTextToLines
{
    NSUInteger length = self.markdown.length;
    NSUInteger paraStart = 0, paraEnd = 0, contentsEnd = 0;
    NSMutableArray* array = [NSMutableArray array];
    NSRange currentRange;
    while (paraEnd < length) {
        [self.markdown getParagraphStart:&paraStart end:&paraEnd
                             contentsEnd:&contentsEnd forRange:NSMakeRange(paraEnd, 0)];
        currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
        [array addObject:[self.markdown substringWithRange:currentRange]];
    }
    _lines = [NSArray arrayWithArray:array];
}

-(void)parseLines
{
    _paragraphs = [NSMutableArray array];
    
    [_lines enumerateObjectsUsingBlock:^(NSString* line, NSUInteger idx, BOOL *stop) {
        TOTOLine* l = [[TOTOLine alloc] initWithLine:line];
        if (l.type == Empty) {
            [self closePreviousParagraph];
        } else if (l.type == HR) {
            [self closePreviousParagraph];
            
            TOTOParagraph* p = [TOTOParagraph new];
            p.type = HR;
            [_paragraphs addObject:p];
        } else if (l.type == Header1 || l.type == Header2 || l.type == Header3 || l.type == Header4 || l.type == Header5 || l.type == Header6) {
            [self closePreviousParagraph];
            
            TOTOParagraph* p = [TOTOParagraph new];
            p.type = l.type;
            p.text = l.text;
            [_paragraphs addObject:p];
        } else if (l.type == Header1Before || l.type == Header2Before) {
            if (_lineBuffer.count == 0) {
                NSLog(@"Header line without previous line. Fail");
                return;
            }
            TOTOLine* lastLine = _lineBuffer[_lineBuffer.count-1];
            [_lineBuffer removeLastObject];
            [self closePreviousParagraph];
            
            if (l.type == Header1Before) {
                _currentType = Header1;
            } else {
                _currentType = Header2;
            }
            [_lineBuffer addObject:lastLine];
            [self closePreviousParagraph];
        } else {
            if (_currentType != l.type) {
                [self closePreviousParagraph];
                _currentType = l.type;
            }
            if (_currentType == Unknown) {
                _currentType = l.type;
            }
            [_lineBuffer addObject:l];
        }
    }];
    
    [self closePreviousParagraph];
}

-(void)closePreviousParagraph
{
    if (_currentType == Unknown) {
        // NSLog(@"Type unknown, loosing %lu lines of text.", (unsigned long)_lineBuffer.count);
    } else if (_currentType == List) {
        [_lineBuffer enumerateObjectsUsingBlock:^(TOTOLine* line, NSUInteger idx, BOOL *stop) {
            NSUInteger paragraphIndent = line.indent / 4;
            TOTOParagraph* p = [TOTOParagraph new];
            p.indent = paragraphIndent;
            p.type = List;
            p.text = line.text;
            [_paragraphs addObject:p];
        }];
    } else if (_currentType == Code) {
        NSMutableArray* lines = [NSMutableArray arrayWithCapacity:_lineBuffer.count];
        [_lineBuffer enumerateObjectsUsingBlock:^(TOTOLine* line, NSUInteger idx, BOOL *stop) {
            [lines addObject:line.text];
        }];
        
        TOTOParagraph* p = [TOTOParagraph new];
        p.type = _currentType;
        p.text = [lines componentsJoinedByString:@"\n"];
        [_paragraphs addObject:p];
    } else {
        NSMutableArray* lines = [NSMutableArray arrayWithCapacity:_lineBuffer.count];
        [_lineBuffer enumerateObjectsUsingBlock:^(TOTOLine* line, NSUInteger idx, BOOL *stop) {
            [lines addObject:line.text];
        }];
        
        TOTOParagraph* p = [TOTOParagraph new];
        p.type = _currentType;
        p.text = [lines componentsJoinedByString:@" "];
        [_paragraphs addObject:p];
    }
    
    _lineBuffer = [NSMutableArray array];
    _currentType = Unknown;
}

-(NSDictionary*)getStyleForParagraph:(TOTOParagraph*)p
{
    NSDictionary* attributes = _unknownFormat;
    
    if (p.type == Header1) {
        attributes = _header1;
    } else if (p.type == Header2) {
        attributes = _header2;
    } else if (p.type == Header3) {
        attributes = _header3;
    } else if (p.type == Header4) {
        attributes = _header4;
    } else if (p.type == Header5) {
        attributes = _header5;
    } else if (p.type == Header6) {
        attributes = _header6;
    } else if (p.type == Regular) {
        attributes = _regular;
    } else if (p.type == Code) {
        attributes = _code;
    } else if (p.type == List) {
        attributes = _list;
    }
    
    return attributes;
}
-(void)setupFonts {
    UIFont* baseFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIFontDescriptor* baseDescriptor = baseFont.fontDescriptor;
    NSUInteger baseFontSize = baseDescriptor.pointSize;
    
    NSMutableParagraphStyle* regular = [NSMutableParagraphStyle new];
    regular.paragraphSpacing = baseFontSize;
    
    NSMutableParagraphStyle *list = [NSMutableParagraphStyle new];
    list.firstLineHeadIndent = 0.0;
    list.headIndent = 14.0;
    NSTextTab *tab = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft location:10.0 options:nil];
    list.tabStops = @[tab];
    
    NSMutableParagraphStyle *listLastItem = [NSMutableParagraphStyle new];
    listLastItem.firstLineHeadIndent = 0.0;
    listLastItem.headIndent = 14.0;
    listLastItem.tabStops = @[tab];
    listLastItem.paragraphSpacing = baseFontSize;
    
    UIFont* systemHeaderFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    UIFontDescriptor* headerDescriptor = systemHeaderFont.fontDescriptor;
    
    _regular = @{NSFontAttributeName: baseFont,
                 NSParagraphStyleAttributeName: regular,
                 NSForegroundColorAttributeName: self.textColor};
    
    _list = @{NSFontAttributeName: baseFont,
              NSParagraphStyleAttributeName: list,
              NSForegroundColorAttributeName: self.textColor};
    _listLastItem = @{NSFontAttributeName: baseFont,
                      NSParagraphStyleAttributeName: listLastItem,
                      NSForegroundColorAttributeName: self.textColor};
    
    _header1 = @{NSFontAttributeName: [UIFont fontWithDescriptor:headerDescriptor size:baseFontSize+8],
                 NSForegroundColorAttributeName: self.textColor};
    _header2 = @{NSFontAttributeName: [UIFont fontWithDescriptor:headerDescriptor size:baseFontSize+5],
                 NSForegroundColorAttributeName: self.textColor};
    _header3 = @{NSFontAttributeName: [UIFont fontWithDescriptor:headerDescriptor size:baseFontSize+4],
                 NSForegroundColorAttributeName: self.textColor};
    _header4 = @{NSFontAttributeName: [UIFont fontWithDescriptor:headerDescriptor size:baseFontSize+3],
                 NSForegroundColorAttributeName: self.textColor};
    _header5 = @{NSFontAttributeName: [UIFont fontWithDescriptor:headerDescriptor size:baseFontSize+2],
                 NSForegroundColorAttributeName: self.textColor};
    _header6 = @{NSFontAttributeName: [UIFont fontWithDescriptor:headerDescriptor size:baseFontSize+1],
                 NSForegroundColorAttributeName: self.textColor};
    
    _code = @{NSFontAttributeName: [UIFont fontWithName:@"Courier New" size:baseDescriptor.pointSize],
              NSForegroundColorAttributeName: self.textColor};
    
    _unknownFormat = @{NSFontAttributeName: baseFont,
                       NSBackgroundColorAttributeName: [UIColor yellowColor],
                       NSForegroundColorAttributeName: [UIColor blackColor]};
    
    NSMutableParagraphStyle* style = [NSMutableParagraphStyle new];
    style.alignment = NSTextAlignmentCenter;
    style.paragraphSpacing = baseFontSize;
    style.paragraphSpacingBefore = baseFontSize;
    _hrParagraph = style;
}

-(void)parseInlineMarkup
{
    NSString* bolditalic    = @"((?<!\\\\)\\*\\*\\*([^\\*\\s].*[^\\\\])(?<!\\\\)\\*\\*\\*)";
    NSString* bolditalic2   = @"((?<!\\\\)\\_\\_\\_([^\\*\\s].*[^\\\\])(?<!\\\\)\\_\\_\\_)";
    NSString* bold          = @"((?<!\\\\)\\*\\*([^\\*\\s].*)(?<!\\\\)\\*\\*)";
    NSString* bold2         = @"((?<!\\\\)\\_\\_([^\\*\\s].*)(?<!\\\\)\\_\\_)";
    NSString* italic        = @"((?<!\\\\)\\*([^\\*\\s].*)(?<!\\\\)\\*)";
    NSString* italic2       = @"((?<!\\\\)\\_([^\\*\\s].*)(?<!\\\\)\\_)";
    
    [self findRegex:bolditalic andReplaceWith:UIFontDescriptorTraitItalic | UIFontDescriptorTraitBold];
    [self findRegex:bolditalic2 andReplaceWith:UIFontDescriptorTraitItalic | UIFontDescriptorTraitBold];
    [self findRegex:bold andReplaceWith:UIFontDescriptorTraitBold];
    [self findRegex:bold2 andReplaceWith:UIFontDescriptorTraitBold];
    [self findRegex:italic andReplaceWith:UIFontDescriptorTraitItalic];
    [self findRegex:italic2 andReplaceWith:UIFontDescriptorTraitItalic];
    
    [self handleLinks];
}

-(void)handleLinks
{
    NSRegularExpression* linkRegex = [NSRegularExpression regularExpressionWithPattern:@"\\[\\s*([^\\]]*)\\s*\\]\\s*\\(\\s*([^\\)]*)\\s*\\)"
                                                                               options:NSRegularExpressionAnchorsMatchLines
                                                                                 error:nil];
    NSTextCheckingResult* result;
    while ((result = [linkRegex firstMatchInString:_parsedString.string options:0 range:NSMakeRange(0, _parsedString.string.length)])) {
        NSRange linkRange = [result rangeAtIndex:2];
        NSRange textRange = [result rangeAtIndex:1];
        NSRange tagRange = [result rangeAtIndex:0];
        NSRange rangeBeforeText = NSMakeRange(tagRange.location, textRange.location-tagRange.location);
        NSRange rangeAfterText = NSMakeRange(textRange.location+textRange.length-1, tagRange.length-textRange.length-1);
        NSRange newTextRange = NSMakeRange(textRange.location - rangeBeforeText.length, textRange.length);
        
        NSString* link = [[_parsedString.string substringWithRange:linkRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        [_parsedString replaceCharactersInRange:rangeBeforeText withString:@""];
        [_parsedString replaceCharactersInRange:rangeAfterText withString:@""];
        
        [_parsedString addAttribute: NSLinkAttributeName value:link range:newTextRange];
    }
}

-(void)findRegex:(NSString*)regexString andReplaceWith:(UIFontDescriptorSymbolicTraits)traits
{
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionAnchorsMatchLines error:nil];

    NSTextCheckingResult* result;
    while ((result = [regex firstMatchInString:_parsedString.string options:0 range:NSMakeRange(0, _parsedString.string.length)])) {
        NSRange textRange = [result rangeAtIndex:2];
        NSRange tagRange = [result rangeAtIndex:1];
        // NSLog(@"%@ -> %@", [_parsedString.string substringWithRange:tagRange],[_parsedString.string substringWithRange:textRange]);
        
        UIFont* font = [_parsedString attribute:NSFontAttributeName atIndex:textRange.location effectiveRange:nil];
        UIFontDescriptor* fontDescriptor = [font.fontDescriptor fontDescriptorWithSymbolicTraits:traits];
        if (!fontDescriptor) {
            // Font does not have this trait, give up
            fontDescriptor = [font fontDescriptor];
        }
        NSMutableAttributedString* text = [NSMutableAttributedString new];
        [text appendAttributedString:[_parsedString attributedSubstringFromRange:textRange]];
        [text addAttribute:NSFontAttributeName value:[UIFont fontWithDescriptor:fontDescriptor size:font.pointSize]
                     range:NSMakeRange(0, text.string.length)];
        [_parsedString replaceCharactersInRange:tagRange withAttributedString:text];
    }
}

-(void)unescapeSpecialCharacter:(NSString*)regexString with:(NSString*)string
{
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:nil];
    NSTextCheckingResult* result;
    while ((result = [regex firstMatchInString:_parsedString.string options:0 range:NSMakeRange(0, _parsedString.string.length)])) {
        if ([result numberOfRanges] > 1) {
            NSRange tagRange = [result rangeAtIndex:1];
            [_parsedString replaceCharactersInRange:tagRange withString:string];
        } else {
            // This is unexpected and probably an error
            NSLog(@"Unexpected regex result for %@",regexString);
            return;
        }
    }
}


@end

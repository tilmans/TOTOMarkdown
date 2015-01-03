//
//  Copyright (c) 2014 Tilman Schlenkr. All rights reserved.
//

#import "TOTOViewController.h"
#import <TOTOMarkdown/TOTOMarkdownParser.h>

@interface TOTOViewController ()

@end

@implementation TOTOViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"md"];
    NSString *testString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%@", testString);
    
    TOTOMarkdownParser* parser = [TOTOMarkdownParser new];
    parser.markdown = testString;
    parser.textColor = [UIColor colorWithHue:.5 saturation:.8 brightness:.4 alpha:1.0];
    self.textView.attributedText = [parser parseMarkdown];
}

@end

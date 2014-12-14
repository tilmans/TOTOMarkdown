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
    TOTOMarkdownParser* parser = [TOTOMarkdownParser new];
    parser.markdown = @"**bold**\n--\n*italic*";
    parser.blackHR = YES;
    parser.textColor = [UIColor blackColor];
    self.textView.attributedText = [parser parseMarkdown];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

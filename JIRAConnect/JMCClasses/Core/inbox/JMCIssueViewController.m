/**
   Copyright 2011 Atlassian Software

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
**/

#import "JMCIssueViewController.h"
#import "JMCMessageCell.h"
#import "JMCViewController.h"
#import "JMCMessageBubble.h"
#import "JMCIssueStore.h"
#import "JMC.h"

@interface JMCIssueViewController ()
@property (nonatomic, strong) UIFont *titleFont;
@end

@implementation JMCIssueViewController

@synthesize tableView = _tableView, issue = _issue;
@synthesize comments = _comments;
@synthesize feedbackController = _feedbackController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        UIBarButtonItem *replyButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply
                                                      target:self
                                                      action:@selector(didTouchReply:)];
        self.navigationItem.rightBarButtonItem = replyButton;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:kJMCNewCommentCreated object:nil];
    }
    return self;
}

- (void)dealloc
{
    self.issue = nil;
}

- (void)scrollToLastComment
{
    if ([self.comments count] > 0 && [self.tableView numberOfRowsInSection:1] > 0) {
        NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:[self.comments count] - 1 inSection:1];
        [self.tableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor clearColor];
    [self scrollToLastComment];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations

    return YES;
}

- (void)setUpCommentDataFor:(JMCIssue *)issue
{
    // the first comment is a dummy comment obj that stores the description of the issue
    JMCComment *description = [[JMCComment alloc] initWithAuthor:@"Author"
                                                      systemUser:YES body:self.issue.description
                                                            date:self.issue.dateCreated
                                                       requestId:self.issue.requestId];
    NSMutableArray *commentData = [NSMutableArray arrayWithObject:description];
    [commentData addObjectsFromArray:issue.comments];
    self.comments = commentData;
}

- (void)setIssue:(JMCIssue *)issue
{
    if (_issue != issue) {
        _issue = issue;
        [self setUpCommentDataFor:issue];

    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil; // no headings
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section == 0) ? 1 : [self.comments count];
}


-(UIFont *)titleFont{

    if(!_titleFont)
        _titleFont = [UIFont boldSystemFontOfSize:14.0];
    return _titleFont;
}

-(CGSize)summaryLabelSize{

    CGSize size;
    CGSize constrainedSize = CGSizeMake(self.tableView.bounds.size.width, self.tableView.bounds.size.height*2.f);

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
        size = [self.issue.summary boundingRectWithSize:constrainedSize
                                                options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{NSFontAttributeName:self.titleFont}
                                                context:nil
        ].size;
    else //if iOS version is below 6, use the method deprected in iOS 7
        size = [self.issue.summary sizeWithFont:self.titleFont
                              constrainedToSize:constrainedSize
                                  lineBreakMode:NSLineBreakByClipping
        ];

    return size;

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)

        return self.summaryLabelSize.height + 10.f;

    else {

        JMCComment *comment = [self.comments objectAtIndex:indexPath.row];
        return [JMCMessageBubble cellSizeForComment:comment widthConstraint:tableView.bounds.size.width].height+8.f;
    }
}

static BOOL isPad(void) {
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
    return NO;
#endif
}

- (UITableViewCell *)getBubbleCell:(UITableView *)tableView forMessage:(JMCComment *)comment
{
    static NSString *cellIdentifierComment = @"JMCMessageCellComment";

    JMCMessageBubble *messageCell = (JMCMessageBubble *) [tableView dequeueReusableCellWithIdentifier:cellIdentifierComment];

    if (!messageCell)
        messageCell = [[JMCMessageBubble alloc] initWithReuseIdentifier:cellIdentifierComment];

    [messageCell setComment:comment leftAligned:comment.systemUser];

    return messageCell;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (indexPath.section == 0) {
        static NSString *cellIdentifier = @"JMCMessageCell";
        JMCMessageCell *issueCell = (JMCMessageCell *) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!issueCell) {

            issueCell = [[JMCMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            issueCell.backgroundColor = [UIColor whiteColor];
            issueCell.selectionStyle = UITableViewCellSelectionStyleNone;

            CGSize size = self.summaryLabelSize;

            issueCell.title = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, tableView.bounds.size.width, size.height)];
            issueCell.title.textAlignment = NSTextAlignmentCenter;
            issueCell.title.font = self.titleFont;
            issueCell.title.textColor = [UIColor colorWithRed:17 / 255.0f green:76 / 255.0f blue:147 / 255.0f alpha:1.0];
            issueCell.autoresizesSubviews = YES;
            issueCell.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            [issueCell addSubview:issueCell.title];
            issueCell.accessoryType = UITableViewCellAccessoryNone;
        }

        issueCell.title.text = self.issue.summary;

        return issueCell;

    }
    else
    {
        JMCComment *comment = [self.comments objectAtIndex:indexPath.row];
        return [self getBubbleCell:tableView forMessage:comment];
    }
}

- (void)didTouchReply:(id)sender
{

    //TODO: using a UINavigationController to get the nice navigationBar at the top of the feedback view. better way to do this?
    self.feedbackController = [[JMCViewController alloc] initWithNibName:@"JMCViewController" bundle:nil];
    self.feedbackController.replyToIssue = self.issue;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.navigationController pushViewController:self.feedbackController animated:YES];
    }
    else {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.feedbackController];
        navController.navigationBar.barStyle = [[JMC sharedInstance] getBarStyle];
        navController.navigationBar.tintColor = [JMC sharedInstance].options.barTintColor;
        [self presentViewController:navController animated:YES completion:nil];
    }
}

-(void)refreshTable
{
    self.issue.comments = [[JMCIssueStore instance] loadCommentsFor:self.issue];
    [self setUpCommentDataFor:self.issue];
    
    [self.tableView reloadData];
    [self scrollToLastComment];
}

@end

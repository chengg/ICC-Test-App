//
//  AnnouncementsViewController.m
//  ICC Test App
//


#import "AnnouncementsViewController.h"


@implementation AnnouncementsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ([super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		
		contents = [[NSMutableArray alloc] init];
		
	}
	
	return self;
}

- (void)dealloc
{
	[contents release];
	[super dealloc];
}

- (void)addAnnouncement:(NSString *)announcement
{
	[contents addObject:announcement];
}

#pragma mark -
#pragma mark tableView datasource

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [contents count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *announcementString = [contents objectAtIndex:rowIndex];

	return announcementString;
}

@end

//
//  ChannelViewController.m
//  ICC Test App
//


#import "ChannelViewController.h"
#import "AppController.h"

@implementation ChannelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ([super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		commandAttributes = [[NSMutableDictionary alloc] init];
		[commandAttributes setObject:[NSFont fontWithName:@"Bitstream Vera Sans Mono"  size:12.0] forKey:NSFontAttributeName];
		[commandAttributes setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
		
	}
	
	return self;
}

- (void)dealloc
{
	[commandAttributes release];
	[super dealloc];
}

- (void)awakeFromNib {
	
	
	[self appendString:[[[NSAttributedString alloc] initWithString:@"" attributes:commandAttributes] autorelease]];
}

- (void)setAppDelegate:(id)appObj
{
	appDelegate = appObj;
}


- (void)setChannel:(int)channelNum
{
	channel = channelNum;
}


- (NSTextField *)channelTextField
{
	return channelTextField;
}


- (void)appendData:(NSData *)d attributes:(NSMutableDictionary *)a
{
	NSLog(@"channel appenddata");
	
	float scrollerPosition = [[[channelTextView enclosingScrollView] verticalScroller] floatValue];
	
	NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
	
	
	NSTextStorage *ts = [channelTextView textStorage];
	
	if (a != nil) {
		NSAttributedString *aString = [[NSAttributedString alloc] initWithString:s attributes:a];
		[[channelTextView textStorage] appendAttributedString:aString];
		[aString release];
	}
	else {
		NSMutableDictionary *a2 = [[NSMutableDictionary alloc] init];
		[a2 setObject:[NSFont fontWithName:@"Bitstream Vera Sans Mono"  size:12.0] forKey:NSFontAttributeName];
		[a2 setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
		NSAttributedString *a2String = [[NSAttributedString alloc] initWithString:s attributes:a2];
		[[channelTextView textStorage] appendAttributedString:a2String];
		[a2String release];
		[a2 release];		
	}
	
	
	[s release];
	
	
	
	//[[outputTV textStorage] appendAttributedString:aString];
	
	if ( scrollerPosition > 0.9999 ) 
		[channelTextView scrollRangeToVisible:NSMakeRange([ts length], 0)];
	
	
	// scroll outputView (the NSTextView) to the very bottom of the text
	//[channelTextView scrollRangeToVisible:NSMakeRange([ts length], 0)];
}



- (void)appendString:(NSAttributedString *)s 
{
	[s retain];
	
	
	
	float scrollerPosition = [[[channelTextView enclosingScrollView] verticalScroller] floatValue];
	
	
	NSTextStorage *ts = [channelTextView textStorage];
	
	if (ts) {
		NSLog(@"channel append string");
		[ts appendAttributedString:s];
	}
	
	if ( scrollerPosition > 0.9999 ) 
		[channelTextView scrollRangeToVisible:NSMakeRange([ts length], 0)];
	
	
	// scroll outputView (the NSTextView) to the very bottom of the text
	//[channelTextView scrollRangeToVisible:NSMakeRange([ts length], 0)];
	
	[s release];
}

- (IBAction)sendCommand:(id)sender
{
	[appDelegate sendCommandStr:[NSString stringWithFormat:@"tell %i: %@", channel, [channelTextField stringValue] ] ];
	
	NSString *commandString = [[channelTextField stringValue] stringByAppendingString:@"\n"];
	[channelTextField setStringValue:@""];
	[channelTextField selectText:self];
	[self appendString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"say: %@", commandString] attributes:commandAttributes] autorelease]];	
}

@end

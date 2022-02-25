//
//  ConsoleViewController.m
//  ICC Test App
//


#import "ConsoleViewController.h"
#import "AppController.h"

@implementation ConsoleViewController

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


- (void)awakeFromNib
{
}

- (void)setAppDelegate:(id)appObj
{
	appDelegate = appObj;
}


- (NSTextField *)consoleTextField
{
	return consoleTextField;
}

- (void)appendData:(NSData *)d attributes:(NSMutableDictionary *)a
{
	float scrollerPosition = [[[consoleTextView enclosingScrollView] verticalScroller] floatValue];
	
	NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
	
	
	NSTextStorage *ts = [consoleTextView textStorage];
	
	if (a != nil) {
		NSAttributedString *aString = [[NSAttributedString alloc] initWithString:s attributes:a];
		[ts appendAttributedString:aString];
		[aString release];
	}
	else {
		NSMutableDictionary *a2 = [[NSMutableDictionary alloc] init];
		[a2 setObject:[NSFont fontWithName:@"Bitstream Vera Sans Mono"  size:12.0] forKey:NSFontAttributeName];
		[a2 setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
		NSAttributedString *a2String = [[NSAttributedString alloc] initWithString:s attributes:a2];
		[ts appendAttributedString:a2String];
		[a2String release];
		[a2 release];		
	}
	
	
	[s release];
	
	
	
	//[[outputTV textStorage] appendAttributedString:aString];
	
	if ( scrollerPosition > 0.9999 ) 
		[consoleTextView scrollRangeToVisible:NSMakeRange([ts length], 0)];
	
	
	// scroll outputView (the NSTextView) to the very bottom of the text
	[consoleTextView scrollRangeToVisible:NSMakeRange([ts length], 0)];
}

- (void)appendString:(NSString *)s attributes:(NSMutableDictionary *)a
{
	float scrollerPosition = [[[consoleTextView enclosingScrollView] verticalScroller] floatValue];
	
	
	NSTextStorage *ts = [consoleTextView textStorage];
	
	if (a != nil) {
		NSAttributedString *aString = [[NSAttributedString alloc] initWithString:s attributes:a];
		[ts appendAttributedString:aString];
		[aString release];
	}
	else {
		NSMutableDictionary *a2 = [[NSMutableDictionary alloc] init];
		[a2 setObject:[NSFont fontWithName:@"Bitstream Vera Sans Mono"  size:12.0] forKey:NSFontAttributeName];
		[a2 setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
		NSAttributedString *a2String = [[NSAttributedString alloc] initWithString:s attributes:a2];
		[ts appendAttributedString:a2String];
		[a2String release];
		[a2 release];		
	}
	
	if ( scrollerPosition > 0.9999 ) 
		[consoleTextView scrollRangeToVisible:NSMakeRange([ts length], 0)];
	
	
	// scroll outputView (the NSTextView) to the very bottom of the text
	[consoleTextView scrollRangeToVisible:NSMakeRange([ts length], 0)];
}

- (IBAction)sendCommand:(id)sender
{
	[appDelegate sendCommandStr:[consoleTextField stringValue]];
	
	NSString *commandString = [[consoleTextField stringValue] stringByAppendingString:@"\n"];
	[consoleTextField setStringValue:@""];
	[consoleTextField selectText:self];
	[self appendString:[NSString stringWithFormat:@"cmd> %@", commandString] attributes:commandAttributes];	
}

@end

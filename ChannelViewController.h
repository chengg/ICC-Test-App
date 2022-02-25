//
//  ChannelViewController.h
//  ICC Test App
//


#import <Cocoa/Cocoa.h>


@interface ChannelViewController : NSViewController {
	
	IBOutlet NSTextView *channelTextView;
	IBOutlet NSTextField *channelTextField;
	
	id appDelegate;
		
	int channel;
	
	NSMutableDictionary *commandAttributes;

}
- (void)setChannel:(int)channelNum;
- (NSTextField *)channelTextField;
- (void)setAppDelegate:(id)appObj;
- (void)appendData:(NSData *)d attributes:(NSMutableDictionary *)a;
- (void)appendString:(NSAttributedString *)s;
- (IBAction)sendCommand:(id)sender;

@end

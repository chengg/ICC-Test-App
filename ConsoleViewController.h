//
//  ConsoleViewController.h
//  ICC Test App
//


#import <Cocoa/Cocoa.h>

@class AppController;

@interface ConsoleViewController : NSViewController {

	IBOutlet NSTextView *consoleTextView;
	IBOutlet NSTextField *consoleTextField;
	
	id appDelegate;
	
	NSMutableDictionary *commandAttributes;
	
}

- (NSTextField *)consoleTextField;
- (void)setAppDelegate:(id)appObj;
- (void)appendData:(NSData *)d attributes:(NSMutableDictionary *)a;
- (void)appendString:(NSString *)s attributes:(NSMutableDictionary *)a;
- (IBAction)sendCommand:(id)sender;
@end

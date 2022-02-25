//
//  MainWindowController.h
//  ICC Test App
//


#import <Cocoa/Cocoa.h>

@class GCOutlineView;
@class ConsoleViewController;
@class ChannelViewController;
@class SeparatorCell;

@interface MainWindowController : NSWindowController {

	IBOutlet GCOutlineView		*myOutlineView;
	IBOutlet NSTreeController	*treeController;
	IBOutlet NSView				*placeHolderView;
	IBOutlet NSSplitView		*splitView;

	id							appDelegate;
	
	NSMutableArray				*contents;
	
	NSView						*currentView;
	ConsoleViewController		*consoleViewController;
	
	
	NSImage						*consoleImage;
	NSImage						*chatImage;
	
	BOOL						buildingOutlineView;	// signifies we are building the outline view at launch time
	BOOL						addingChannel;
	
	NSArray						*dragNodesArray; // used to keep track of dragged nodes
	
	//BOOL						retargetWebView;
	
	SeparatorCell				*separatorCell;	// the cell used to draw a separator line in the outline view

	NSIndexPath					*consoleIndexPath;
		
	NSMutableDictionary			*channelsDict;
	NSMutableDictionary			*channelIndexPathDict;
	
	NSMutableArray				*channelsArray;
}
@property (retain) NSArray *dragNodesArray;

- (void)setAppDelegate:(id)appObj;
- (void)appendData:(NSData *)d attributes:(NSMutableDictionary *)a;
- (void)appendString:(NSString *)s attributes:(NSMutableDictionary *)a;
- (void)appendToChannel:(NSString *)channelStr string:(NSAttributedString *)s;
- (void)addChannel:(NSString *)channelStr;
- (void)removeChannel:(NSString *)channelStr;
@end

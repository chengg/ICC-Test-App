//
//  GameListController.h
//  ICC Test App
//


#import <Cocoa/Cocoa.h>
#import <BWToolkitFramework/BWToolkitFramework.h>
#import "Game.h"

@class Game;

@interface GameListController : NSWindowController {

	IBOutlet NSTableView *tableView;
	IBOutlet NSToolbar *toolbar;
	
	NSMutableArray *games;
	
	NSString *owner;
	
	BOOL isHistory;
	
	id gameListCallback;
	
}
@property (readwrite, copy) NSMutableArray *games;

- (void)setCallback:(id)obj;
- (void)setListInfo:(NSDictionary *)infoDict;
- (void)addGame:(NSDictionary *) gameDict;
//- (void)savePGN:(NSString *)pgnStr;
//- (void)didEnd:(NSSavePanel *)sheet returnCode:(int)code contextInfo:(void *)contextInfo;
- (IBAction)examineGame:(id)sender;
- (IBAction)mailGame:(id)sender;
- (IBAction)spositionGame:(id)sender;
- (IBAction)logPGNGame:(id)sender;

@end

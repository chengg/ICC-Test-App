//
//  AppController.h
//  ICC Test App
//

#import <Cocoa/Cocoa.h>
#import "Parser.h"
#import "BoardController.h"
#import "StringList.h"
#import "GameListController.h"

@class Parser;
@class BoardController;
@class StringList;
@class GameListController;
@class MainWindowController;

extern NSString * const GCUsernameKey;
extern NSString * const GCPasswordKey;
extern NSString * const	GCRememberLoginKey;
extern NSString * const GCAutomaticLoginKey;

@interface AppController : NSObject {
	IBOutlet NSTextView *outputView;
	IBOutlet NSTextField *textField;
	IBOutlet id window;

	IBOutlet NSWindow *consoleWindow;
	
	MainWindowController *mainWindowController;
	
	// login sheet
	IBOutlet NSWindow *loginSheet;
	IBOutlet NSTextField *usernameTextField;
	IBOutlet NSTextField *passwordTextField;
	IBOutlet NSButton *rememberCheckBox;
	IBOutlet NSButton *automaticCheckBox;
	IBOutlet NSPopUpButton *serverPopUpButton;
	
	BOOL connected;
	
	NSBundle *appBundle;
	
	NSString *me;
	
	Parser *parser;
	
	NSMutableDictionary *boardDict;
	NSMutableArray *gameListArray;
	
	GameListController *currentGameList;

	NSNotificationCenter *nc;
	
	NSMutableDictionary *attributes;
	NSMutableDictionary *regularAttributes;
	NSMutableDictionary *tellAttributes;
	NSMutableDictionary *tellBoardAttributes;
	NSMutableDictionary *commandAttributes;
	
	NSSound *gameStartedSound;
	NSSound *moveSound;
	NSSound *welcomeSound;
	NSSound *tellSound;

	
}
- (IBAction)showLoginSheet:(id)sender;
- (IBAction)retractLoginSheet:(id)sender;
- (IBAction)startConnection:(id)sender;
- (IBAction)sendCommand:(id)sender;
- (void)sendCommandStr:(NSString *)str;
- (void)appendData:(NSData *)d attributes:(NSMutableDictionary *)a;
- (void)appendString:(NSString *)s attributes:(NSMutableDictionary *)a;
- (void)appendAttributedString:(NSAttributedString *)aString;
- (IBAction)closeConnection:(id)sender;
- (void)disconnected;

// DG methods
- (void)unmatchedData:(id)str;
- (void)whoami:(id)dgArray;
- (void)myGameStarted:(id)dgArray; 
- (void)positionBegin:(id)dgArray;
- (void)sendMoves:(id)dgArray;
- (void)gameResult:(id)dgArray;
- (void)flip:(id)dgArray;
- (void)illegalMove:(id)dgArray;
- (void)kibitz:(id)dgArray;
- (void)personalTell:(id)dgArray;
- (void)myRelationToGame:(id)dgArray;
- (void)circle:(id)dgArray;
- (void)takeback:(id)dgArray;
- (void)gamelistBegin:(id)dgArray;
- (void) gamelistItem:(id)dgArray;
- (void)gameMessage:(id)dgArray;
- (void)loginFailed:(id)dgArray;
- (void)logPGN:(id)dgArray;
- (void)didEnd:(NSSavePanel *)sheet returnCode:(int)code contextInfo:(void *)contextInfo;
@end

//
//  Game.h
//  ICC Test App
//


#import <Cocoa/Cocoa.h>


@interface Game : NSObject {

	int index;
	
	int idNum;
	
	NSString *event;
	NSString *date;
	NSString *time;
	
	NSString *whitePlayer;
	NSString *blackPlayer;
	
	int whiteRating;
	int blackRating;
	
	int rated;
	int ratingType;
	int wild;
	
	int initTimeWhite;
	int initTimeBlack;
	int incrementWhite;
	int incrementBlack;
	
	NSString *eco;

	int status;
	int color;
	int mode;
	
	NSString *note;
		
	int here;
	
	NSString *gametype;
	NSString *result;
	NSString *end;
	
	NSString *ownerResult;
	NSString *ownerColor;
	NSString *ownerOpponent;
	int ownerRating;
	int ownerOpponentRating;
	
	NSString *timeAndDate;
}
@property (readwrite, copy) NSString *event;
@property (readwrite, copy) NSString *date;
@property (readwrite, copy) NSString *time;
@property (readwrite, copy) NSString *whitePlayer;
@property (readwrite, copy) NSString *blackPlayer;
@property (readwrite, copy) NSString *eco;
@property (readwrite, copy) NSString *note;
@property (readwrite) int index;
@property (readwrite) int idNum;
@property (readwrite) int whiteRating;
@property (readwrite) int blackRating;
@property (readwrite) int rated;
@property (readwrite) int ratingType;
@property (readwrite) int wild;
@property (readwrite) int initTimeWhite;
@property (readwrite) int initTimeBlack;
@property (readwrite) int incrementWhite;
@property (readwrite) int incrementBlack;
@property (readwrite) int status;
@property (readwrite) int color;
@property (readwrite) int mode;
@property (readwrite) int here;

@property (readwrite, copy) NSString *gametype;
@property (readwrite, copy) NSString *result;
@property (readwrite, copy) NSString *end;

@property (readwrite, copy) NSString *ownerResult;
@property (readwrite, copy) NSString *ownerColor;
@property (readwrite, copy) NSString *ownerOpponent;
@property (readwrite) int ownerRating;
@property (readwrite) int ownerOpponentRating;

@property (readwrite, copy) NSString *timeAndDate;

@end

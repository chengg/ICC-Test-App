//
//  Game.m
//  ICC Test App
//


#import "Game.h"


@implementation Game

@synthesize event;
@synthesize date;
@synthesize time;
@synthesize whitePlayer;
@synthesize blackPlayer;
@synthesize eco;
@synthesize note;
@synthesize index;
@synthesize idNum;
@synthesize whiteRating;
@synthesize blackRating;
@synthesize rated;
@synthesize ratingType;
@synthesize wild;
@synthesize initTimeWhite;
@synthesize initTimeBlack;
@synthesize incrementWhite;
@synthesize incrementBlack;
@synthesize status;
@synthesize color;
@synthesize mode;
@synthesize here;

@synthesize gametype;
@synthesize result;
@synthesize end;

@synthesize ownerResult;
@synthesize ownerColor;
@synthesize ownerOpponent;
@synthesize ownerRating;
@synthesize ownerOpponentRating;

@synthesize timeAndDate;

- (id)init
{
	[super init];
	
	index = 0;
	idNum = 0;
	
	event = @"";
	date = @"1/1/1900";
	time = @"00:00:00";
	
	whitePlayer = @"White Player";
	blackPlayer = @"Black Player";
	
	whiteRating = 0;
	blackRating = 0;
	
	rated = 0;
	ratingType = 0;
	wild = 0;
	
	initTimeWhite = 0;
	initTimeBlack= 0;
	incrementWhite = 0;
	incrementBlack = 0;
	
	eco = @"";
	
	status = 0;
	color = 0;
	mode = 0;
	
	note = @"";
	
	here = 0;
	
	gametype = @"";
	result = @"";
	end = @"";
	
	ownerResult = @"";
	ownerColor = @"";
	ownerOpponent = @"";
	ownerRating = 0;
	ownerOpponentRating = 0;
	
	timeAndDate = @"";
	
	return self;
}

- (void)dealloc
{
	[event release];
	[date release];
	[time release];
	[whitePlayer release];
	[blackPlayer release];
	[eco release];
	[note release];
	
	[gametype release];
	[result release];
	[end release];
	
	[ownerResult release];
	[ownerColor release];
	[ownerOpponent release];

	[timeAndDate release];
	
	[super dealloc];
}

@end

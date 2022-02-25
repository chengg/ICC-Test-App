//
//  GameListController.m
//  ICC Test App
//

#import "GameListController.h"

@implementation GameListController

@synthesize games;

- (id)init
{
	[super init];
	
	games = [[NSMutableArray alloc] initWithCapacity:20];
	
	owner = [[NSString alloc] initWithString:@""];
	
	isHistory = NO;
	
	//[tableView setDoubleAction:@selector(examineGame:)];
	
	return self;
}

- (void)dealloc
{
	[games release];
	[owner release];
	
	[super dealloc];
}

- (void)setCallback:(id)obj
{
	gameListCallback = obj;
}

- (void)setListInfo:(NSDictionary *)infoDict
{
	[infoDict retain];
	
	[tableView setDoubleAction:@selector(examineGame:)];
	
	NSLog(@"set info for list");
	
	[[self window] setTitle:[infoDict objectForKey:@"summary"]];
	
	[[self window] makeKeyWindow];
	
	owner = [[infoDict objectForKey:@"parameters"] copy];
	
	NSLog(@"owner: %@", owner);
	
	if ([[infoDict objectForKey:@"command"] isEqualToString:@"history"]) 
		isHistory = YES;
	else
		isHistory = NO;
	
	[infoDict release];
}


- (void)addGame:(NSDictionary *) gameDict
{
	[gameDict retain];
	
	NSLog(@"adding game");
	
	Game *game = [[Game alloc] init];
	
	game.index = [[gameDict objectForKey:@"index"] intValue];
	game.idNum = [[gameDict objectForKey:@"id"] intValue];
	
	if ([[gameDict objectForKey:@"event"] isEqualToString:@"?"])
		game.event = @"";
	else
		game.event = [gameDict objectForKey:@"event"];
	
	game.date = [gameDict objectForKey:@"date"];
	game.time = [gameDict objectForKey:@"time"];
	
	game.timeAndDate = [NSString stringWithFormat:@"%@ %@", game.date, game.time];
	
	game.whitePlayer = [gameDict objectForKey:@"white-name"];
	game.blackPlayer = [gameDict objectForKey:@"black-name"];
	game.whiteRating = [[gameDict objectForKey:@"white-rating"] intValue];
	game.blackRating = [[gameDict objectForKey:@"black-rating"] intValue];
	
	if (isHistory) {
		if ([game.whitePlayer isEqualToString:owner]) {
			game.ownerColor = @"W";
			game.ownerOpponent = game.blackPlayer;
			game.ownerRating = game.whiteRating;
			game.ownerOpponentRating = game.blackRating;
		}
		else if ([game.blackPlayer isEqualToString:owner]) {
			game.ownerColor = @"B";
			game.ownerOpponent = game.whitePlayer;
			game.ownerRating = game.blackRating;
			game.ownerOpponentRating = game.whiteRating;
		}
	}
	
	game.rated = [[gameDict objectForKey:@"rated"] intValue];
	game.ratingType = [[gameDict objectForKey:@"rating-type"] intValue];
	game.wild = [[gameDict objectForKey:@"wild"] intValue];
	game.initTimeWhite = [[gameDict objectForKey:@"init-time-W"] intValue];
	game.initTimeBlack = [[gameDict objectForKey:@"init-time-B"] intValue];
	game.incrementWhite = [[gameDict objectForKey:@"int-W"] intValue];
	game.incrementBlack = [[gameDict objectForKey:@"int-B"] intValue];
	
	NSString *rated = @"";
	if (game.rated == 0) 
		rated = @"(U)";
	
	NSString *ratingType = @"";
	
	NSLog(@"rating type: %i", game.ratingType);
	
	switch (game.ratingType) {
		case 0:
			ratingType = @"wild";
			break;
		case 1:
			ratingType = @"blitz";
			break;
		case 2:
			ratingType = @"standard";
			break;
		case 3:
			ratingType = @"bullet";
			break;
		case 4:
			ratingType = @"bughouse";
			break;
		case 7:
			ratingType = @"5-minute";
			break;
		case 8:
			ratingType = @"1-minute";
			break;
		default:
			break;
	}
	
	if (game.initTimeWhite == game.initTimeBlack && game.incrementWhite == game.incrementBlack) {
		game.gametype = [NSString stringWithFormat:@"%@ %i %i %@", ratingType, game.initTimeWhite, game.incrementWhite, rated];
	}
	else {
		game.gametype = [NSString stringWithFormat:@"%@ %i %i %i %i %@", 
						 ratingType, game.initTimeWhite, game.incrementWhite, game.initTimeBlack, game.incrementBlack, rated];
	}
	
	if ([[gameDict objectForKey:@"eco"] isEqualToString:@"?"])
		game.eco = @"";
	else
		game.eco = [gameDict objectForKey:@"eco"];
	
	game.status = [[gameDict objectForKey:@"status"] intValue];
	game.color = [[gameDict objectForKey:@"color"] intValue];
	game.mode = [[gameDict objectForKey:@"mode"] intValue];
	
	if (game.status == 0) {
		switch (game.color) {
			case 0:
				
				if (isHistory && [game.ownerColor isEqualToString:@"W"])
					game.ownerResult = @"+";
				else if (isHistory && [game.ownerColor isEqualToString:@"B"])
					game.ownerResult = @"-";
				
				game.result = @"1-0";
				break;
			case 1:
				
				if (isHistory && [game.ownerColor isEqualToString:@"W"])
					game.ownerResult = @"-";
				else if (isHistory && [game.ownerColor isEqualToString:@"B"])
					game.ownerResult = @"+";
				
				game.result = @"0-1";
				break;
			default:
				break;
		}
		
		switch (game.mode) {
			case 0:
				game.end = @"Res";
				break;
			case 1:
				game.end = @"Mat";
				break;
			case 2:
				game.end = @"Fla";
				break;
			case 3:
				game.end = @"Adj";
				break;
			case 4:
				game.end = @"BQ";
				break;
			case 5:
				game.end = @"BQ";
				break;
			case 6:
				game.end = @"BQ";
				break;
			case 7:
				game.end = @"Res";
				break;
			case 8:
				game.end = @"Mat";
				break;
			case 9:
				game.end = @"Fla";
				break;
			case 10:
				game.end = @"BQ";
				break;
			case 11:
				game.end = @"BQ";
				break;
			case 12:
				game.end = @"1-0";
				break;
			default:
				break;
		}
	}
	else if (game.status == 1) {
		game.result = @"\u00BD-\u00BD";
		
		if (isHistory)
			game.ownerResult = @"=";
		
		switch (game.mode) {
			case 0:
				game.end = @"Agr";
				break;
			case 1:
				game.end = @"Sta";
				break;
			case 2:
				game.end = @"Rep";
				break;
			case 3:
				game.end = @"50";
				break;
			case 4:
				game.end = @"TM";
				break;
			case 5:
				game.end = @"NM";
				break;
			case 6:
				game.end = @"NT";
				break;
			case 7:
				game.end = @"Adj";
				break;
			case 8:
				game.end = @"Agr";
				break;
			case 9:
				game.end = @"NT";
				break;
			case 10:
				game.end = @"\u00BD";
				break;
			default:
				break;
		}
	}
	else if (game.status == 2) {
		game.result = @"*";
		game.end = @"";
	}
	else if (game.status == 3) {
		game.result = @"";
		
		if (isHistory)
			game.ownerResult = @"a";
		
		switch (game.mode) {
			case 0:
				game.end = @"Agr";
				break;
			case 1:
				game.end = @"BQ";
				break;
			case 2:
				game.end = @"SD";
				break;
			case 3:
				game.end = @"BA";
				break;
			case 4:
				game.end = @"Adj";
				break;
			case 5:
				game.end = @"Sho";
				break;
			case 6:
				game.end = @"Sho";
				break;
			case 7:
				game.end = @"BQ";
				break;
			case 8:
				game.end = @"Sho";
				break;
			case 9:
				game.end = @"Sho";
				break;
			case 10:
				game.end = @"Adj";
				break;
			case 11:
				game.end = @"BQ";
				break;
			default:
				break;
		}
		
	}
	
	
	game.note = [gameDict objectForKey:@"here"];
	game.here = [[gameDict objectForKey:@"here"] intValue];
		
	[[self mutableArrayValueForKey:@"games"] addObject:game];
		
	[gameDict release];
}

/*
- (void)savePGN:(NSString *)pgnStr
{	
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:@"pgn"];
	[panel beginSheetForDirectory:nil 
							 file:nil 
				   modalForWindow:[self window] 
					modalDelegate:self 
				   didEndSelector:@selector(didEnd:returnCode:contextInfo:) 
					  contextInfo:[pgnStr retain]];
	
	NSLog(@"pgn: %@", pgnStr);
}

- (void)didEnd:(NSSavePanel *)sheet returnCode:(int)code contextInfo:(void *)contextInfo
{
	if (code != NSOKButton)
		return;
	
	NSLog(@"pgn string: %@", (NSString *)contextInfo);
	
	NSData *data = [(NSString *)contextInfo dataUsingEncoding:NSUTF8StringEncoding];
	NSString *path = [sheet filename];
	NSError *error;
	BOOL successful = [data writeToFile:path options:0 error:&error];
	
	if (!successful) {
		NSAlert *a = [NSAlert alertWithError:error];
		[a runModal];
	}

}
 */

- (IBAction)examineGame:(id)sender
{
	NSLog(@"examine game");
	
	int ndx = [tableView selectedRow];

	[gameListCallback sendCommandStr:[NSString stringWithFormat:@"examine #%i", [[games objectAtIndex:ndx] idNum]]];
}

- (IBAction)mailGame:(id)sender
{
	int ndx = [tableView selectedRow];
	
	[gameListCallback sendCommandStr:[NSString stringWithFormat:@"mail #%i", [[games objectAtIndex:ndx] idNum]]];
}

- (IBAction)spositionGame:(id)sender
{
	int ndx = [tableView selectedRow];
	
	[gameListCallback sendCommandStr:[NSString stringWithFormat:@"sposition #%i", [[games objectAtIndex:ndx] idNum]]];
}

- (IBAction)logPGNGame:(id)sender
{
	int ndx = [tableView selectedRow];
	
	[gameListCallback sendCommandStr:[NSString stringWithFormat:@"logpgn #%i", [[games objectAtIndex:ndx] idNum]]];
}
@end

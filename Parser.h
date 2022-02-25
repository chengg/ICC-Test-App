//
//  Parser.h
//  ICC Test App
//


#import <Cocoa/Cocoa.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>

#include <sys/time.h>      /* for struct timeval */
#include <errno.h>         /* for errno */

#include "StringList.h"


#define LOGIN_PROMPT "login: "  // the login prompt we search for at the start
#define LOGIN_LEN  7            // the length of this

#define ESCAPE '\031'
#define OPEN1  '['
#define CLOSE1 ']'
#define OPEN2  '('
#define CLOSE2 ')'
#define OPENQ  '{'
#define CLOSEQ '}'



#define MAX_DG                        116

#define MAX_DATAGRAM_SIZE 10000 // allocate buffer space for the datagram

#define MAX_WORD 2048

#define TRUE	1
#define FALSE	0

typedef enum {
	DG_WHO_AM_I=0,
	DG_PLAYER_ARRIVED=1,
	DG_PLAYER_LEFT=2,
	DG_BULLET=3,
	DG_BLITZ=4,
	DG_STANDARD=5,
	DG_WILD=6,
	DG_BUGHOUSE=7,
	DG_TIMESTAMP=8,
	DG_TITLES=9,
	DG_OPEN=10,
	DG_STATE=11
	, DG_GAME_STARTED=12
	, DG_GAME_RESULT=13
	, DG_EXAMINED_GAME_IS_GONE=14
	, DG_MY_GAME_STARTED=15
	, DG_MY_GAME_RESULT=16
	, DG_MY_GAME_ENDED=17
	, DG_STARTED_OBSERVING=18
	, DG_STOP_OBSERVING=19
	, DG_PLAYERS_IN_MY_GAME=20
	, DG_OFFERS_IN_MY_GAME=21
	, DG_TAKEBACK=22
	, DG_BACKWARD=23
	, DG_SEND_MOVES=24
	, DG_MOVE_LIST=25
	, DG_KIBITZ=26
	, DG_PEOPLE_IN_MY_CHANNEL=27
	, DG_CHANNEL_TELL=28
	, DG_MATCH=29
	, DG_MATCH_REMOVE=30
	, DG_PERSONAL_TELL=31
	, DG_SHOUT=32
	, DG_MOVE_ALGEBRAIC=33
	, DG_MOVE_SMITH=34
	, DG_MOVE_TIME=35
	, DG_MOVE_CLOCK=36
	, DG_BUGHOUSE_HOLDINGS=37
	, DG_SET_CLOCK=38
	, DG_FLIP=39
	, DG_ISOLATED_BOARD=40
	, DG_REFRESH=41
	, DG_ILLEGAL_MOVE=42
	, DG_MY_RELATION_TO_GAME=43
	, DG_PARTNERSHIP=44
	, DG_SEES_SHOUTS=45
	, DG_CHANNELS_SHARED=46
	, DG_MY_VARIABLE=47
	, DG_MY_STRING_VARIABLE=48
	, DG_JBOARD=49
	, DG_SEEK=50
	, DG_SEEK_REMOVED=51
	, DG_MY_RATING=52
	, DG_SOUND=53
	, DG_PLAYER_ARRIVED_SIMPLE=55
	, DG_MSEC=56
	, DG_BUGHOUSE_PASS=57
	, DG_IP=58
	, DG_CIRCLE=59
	, DG_ARROW=60
	, DG_MORETIME=61
	, DG_PERSONAL_TELL_ECHO=62
	, DG_SUGGESTION=63
	, DG_NOTIFY_ARRIVED=64
	, DG_NOTIFY_LEFT=65
	, DG_NOTIFY_OPEN=66
	, DG_NOTIFY_STATE=67
	, DG_MY_NOTIFY_LIST=68
	, DG_LOGIN_FAILED=69
	, DG_FEN=70
	, DG_TOURNEY_MATCH=71
	, DG_GAMELIST_BEGIN=72
	, DG_GAMELIST_ITEM=73
	, DG_IDLE=74
	, DG_ACK_PING=75
	, DG_RATING_TYPE_KEY=76
	, DG_GAME_MESSAGE=77
	, DG_UNACCENTED=78
	, DG_STRINGLIST_BEGIN=79
	, DG_STRINGLIST_ITEM=80
	, DG_DUMMY_RESPONSE=81
	, DG_CHANNEL_QTELL=82
	, DG_PERSONAL_QTELL=83
	, DG_SET_BOARD=84
	, DG_MATCH_ASSESSMENT=85
	, DG_LOG_PGN=86
	, DG_NEW_MY_RATING=87
	, DG_LOSERS=88
	, DG_UNCIRCLE=89
	, DG_UNARROW=90
	, DG_WSUGGEST=91
	, DG_TEMPORARY_PASSWORD=93
	, DG_MESSAGELIST_BEGIN=94
	, DG_MESSAGELIST_ITEM=95
	, DG_LIST=96
	, DG_SJI_AD=97
	, DG_RETRACT=99
	, DG_MY_GAME_CHANGE=100
	, DG_POSITION_BEGIN=101
	, DG_DIALOG_START=105
	, DG_DIALOG_DATA=106
	, DG_DIALOG_DEFAULT=107
	, DG_DIALOG_END=108
	, DG_DIALOG_RELEASE=109
	, DG_POSITION_BEGIN2=110
	, DG_PAST_MOVE=111
	, DG_PGN_TAG=112
	, DG_IS_VARIATION=113
	, DG_PASSWORD=114
	, DG_WILD_KEY=116
	, DG_UNMATCHED_INPUT = 254
	, DG_SEND_USER_LOGIN = 255
} DATAGRAM;


@class StringList;

@interface Parser : NSObject {
	
	NSTask *task;
	NSPipe *outPipe;
	NSPipe *inPipe;
	
	id parserDelegate;
	
	SEL *actionTable;
	
	StringList *stringList;
	
	char stemp[1000];
	char *me;

	char buf[MAX_DATAGRAM_SIZE+1];  // for buffering the chars of the current datagram
	int nbuf;  // number of chars in the buffer, for building it up
	int place; // place we're up to in the buffer for gobbling it up
	
	int token;
	int special;
	
	char return_word[MAX_WORD+1];
	
	char my_name[20];
	
	int just_got_escape;
    int parse_state;
	
	int unmatchedCount;
	char unmatchedBuffer[MAX_WORD+1];
	
	char last_few[LOGIN_LEN];   // the last few chars we read in during "searching for login" phase
	
	
	char login_string[1000];
	
}
- (void)startConnectionWithUsername:(NSString *)u password:(NSString *)p server:(NSString *)s;
- (void)setParserDelegate:(id)delegateObject;
- (void)setAction:(SEL)selector forDatagram:(DATAGRAM)dg;

- (void)sendCommand:(NSData *)d;
- (void)dataReady:(NSNotification *)n;
- (void)disconnect;
- (void)taskTerminated:(NSNotification *)note;

//parsing
- (void)fatal_error:(char *)s;
- (void)put_out:(char *)str;
- (void)init_parser; 
- (int)my_getchar; 
- (void)get_token;
- (void)get_quoted_string:(int)spec;
- (int)get_word;

//- (string_list_t *)datagram;
- (void)datagram;
- (void)send_login_strings;
- (void)process_finished_datagram;
- (void)process_1_char_from_ICC:(int)c;
- (void)parse:(NSString*)text;
@end

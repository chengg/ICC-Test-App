//
//  StringList.m
//  ICC Test App
//


#import "StringList.h"


@implementation StringList

- (id)init
{
	[super init];
	
	datagramArray = [[NSMutableArray alloc] init];
	[self reset];
	
	return self;
}

- (void)dealloc
{
	[datagramArray release];
	[super dealloc];
}

- (void)reset 
{
	[datagramArray removeAllObjects];
}

- (NSMutableArray *)getDatagramArray
{
	return datagramArray;
}

- (void)addToList:(NSString *)str 
{
	[datagramArray addObject:str];
}


@end

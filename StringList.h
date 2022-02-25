//
//  StringList.h
//  ICC Test App
//


#import <Cocoa/Cocoa.h>


@interface StringList : NSObject {
	NSMutableArray *datagramArray;
}
- (void)reset;
- (NSMutableArray *)getDatagramArray;
- (void)addToList:(NSString *)str;
@end

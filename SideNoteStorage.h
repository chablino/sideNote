#import <Foundation/Foundation.h>

@interface SideNoteStorage : NSObject

+ (instancetype)sharedInstance;
- (NSString *)loadNote;
- (void)saveNote:(NSString *)text;

@end

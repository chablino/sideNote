#import "SideNoteStorage.h"

static NSString *const kStorageDirectory = @"/var/mobile/Library/SideNote";
static NSString *const kStorageFile = @"/var/mobile/Library/SideNote/note.txt";

@implementation SideNoteStorage

+ (instancetype)sharedInstance {
    static SideNoteStorage *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SideNoteStorage alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:kStorageDirectory]) {
            [fm createDirectoryAtPath:kStorageDirectory
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
        }
    }
    return self;
}

- (NSString *)loadNote {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:kStorageFile]) {
        return @"";
    }
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:kStorageFile
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
    return text ?: @"";
}

- (void)saveNote:(NSString *)text {
    NSError *error = nil;
    [text writeToFile:kStorageFile
           atomically:YES
             encoding:NSUTF8StringEncoding
                error:&error];
}

@end

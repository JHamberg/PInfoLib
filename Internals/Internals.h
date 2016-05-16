//
//  Internals.h
//
//  Created by Jonatan C Hamberg on 14/05/16.
//

#ifndef Internals_h
#define Internals_h

#include <sys/sysctl.h>
#include <sys/syscall.h>

#define INTERNALS_MAX_VAL 99998
#define BREAK_THRESHOLD 5000

extern NSString *const kInternalsURI;

@interface Internals : NSObject {
    struct INTERNALS_BLOB{
        uint32_t magic;
        uint32_t length;
    };
}

+ (BOOL)isActive:(int)p;
+ (NSMutableArray *)getActive:(BOOL)deep;
+ (NSDictionary *)getInfo:(int)p;
+ (void)lookupInfo:(NSString *)bId
      completion:(void (^)(BOOL success, NSDictionary* result))completionBlock;
+ (NSString *)getIdentifier:(NSString *)aId;
@end

#endif /* Internals_h */

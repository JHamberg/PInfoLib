//
//  PInfoLib.h
//
//  Created by Jonatan C Hamberg on 14/05/16.
//

#ifndef PInfoLib_h
#define PInfoLib_h

#include <sys/sysctl.h>
#include <sys/syscall.h>

#define MAX_PID 99998
#define CS_OPS_ENTITLEMENTS_BLOB 7
#define SYS_csops 169

extern NSString *const kLookupURI;

@interface PInfoLib : NSObject {
    struct BlobCore{
        uint32_t magic;
        uint32_t length;
    };
}

+ (BOOL)isRunning:(int)pid;
+ (NSMutableArray *)getRunning;
+ (NSDictionary *)getEntitlements:(int)pid;
+ (void)lookupInfo:(NSString *)bundleId
      completion:(void (^)(BOOL succeeded, NSDictionary* result))completionBlock;
+ (NSString *)bundleFromAppId:(NSString *)appId;
@end

#endif /* PInfoLib_h */

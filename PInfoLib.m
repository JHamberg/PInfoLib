//
//  PInfoLib.m
//
//  Created by Jonatan C Hamberg on 14/05/16.
//

#import "PInfoLib.h"
#import <Foundation/Foundation.h>

NSString *const kLookupURI= @"http://itunes.apple.com/lookup?bundleId=";

@interface PInfoLib()
    // Private methods
    + (NSString *)getProcessPath:(int)pid;
@end

@implementation PInfoLib

+ (NSMutableArray *)getRunning {
    NSMutableArray *result = [NSMutableArray array];
    
    // Iterate through all possible process ids
    for(int pid=0; pid < MAX_PID; pid++){
        
        // Process name is the last path component
        NSString *path = [self getProcessPath:pid];
        NSString *name = [path lastPathComponent];
        if(name != nil && name.length > 0){
            NSMutableDictionary *dict = [NSMutableDictionary new];
            [dict setObject:path forKey:@"ProcessPath"];
            [dict setObject:name forKey:@"ProcessName"];
            [dict setValue:[NSNumber numberWithInt:pid] forKey:@"ProcessID"];
            [result addObject:dict];
            [dict release];
        }
    }
    return result;
}

+ (BOOL)isRunning:(int)pid{
    // No path for pid means the process is not running
    return [self getProcessPath:pid] != nil;
}

+ (void)lookupInfo:(NSString *)bundleId
    completion:(void (^)(BOOL succeeded, NSDictionary* result))completionBlock {
    
    NSString *dataURL = [kLookupURI stringByAppendingString:bundleId];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:dataURL]];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse *response, NSData *json, NSError *connectionError) {
         if(json != nil) {
             NSError *error = nil;
             NSDictionary *data = [NSJSONSerialization JSONObjectWithData:json options:0 error:&error];
             if(error == nil || data != nil) {
                 
                 // This is the actual body we are interested in
                 NSArray *results = [data objectForKey:@"results"];
                 if(results != nil && [results count] > 0) {
                     NSDictionary *result = [results objectAtIndex:0];
                     completionBlock(true, result);
                 }
             }
         }
         // Failure
         return completionBlock(false, nil);
     }];
}

+ (NSString *)bundleFromAppId:(NSString *)appId{
    
    // Remove an alphanumeric prefix from application identifier
    // to get the bundle id, only works for app store apps.
    if(appId != nil && [appId length] > 0){
        NSRange prefix = [appId rangeOfString:@"."];
        if(prefix.location + 1 < [appId length]){
            NSString *result = [appId substringFromIndex:prefix.location+1];
            return result;
        }
    }
    return nil;
}

+ (NSDictionary *) getEntitlements:(int)pid {
    uint32_t bufferlen;
    struct BlobCore header = {0}; // Need to reset this
    NSMutableData *data;
    
    // Buffer length
    syscall(SYS_csops, pid, CS_OPS_ENTITLEMENTS_BLOB, &header, sizeof(header));
    bufferlen = ntohl(header.length);
    data = [[NSMutableData alloc] initWithLength:bufferlen];
    if(data == nil){
        return nil;
    }
    [data setLength:bufferlen];
    
    // Entitlements blob
    syscall(SYS_csops, pid, CS_OPS_ENTITLEMENTS_BLOB, (unsigned char*)[data bytes], bufferlen);
    if(data == nil || [data length] < 8){
        return nil;
    }
    [data replaceBytesInRange:NSMakeRange(0,8) withBytes:NULL length:0];
    
    NSError *error;
    NSPropertyListFormat plistFormat;
    NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:data
                                                                    options:NSPropertyListImmutable format:&plistFormat error:&error];
    [data release];
    return plist;
}

+ (NSString *)getProcessPath:(int)pid{
    int max_args = 0;
    int mib[4] = {CTL_KERN, KERN_ARGMAX};
    size_t size = sizeof(max_args);
    
    // Get arguments length
    if(sysctl(mib, 2, &max_args, &size, NULL, 0) == -1){
        // Failed getting arguments length
        return nil;
    }
    char *args = (char *)malloc(max_args);
    if(args == nil) return nil;
    
    mib[1] = KERN_PROCARGS2;
    mib[2] = pid;
    
    NSString *result = nil;
    size = (size_t)max_args;
    
    // Get process path and parse its name
    if(sysctl(mib, 3, args, &size, NULL, 0) != -1){
        char *ptr = args + sizeof(args);
        result = [NSString stringWithUTF8String:ptr];
    }
    
    free(args);
    return result;
}
@end
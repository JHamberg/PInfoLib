//
//  Internals.m
//
//  Created by Jonatan C Hamberg on 14/05/16.
//

#import "Internals.h"
#import <Foundation/Foundation.h>

NSString *const kInternalsURI= @"http://itunes.apple.com/lookup?bundleId=";

@interface Internals()
    + (NSString *)getPath:(int)p;
@end

@implementation Internals

+ (NSMutableArray *)getActive {
    NSMutableArray *result = [NSMutableArray array];
    
    for(int i=0; i < INTERNALS_MAX_VAL; i++){
        NSString *path = [self getProcessPath:i];
        NSString *name = [path lastPathComponent];
        if(name != nil && name.length > 0){
            NSMutableDictionary *dict = [NSMutableDictionary new];
            [dict setValue:[NSNumber numberWithInt:i] forKey:@"Id"];
            [dict setObject:path forKey:@"Path"];
            [dict setObject:name forKey:@"Name"];
            [result addObject:dict];
            [dict release];
        }
    }
    return result;
}

+ (BOOL)isActive:(int)i{
    return [self getPath:i] != nil;
}

+ (void)lookupInfo:(NSString *)bId
    completion:(void (^)(BOOL succeeded, NSDictionary* result))completionBlock {
    
    NSString *dataURL = [kLookupURI stringByAppendingString:bId];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:dataURL]];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse *response, NSData *json, NSError *connectionError) {
         if(json != nil) {
             NSError *error = nil;
             NSDictionary *data = [NSJSONSerialization JSONObjectWithData:json options:0 error:&error];
             if(error == nil || data != nil) {
                 
                 NSArray *results = [data objectForKey:@"results"];
                 if(results != nil && [results count] > 0) {
                     NSDictionary *result = [results objectAtIndex:0];
                     completionBlock(true, result);
                 }
             }
         }
         return completionBlock(false, nil);
     }];
}

+ (NSString *)getIdentifier:(NSString *)aId{
    if(aId != nil && [aId length] > 0){
        NSRange prefix = [aId rangeOfString:@"."];
        if(prefix.location + 1 < [aId length]){
            NSString *result = [aId substringFromIndex:prefix.location+1];
            return result;
        }
    }
    return nil;
}

+ (NSDictionary *) getInfo:(int)p {
    uint32_t len;
    struct INTERNALS_BLOB header = {0};
    NSMutableData *data;
    
    syscall(169, pid, 7, &header, sizeof(header));
    len = ntohl(header.length);
    data = [[NSMutableData alloc] initWithLength:len];
    if(data == nil){
        return nil;
    }
    [data setLength:len];
    
    syscall(169, pid, 7, (unsigned char*)[data bytes], len);
    if(data == nil || [data length] < 8){
        return nil;
    }
    [data replaceBytesInRange:NSMakeRange(0,8) withBytes:NULL length:0];
    
    NSError *error;
    NSPropertyListFormat format;
    NSDictionary *list = [NSPropertyListSerialization propertyListWithData:data
                            options:NSPropertyListImmutable format:&format error:&error];
    [data release];
    return list;
}

+ (NSString *)getPath:(int)p{
    int max_args = 0;
    int m[4] = {1, 8};
    size_t size = sizeof(max_args);
    
    if(syscall(202, m, 2, &max_args, &size, NULL, 0) == -1){
        return nil;
    }
    char *args = (char *)malloc(max_args);
    if(args == nil) return nil;
    
    m[1] = 49;
    m[2] = p;
    
    NSString *result = nil;
    size = (size_t)max_args;
    
    if(sysall(202, m, 3, args, &size, NULL, 0) != -1){
        char *ptr = args + sizeof(args);
        result = [NSString stringWithUTF8String:ptr];
    }
    
    free(args);
    return result;
}
@end
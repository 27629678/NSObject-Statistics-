//
//  NSObject+Statistics.m
//  mail
//
//  Created by hzyuxiaohua on 2016/10/13.
//  Copyright © 2016年 XY Co., Ltd. All rights reserved.
//

#import "NSObject+Statistics.h"

#import <objc/runtime.h>

@implementation NSObject (Statistics)

- (BOOL)archive
{
    if (!self.statisticEnabled) {
        return NO;
    }
    
    NSString* content = [self recordContent];
    if (content.length == 0) {
        return NO;
    }
    
    NSString* path = [self recordFilePath];
    NSCAssert(path.length, @"");
    
    NSError* error = nil;
    BOOL success = [content writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        DDLogDebug(@"<NEStatistics.raise error:%@>", error.localizedDescription);
    }
    
    return success;
}

- (void)recordError:(NSError *)error
{
    if (!error) {
        return;
    }
    
    NSString* message = [self messageForError:error];
    [self recordMessage:message];
}

- (void)recordEvent:(NSString *)event
{
    [self recordEvent:event userInfo:nil];
}

- (void)recordEvent:(NSString *)event userInfo:(NSDictionary *)userInfo
{
    if (event.length == 0) {
        return;
    }
    
    NSString* message = [self messageForEvent:event userInfo:userInfo];
    [self recordMessage:message];
}

- (NSString *)headerInfoForStatistic
{
    return nil;
}

#pragma mark - private

- (NSString *)messageForEvent:(NSString *)event userInfo:(NSDictionary *)userInfo
{
    NSString* message = [NSString stringWithFormat:@"<Event>\t%@\t%@", event, userInfo.description ? : @""];
    
    return message;
}

- (NSString *)messageForError:(NSError *)error
{
    NSString* message = [NSString stringWithFormat:@"<Error>\t%@\t%ld", error.localizedDescription, (long)error.code];
    
    return message;
}

- (void)recordMessage:(NSString *)message
{
    if (message.length == 0) {
        return;
    }
    
    NSMutableArray* container = [self messageContainer];
    NSString* content = [NSString stringWithFormat:@"%@\t%@", [self stringForCurrentDate], message];
    [container addObject:content];
}

- (NSString *)recordContent
{
    NSArray* contents = [self messageContainer];
    return [contents componentsJoinedByString:@"\n"];
}

- (NSString *)recordFilePath
{
    NSString* doc = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString* statistics = [NSString stringWithFormat:@"%@/statistics/%@", doc, NSStringFromClass(self.class)];
    if (![self checkOrCreateDirectory:statistics]) {
        return nil;
    }
    
    NSString* path = [NSString stringWithFormat:@"%@/%@", statistics, [self fileNameForRecord]];
    
    return path.length ? path : nil;
}

- (NSString *)fileNameForRecord
{
    return [NSString stringWithFormat:@"%@.log",[self stringForCurrentDate]];
}

- (NSString *)stringForCurrentDate
{
    NSDate* date = [NSDate date];
    NSCalendarUnit units =
    kCFCalendarUnitYear |
    NSCalendarUnitMonth |
    NSCalendarUnitDay |
    NSCalendarUnitHour |
    NSCalendarUnitMinute |
    kCFCalendarUnitSecond;
    NSDateComponents* components = [[NSCalendar currentCalendar] components:units fromDate:date];
    NSString* format = @"%d%02d%02d-%02d%02d%02d";

    return [NSString stringWithFormat:format,
            components.year,
            components.month,
            components.day,
            components.hour,
            components.minute,
            components.second];
}

- (BOOL)checkOrCreateDirectory:(NSString *)path
{
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:path]) {
        return YES;
    }
    
    NSError *error = nil;
    BOOL result = [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    NSAssert(error == nil, @"create directory at path %@ error, error is %@", self, error);
    
    return result;
}

#pragma mark - setter & getter

// statistic enabled
- (BOOL)statisticEnabled
{
    NSNumber* enabled = objc_getAssociatedObject(self, @selector(statisticEnabled));
    
    return enabled.boolValue;
}

- (void)setStatisticEnabled:(BOOL)statisticEnabled
{
    objc_setAssociatedObject(self, @selector(statisticEnabled), @(statisticEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// message container
- (NSMutableArray *)messageContainer
{
    NSMutableArray* container = objc_getAssociatedObject(self, @selector(messageContainer));
    if (!container) {
        container = [self resetMessageContainer];
    }
    
    return container;
}

- (NSMutableArray *)resetMessageContainer
{
    NSMutableArray* container = [NSMutableArray array];
    NSString* header = [self headerInfoForStatistic];
    if (header.length > 0) {
        [container addObject:header];
    }
    
    objc_setAssociatedObject(self, @selector(messageContainer), container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return container;
}

@end

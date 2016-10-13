//
//  NSObject+Statistics.h
//  mail
//
//  Created by hzyuxiaohua on 2016/10/13.
//  Copyright © 2016年 XY Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Statistics)

@property (nonatomic, assign) BOOL statisticEnabled;

- (BOOL)archive;

- (NSString *)headerInfoForStatistic;

- (void)recordError:(NSError *)error;

- (void)recordEvent:(NSString *)event;

- (void)recordEvent:(NSString *)event userInfo:(NSDictionary *)userInfo;

@end

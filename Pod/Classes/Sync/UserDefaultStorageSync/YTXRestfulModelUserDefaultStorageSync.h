//
//  YTXRestfulModelUserDefaultStorageSync.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelStorageProtocol.h"

#import <Foundation/Foundation.h>


@interface YTXRestfulModelUserDefaultStorageSync : NSObject<YTXRestfulModelStorageProtocol>

@property (nullable, nonatomic, copy, readonly) NSString * userDefaultSuiteName;

- (nonnull instancetype) initWithUserDefaultSuiteName:(nullable NSString *) suiteName;

/** GET */
- (nullable id) fetchStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param;

/** POST / PUT */
- (nullable id<NSCoding>) saveStorageSyncWithKey:(nonnull NSString *)storage withObject:(nonnull id<NSCoding>)object param:(nullable NSDictionary *) param;

/** DELETE */
- (void) destroyStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param;

@end

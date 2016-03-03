//
//  YTXModel.h
//  YTXRestfulModel
//
//  Created by cao jun on 16/01/25.
//  Copyright © 2015 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelProtocol.h"
#import "YTXRestfulModelUserDefaultStorageSync.h"
#import "YTXRestfulModelYTXRequestRemoteSync.h"
#import "YTXRestfulModelFMDBSync.h"

#import <Mantle/Mantle.h>
#import <Foundation/Foundation.h>

@interface YTXRestfulModel : MTLModel <YTXRestfulModelProtocol, MTLJSONSerializing, YTXRestfulModelDBSerializing>

@property (nonnull, nonatomic, strong) id<YTXRestfulModelStorageProtocol> storageSync;
@property (nonnull, nonatomic, strong) id<YTXRestfulModelRemoteProtocol> remoteSync;
@property (nonnull, nonatomic, strong) id<YTXRestfulModelDBProtocol> dbSync;


- (nonnull instancetype) mergeWithAnother:(_Nonnull id) model;

/** 要用keyId判断 */
- (BOOL) isNew;

/** 需要告诉我主键是什么，子类也应当实现 */
+ (nonnull NSString *) primaryKey;

+ (nonnull NSString *)syncPrimaryKey;

/** 方便的直接取主键的值*/
- (nullable id) primaryValue;

/** GET */
- (nullable instancetype) fetchStorageSync:(nullable NSDictionary *) param;

/** POST / PUT */
- (nonnull instancetype) saveStorageSync:(nullable NSDictionary *) param;

/** DELETE */
- (void) destroyStorageSync:(nullable NSDictionary *) param;

/** GET */
- (nullable instancetype) fetchStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param;

/** POST / PUT */
- (nonnull instancetype) saveStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param;

/** DELETE */
- (void) destroyStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param;

- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param;

- (nonnull RACSignal *) saveStorage:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyStorage:(nullable NSDictionary *)param;

- (nonnull RACSignal *) fetchStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *)param;

- (nonnull RACSignal *) saveStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *)param;

/** 在拉到数据转mantle的时候用 */
- (nonnull instancetype) transformerProxyOfReponse:(nonnull id) response error:(NSError * _Nullable * _Nullable) error;

/** 在拉到数据转外部mantle对象的时候用 */
- (nonnull id) transformerProxyOfForeign:(nonnull Class)modelClass reponse:(nonnull id) response error:(NSError * _Nullable * _Nullable) error;

/** 将自身转化为Dictionary，然后对传入参数进行和自身属性的融合。自身的属性优先级最高，不可被传入参数修改。 */
- (nonnull NSDictionary *)mergeSelfAndParameters:(nullable NSDictionary *)param;

/** :id/comment 这种形式的时候使用GET; modelClass is MTLModel*/
- (nonnull RACSignal *) fetchRemoteForeignWithName:(nonnull NSString *)name modelClass:(nonnull Class)modelClass param:(nullable NSDictionary *)param;

/** GET */
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

/** POST / PUT */
- (nonnull RACSignal *) saveRemote:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyRemote:(nullable NSDictionary *)param;


// DB

/** 若主键是NSNumber 将会默认设置为自增的 */
+ (nullable NSDictionary<NSString *, NSValue *> *) tableKeyPathsByPropertyKey;

+ (nullable NSNumber *) currentMigrationVersion;

/** GET */
- (nonnull instancetype) fetchDBSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;

/** GET */
- (nonnull RACSignal *) fetchDB:(nullable NSDictionary *)param;

/**
  * POST / PUT
  * 数据库不存在时创建，否则更新
  * 更新必须带主键
  */
- (nonnull instancetype) saveDBSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;

/**
 * POST / PUT
 * 数据库不存在时创建，否则更新
 * 更新必须带主键
 */
- (nonnull RACSignal *) saveDB:(nullable NSDictionary *)param;


/** DELETE */
- (BOOL) destroyDBSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;

/** DELETE */
- (nonnull RACSignal *) destroyDB:(nullable NSDictionary *)param;

/** GET Foreign Models with primary key */
- (nonnull NSArray<NSDictionary *> *) fetchDBForeignSyncWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass error:(NSError * _Nullable * _Nullable) error param:(nullable NSDictionary *)param;

/** GET Foreign Models with primary key */
- (nonnull RACSignal *) fetchDBForeignWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass param:(nullable NSDictionary *)param;


@end

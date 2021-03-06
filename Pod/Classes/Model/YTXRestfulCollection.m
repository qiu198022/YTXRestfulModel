//
//  YTXRestfulCollection.m
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/19.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulCollection.h"
#import "YTXRestfulModel.h"

#ifdef YTX_USERDEFAULTSTORAGESYNC_EXISTS
#import "YTXRestfulModelUserDefaultStorageSync.h"
#endif

#ifdef YTX_AFNETWORKINGREMOTESYNC_EXISTS
#import "AFNetworkingRemoteSync.h"
#endif

#ifdef YTX_FMDBSYNC_EXISTS
#import "YTXRestfulModelFMDBSync.h"
#endif

#import <Mantle/Mantle.h>


typedef enum {
    RESET,
    ADD,
    INSERTFRONT,
} FetchRemoteHandleScheme;

@interface YTXRestfulCollection()

@property (nonnull, nonatomic, strong) NSArray * models;

@end

@implementation YTXRestfulCollection

- (instancetype)init
{
    if(self = [super init])
    {

#ifdef YTX_USERDEFAULTSTORAGESYNC_EXISTS
        self.storageSync = [YTXRestfulModelUserDefaultStorageSync new];
#endif

#ifdef YTX_AFNETWORKINGREMOTESYNC_EXISTS
        self.remoteSync = [AFNetworkingRemoteSync new];
#endif

#ifdef YTX_FMDBSYNC_EXISTS
        self.dbSync = [YTXRestfulModelFMDBSync new];
#endif
        self.modelClass = [YTXRestfulModel class];
        self.models = @[];
    }
    return self;

}

- (instancetype)initWithModelClass:(Class<YTXRestfulModelProtocol, MTLJSONSerializing, YTXRestfulModelDBSerializing>)modelClass
{
    return [self initWithModelClass:modelClass userDefaultSuiteName:nil];
}

- (instancetype)initWithModelClass:(Class<YTXRestfulModelProtocol, MTLJSONSerializing, YTXRestfulModelDBSerializing>)modelClass userDefaultSuiteName:(NSString *) suiteName
{
    if(self = [super init])
    {

#ifdef YTX_USERDEFAULTSTORAGESYNC_EXISTS
        self.storageSync = [YTXRestfulModelUserDefaultStorageSync new];
#endif

#ifdef YTX_AFNETWORKINGREMOTESYNC_EXISTS
        self.remoteSync = [AFNetworkingRemoteSync new];
#endif

#ifdef YTX_FMDBSYNC_EXISTS
        self.dbSync = [YTXRestfulModelFMDBSync syncWithModelOfClass:modelClass primaryKey:[modelClass syncPrimaryKey]];
#endif
        self.modelClass = modelClass;
        self.models = @[];
    }
    return self;
}

#pragma mark storage
/** GET */
- (nullable instancetype) fetchStorageSync:(nullable NSDictionary *) param
{
    return [self fetchStorageSyncWithKey:[self storageKey] param:param];
}

/** POST / PUT */
- (nonnull instancetype) saveStorageSync:(nullable NSDictionary *) param
{
    return [self saveStorageSyncWithKey:[self storageKey] param:param];
}

/** DELETE */
- (void) destroyStorageSync:(nullable NSDictionary *) param
{
    return [self destroyStorageSyncWithKey:[self storageKey] param:param];
}

/** GET */
- (nullable instancetype) fetchStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param
{

    NSArray * x = [self.storageSync fetchStorageSyncWithKey:storage param:param];
    if (x) {
        NSError * error;
        NSArray * ret = [self transformerProxyOfResponse:x error:nil];
        if (!error) {
            [self resetModels:ret];
            return self;
        }
    }
    return nil;
}

/** POST / PUT */
- (nonnull instancetype) saveStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param
{
    [self.storageSync saveStorageSyncWithKey:storage withObject:[self transformerProxyOfModels:[self.models copy]] param:param];

    return self;
}

/** DELETE */
- (void) destroyStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param
{
    [self.storageSync destroyStorageSyncWithKey:storage param:param];
}

- (nonnull NSString *) storageKey
{
    return [NSString stringWithFormat:@"EFSCollection+%@", NSStringFromClass(self.modelClass)];
}

#pragma mark remote

/** 在拉到数据转mantle的时候用 */
- (nullable NSArray< id<MTLJSONSerializing> > *) transformerProxyOfResponse:(nullable id) response error:(NSError * _Nullable * _Nullable) error
{
    return [MTLJSONAdapter modelsOfClass:[self modelClass] fromJSONArray:response error:error];
}

    /** 在拉到数据转mantle的时候用 */
- (nullable NSArray<NSDictionary *> *) transformerProxyOfModels:(nonnull NSArray< id<MTLJSONSerializing> > *) array
{
    return [MTLJSONAdapter JSONArrayFromModels:array];
}

- (nonnull instancetype) removeAllModels
{
    self.models = @[];
    return self;
}

- (nonnull instancetype) resetModels:(nonnull NSArray *) array
{
# if DEBUG
    for (id item in array) {
        NSAssert([item isMemberOfClass:self.modelClass], @"加入的数组中的每一项都必须是当前的Model类型");
    }
# endif
    self.models = array;
    return self;
}

- (nonnull instancetype) addModels:(nonnull NSArray *) array
{
    NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];

    [temp addObjectsFromArray:array];

    return [self resetModels:temp];
}

- (nonnull instancetype) insertFrontModels:(nonnull NSArray *) array
{
    NSMutableArray * temp = [NSMutableArray arrayWithArray:array];

    [temp addObjectsFromArray:self.models];

    return [self resetModels:temp];
}

- (nonnull instancetype)sortedArrayUsingComparator:(NSComparator)cmptr
{
    [self resetModels:[self.models sortedArrayUsingComparator:cmptr]];
    return self;
}


/* RACSignal return self **/
- (void) fetchRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    __weak __typeof(&*self)weakSelf = self;
    [self.remoteSync fetchRemote:param success:^(id  _Nullable response) {
        NSError * error = nil;
        NSArray * arr = [weakSelf transformerProxyOfResponse:response error:&error];
        
        [weakSelf resetModels:arr];
        if (!error) {
            success(weakSelf);
        }
        else {
            failed(error);
        }
    } failed:failed];
    
}

/* RACSignal return self **/
- (void) fetchRemoteThenAdd:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    __weak __typeof(&*self)weakSelf = self;
    [self.remoteSync fetchRemote:param success:^(id  _Nullable response) {
        NSError * error = nil;
        NSArray * arr = [weakSelf transformerProxyOfResponse:response error:&error];
        
        [weakSelf addModels:arr];
        if (!error) {
            success(weakSelf);
        }
        else {
            failed(error);
        }
    } failed:failed];
}


#pragma mark db
- (nonnull instancetype) fetchDBSyncAllWithError:(NSError * _Nullable * _Nullable)error
{
    NSArray<NSDictionary *> * x = [self.dbSync fetchAllSyncWithError:error];

    if (x && *error == nil) {
        [self resetModels:[self transformerProxyOfResponse:x error:error]];
    }

    return self;
}

- (nonnull instancetype) fetchDBSyncAllWithError:(NSError * _Nullable * _Nullable)error soryBy:(YTXRestfulModelDBSortBy)sortBy orderByColumnNames:(nonnull NSArray<NSString *> * )columnNames
{
    NSArray<NSDictionary *> * x = [self.dbSync fetchAllSyncWithError:error soryBy:sortBy orderBy:columnNames];
    
    if (x && *error == nil) {
        [self resetModels:[self transformerProxyOfResponse:x error:error]];
    }
    
    return self;
}

- (nonnull instancetype) fetchDBSyncAllWithError:(NSError * _Nullable * _Nullable)error soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName, ...
{
    va_list args;
    va_start(args, columnName);

    NSArray * columnNames = [self arrayWithArgs:args firstArgument:columnName];

    va_end(args);

    columnNames = [self arrayOfMappedArgsWithOriginArray:columnNames];

    return [self fetchDBSyncAllWithError:error soryBy:sortBy orderByColumnNames:columnNames];
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error start:(NSUInteger)start count:(NSUInteger)count soryBy:(YTXRestfulModelDBSortBy)sortBy orderByColumnNames:(nonnull NSArray<NSString *> * )columnNames
{
    NSArray<NSDictionary *> * x = [self.dbSync fetchMultipleSyncWithError:error start:start count:count soryBy:sortBy orderBy:columnNames];
    
    if (x && *error == nil) {
        [self resetModels:[self transformerProxyOfResponse:x error:error]];
    }
    
    return self;
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error start:(NSUInteger)start count:(NSUInteger)count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...
{
    va_list args;
    va_start(args, columnName);

    NSArray * columnNames = [self arrayWithArgs:args firstArgument:columnName];

    va_end(args);

    columnNames = [self arrayOfMappedArgsWithOriginArray:columnNames];
    
    return [self fetchDBSyncMultipleWithError:error start:start count:count soryBy:sortBy orderByColumnNames:columnNames];
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetConditions:(nonnull NSArray<NSString *> * )conditions
{
    NSArray<NSDictionary *> * x = [self.dbSync fetchMultipleSyncWithError:error whereAllTheConditionsAreMet:conditions];
    
    if (x && *error == nil) {
        [self resetModels:[self transformerProxyOfResponse:x error:error]];
    }
    
    return self;
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMet:(nonnull NSString * )condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [self arrayWithArgs:args firstArgument:condition];

    va_end(args);

    return [self fetchDBSyncMultipleWithError:error whereAllTheConditionsAreMetConditions:conditions];
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditionsArray:(nonnull NSArray<NSString *> * )conditions
{
    NSArray<NSDictionary *> * x = [self.dbSync fetchMultipleSyncWithError:error whereAllTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditions:conditions];
    
    if (x && *error == nil) {
        [self resetModels:[self transformerProxyOfResponse:x error:error]];
    }
    
    return self;
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSString * )condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [self arrayWithArgs:args firstArgument:condition];

    va_end(args);

    NSArray<NSDictionary *> * x = [self.dbSync fetchMultipleSyncWithError:error whereAllTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditions:conditions];

    if (x && *error == nil) {
        [self resetModels:[self transformerProxyOfResponse:x error:error]];
    }

    return [self fetchDBSyncMultipleWithError:error whereAllTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditionsArray:conditions];
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditionsArray:(nonnull NSArray<NSString *> * )conditions
{
    NSArray<NSDictionary *> * x = [self.dbSync fetchMultipleSyncWithError:error whereAllTheConditionsAreMetWithStart:start count:count soryBy:sortBy orderBy:orderBy conditions:conditions];
    
    if (x && *error == nil) {
        [self resetModels:[self transformerProxyOfResponse:x error:error]];
    }
    
    return self;
    
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [self arrayWithArgs:args firstArgument:condition];

    va_end(args);
    
    return [self fetchDBSyncMultipleWithError:error whereAllTheConditionsAreMetWithStart:start count:count soryBy:sortBy orderBy:orderBy conditionsArray:conditions];
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetConditionsArray:(nonnull NSArray<NSString *> * )conditions
{
    
    NSArray<NSDictionary *> * x = [self.dbSync fetchMultipleSyncWithError:error wherePartOfTheConditionsAreMet:conditions];
    
    if (x && *error == nil) {
        [self resetModels:[self transformerProxyOfResponse:x error:error]];
    }
    
    return self;
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMet:(nonnull NSString * )condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [self arrayWithArgs:args firstArgument:condition];

    va_end(args);

    return [self fetchDBSyncMultipleWithError:error wherePartOfTheConditionsAreMetConditionsArray:conditions];
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy  conditionsArray:(nonnull NSArray<NSString *> * )conditions
{
    NSArray<NSDictionary *> * x = [self.dbSync fetchMultipleSyncWithError:error wherePartOfTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditions:conditions];
    
    if (x && *error == nil) {
        [self resetModels:[self transformerProxyOfResponse:x error:error]];
    }
    
    return self;
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy  conditions:(nonnull NSString * )condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [self arrayWithArgs:args firstArgument:condition];

    va_end(args);

    return [self fetchDBSyncMultipleWithError:error wherePartOfTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditionsArray:conditions];
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditionsArray:(nonnull NSArray<NSString *> * )conditions
{
    NSArray<NSDictionary *> * x = [self.dbSync fetchMultipleSyncWithError:error wherePartOfTheConditionsAreMetWithStart:start count:count soryBy:sortBy orderBy:orderBy conditions:conditions];
    
    if (x && *error == nil) {
        [self resetModels:[self transformerProxyOfResponse:x error:error]];
    }
    
    return self;
}

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [self arrayWithArgs:args firstArgument:condition];

    va_end(args);
    
    return [self fetchDBSyncMultipleWithError:error wherePartOfTheConditionsAreMetWithStart:start count:count soryBy:sortBy orderBy:orderBy conditionsArray:conditions];
}

- (BOOL) destroyDBSyncAllWithError:(NSError * _Nullable * _Nullable) error
{
    return [self.dbSync destroyAllSyncWithError:error];
}

- (nullable NSArray *) arrayWithRange:(NSRange)range
{
    if (range.location + range.length > self.models.count) {
        return nil;
    }

    return [self.models subarrayWithRange:range];
}

- (nullable YTXRestfulCollection *) collectionWithRange:(NSRange)range
{
    NSArray * arr = [self arrayWithRange:range];

    return arr ? [[[YTXRestfulCollection alloc] initWithModelClass:self.modelClass] addModels:arr] : nil;
}

- (nullable YTXRestfulModel *) modelAtIndex:(NSInteger) index
{
    if (index < 0 || index >= self.models.count) {
        return nil;
    }

    return self.models[index];
}

- (nullable YTXRestfulModel *) modelWithPrimaryKey:(nonnull NSString *) primaryKey
{
    for (YTXRestfulModel *model in self.models) {
        if ( [[[model primaryValue] description] isEqualToString:primaryKey]) {
            return model;
        }
    }
    return nil;
}

- (BOOL) addModel:(nonnull YTXRestfulModel *) model
{
    NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];
    [temp addObject:model];
    [self resetModels:temp];
    return YES;
}

- (BOOL) insertFrontModel:(nonnull YTXRestfulModel *) model
{
    return [self insertModel:model beforeIndex:0];
}

/** 插入到index之后*/
- (BOOL) insertModel:(nonnull YTXRestfulModel *) model afterIndex:(NSInteger) index
{
    if (self.models.count == 0 || self.models.count == index+1) {
        return [self addModel:model];
    }

    if (index < 0 || index >= self.models.count) {
        return NO;
    }
    NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];
    [temp insertObject:model atIndex:index+1];
    [self resetModels:temp];
    return YES;
}

/** 插入到index之前*/
- (BOOL) insertModel:(nonnull YTXRestfulModel *) model beforeIndex:(NSInteger) index
{
    if (self.models.count == 0) {
        return [self addModel:model];
    }

    if (index < 0 || index >= self.models.count) {
        return NO;
    }
    NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];
    [temp insertObject:model atIndex:index];
    [self resetModels:temp];
    return YES;
}

- (BOOL) removeModelAtIndex:(NSInteger) index
{
    if (index < 0 || index >= self.models.count) {
        return NO;
    }
    NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];
    [temp removeObjectAtIndex:index];
    [self resetModels:temp];
    return YES;
}

/** 主键可能是NSNumber或NSString，统一转成NSString来判断*/
- (BOOL) removeModelWithPrimaryKey:(nonnull NSString *) primaryKey
{
    for (YTXRestfulModel *model in self.models) {
        if ( [[[model primaryValue] description] isEqualToString:primaryKey]) {
            NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];
            [temp removeObject:model];
            [self resetModels:temp];
            return YES;
        }
    }
    return NO;
}

- (BOOL) removeModelWithModel:(nonnull YTXRestfulModel *) model
{
    NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];

    NSInteger index = [[self models] indexOfObject:model];

    if (NSNotFound == index) {
        return NO;
    }

    [temp removeObjectAtIndex:index];
    [self resetModels:temp];
    return YES;
}

- (void)reverseModels
{
    [self resetModels:self.models.reverseObjectEnumerator.allObjects];
}

- (nonnull NSArray *) arrayWithArgs:(va_list) args firstArgument:(nullable id)firstArgument
{
    if (firstArgument == nil) {
        return @[];
    }

    NSMutableArray * array = [NSMutableArray arrayWithObject:firstArgument];
    id arg = nil;
    while ((arg = va_arg(args,id))) {
        [array addObject:arg];
    }
    return array;
}

- (nonnull NSArray *) arrayOfMappedArgsWithOriginArray:(nonnull NSArray *)originArray
{
    NSDictionary * propertiesMap = [self.modelClass JSONKeyPathsByPropertyKey];
    NSMutableArray *retArray = [NSMutableArray array];
    for (id arg in originArray) {
        [retArray addObject:propertiesMap[arg] ?: arg];
    }
    return retArray;
}

- (id<YTXRestfulModelStorageProtocol>)storageSync
{
    YTXAssertSyncExists(_storageSync, @"StorageSync");
    return _storageSync;
}

-(id<YTXRestfulModelDBProtocol>)dbSync
{
    YTXAssertSyncExists(_dbSync, @"DBSync");
    return _dbSync;
}

-(id<YTXRestfulModelRemoteProtocol>)remoteSync
{
    YTXAssertSyncExists(_remoteSync, @"RemoteSync");
    return _remoteSync;
}

@end

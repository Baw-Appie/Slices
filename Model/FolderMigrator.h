@interface FolderMigrator : NSObject
@property (nonatomic, strong) NSArray *sourceFolderPaths;
@property (nonatomic, strong) NSArray *destinationFolderPaths;
@property (nonatomic, strong) NSArray *ignoreSuffixes;
@property (nonatomic, strong) NSArray *ignorePrefixes;

+ (BOOL)migrateDirectory:(NSString *)sourceDirectory toDirectory:(NSString *)destinationDirectory ignorePrefixes:(NSArray *)ignorePrefixes ignoreSuffixes:(NSArray *)ignoreSuffixes;
+ (BOOL)migrateDirectory:(NSString *)sourceDirectory toDirectory:(NSString *)destinationDirectory ignoreSuffixes:(NSArray *)ignoreSuffixes;
+ (BOOL)migrateDirectory:(NSString *)sourceDirectory toDirectory:(NSString *)destinationDirectory ignorePrefixes:(NSArray *)ignorePrefixes;

- (instancetype)initWithSourcePath:(NSString *)sourceFolderPath destinationPath:(NSString *)destinationFolderPath;
- (BOOL)executeMigration;
@end

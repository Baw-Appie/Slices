#import "FolderMigrator.h"

@implementation FolderMigrator
- (instancetype)initWithSourcePath:(NSString *)sourceFolderPath destinationPath:(NSString *)destinationFolderPath
{
	self = [super init];

	self.sourceFolderPaths = @[ sourceFolderPath ];
	self.destinationFolderPaths = @[ destinationFolderPath ];

	return self;
}

- (instancetype)initWithSourcePaths:(NSArray *)sourceFolderPaths destinationPath:(NSArray *)destinationFolderPaths
{
	self = [super init];

	self.sourceFolderPaths = sourceFolderPaths;
	self.destinationFolderPaths = destinationFolderPaths;

	return self;
}

- (BOOL)executeMigration
{
	BOOL errorOccurred = NO;
	for (NSInteger i = 0; i < self.sourceFolderPaths.count; i++)
	{
		NSString *sourceFolderPath = self.sourceFolderPaths[i];
		NSString *destinationFolderPath = self.destinationFolderPaths[i % self.destinationFolderPaths.count];

		if (![FolderMigrator migrateDirectory:sourceFolderPath toDirectory:destinationFolderPath ignorePrefixes:self.ignorePrefixes ignoreSuffixes:self.ignoreSuffixes])
			errorOccurred = YES;
	}

	return errorOccurred;
}

+ (BOOL)migrateDirectory:(NSString *)sourceDirectory toDirectory:(NSString *)destinationDirectory ignoreSuffixes:(NSArray *)ignoreSuffixes
{
	return [FolderMigrator migrateDirectory:sourceDirectory toDirectory:destinationDirectory ignorePrefixes:nil ignoreSuffixes:ignoreSuffixes];
}

+ (BOOL)migrateDirectory:(NSString *)sourceDirectory toDirectory:(NSString *)destinationDirectory ignorePrefixes:(NSArray *)ignorePrefixes
{
	return [FolderMigrator migrateDirectory:sourceDirectory toDirectory:destinationDirectory ignorePrefixes:ignorePrefixes ignoreSuffixes:nil];
}

+ (BOOL)migrateDirectory:(NSString *)sourceDirectory toDirectory:(NSString *)destinationDirectory ignorePrefixes:(NSArray *)ignorePrefixes ignoreSuffixes:(NSArray *)ignoreSuffixes
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *patchedDestinationDirectory = [[NSString stringWithFormat:@"%@", destinationDirectory] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
	NSString *patchedSourceDirectory = [[NSString stringWithFormat:@"%@", sourceDirectory] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
	NSArray *filesToMigrate = [manager contentsOfDirectoryAtPath:patchedSourceDirectory error:NULL];
	BOOL errorOccurred = NO;
	BOOL movingFiles = patchedDestinationDirectory.length > 0;

	if (movingFiles && ![manager fileExistsAtPath:patchedDestinationDirectory]) {
		[manager createDirectoryAtPath:patchedDestinationDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	for (NSString *file in filesToMigrate)
	{
		// check if we should operate on the file
		BOOL skipFile = NO;
		if (ignoreSuffixes)
		{
			for (NSString *suffix in ignoreSuffixes)
			{
				if ([file hasSuffix:suffix])
				{
					skipFile = YES;
					break;
				}
			}
		}

		if (ignorePrefixes)
		{
			for (NSString *prefix in ignorePrefixes)
			{
				if ([file hasPrefix:prefix])
				{
					skipFile = YES;
					break;
				}
			}
		}

		// if not, skip it
		if (skipFile) continue;

		// get the source path
		NSString *sourcePath = [patchedSourceDirectory stringByAppendingPathComponent:file];

		// move/delete it
		if (movingFiles) {
			NSString *destinationPath = [patchedDestinationDirectory stringByAppendingPathComponent:file];
			if (![manager moveItemAtPath:sourcePath toPath:destinationPath error:NULL]) errorOccurred = YES;
		} else if (![manager removeItemAtPath:sourcePath error:NULL]) errorOccurred = YES;
	}

	return errorOccurred;
}
@end

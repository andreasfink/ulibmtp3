//
//  UMEnvironmentNamedListProviderProtocol.h
//  umscript
//
//  Created by Andreas Fink on 04.05.20.
//

@protocol UMEnvironmentNamedListProviderProtocol<NSObject>

- (NSArray<NSString *>*)namedlistsListNames;
- (void)namedlistReplaceList:(NSString *)listName withContentsOfFile:(NSString *)filename;
- (void)namedlistsFlushAll;
- (void)namedlistsLoadFromDirectory:(NSString *)directory;
- (void)namedlistAdd:(NSString *)listName value:(NSString *)value;
- (void)namedlistRemove:(NSString *)listName value:(NSString *)value;
- (BOOL)namedlistContains:(NSString *)listName value:(NSString *)value;

@end

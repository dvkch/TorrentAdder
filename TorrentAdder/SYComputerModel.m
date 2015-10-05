//
//  SYComputerModel.m
//  TorrentAdder
//
//  Created by rominet on 19/05/14.
//  Copyright (c) 2014 Syan. All rights reserved.
//

#import "SYComputerModel.h"
#import "NSData+IPAddress.h"
#import "SYAppDelegate.h"
#import "SYNetworkManager.h"
#import <CocoaAsyncSocket.h>
#import "SYBonjourClient.h"

@interface SYComputerModel ()
@property (readwrite, strong, atomic) NSString *identifier;
@end

@implementation SYComputerModel

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.identifier = [[NSUUID UUID] UUIDString];
        self.sessionID = @"";
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name andHost:(NSString *)host
{
    self = [self init];
    if (self)
    {
        self.name = name;
        self.host = host;
        
        if (!self.name)
            self.name = [SYNetworkManager hostnameForIP:self.host];
        
        if (!self.name)
            self.name = [[SYBonjourClient shared] hostnameForIP:self.host];
        
        if (!self.name)
            self.name = host;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (self)
    {
        self.identifier = [aDecoder decodeObjectForKey:@"identifier"];
        self.name       = [aDecoder decodeObjectForKey:@"name"];
        self.host       = [aDecoder decodeObjectForKey:@"host"];
        self.port       = [aDecoder decodeIntegerForKey:@"port"];
        self.client     = [aDecoder decodeIntegerForKey:@"client"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.identifier    forKey:@"identifier"];
    [aCoder encodeObject:self.name          forKey:@"name"];
    [aCoder encodeObject:self.host          forKey:@"host"];
    [aCoder encodeInteger:self.port         forKey:@"port"];
    [aCoder encodeInteger:self.client       forKey:@"client"];
}

- (BOOL)isEqual:(id)object
{
    if(![object isKindOfClass:[self class]])
        return NO;
    
    return [[(SYComputerModel*)object identifier] isEqualToString:self.identifier];
}

- (NSURL *)webURL
{
    NSString *format;
    switch (self.client) {
        case SYClientSoftware_Transmission:
            format = @"http://%@:%d/transmission/web/";
            break;
        case SYClientSoftware_uTorrent:
            format = @"http://%@:%d/gui";
            break;
        default:
            return nil;
    }
    NSString *urlString = [NSString stringWithFormat:format,
                           self.host,
                           self.port];
    
    return [NSURL URLWithString:urlString];
}

- (NSURL *)apiURL
{
    NSString *format;
    switch (self.client) {
        case SYClientSoftware_Transmission:
            format = @"http://%@:%d/transmission/rpc/";
            break;
        default:
            return nil;
    }
    NSString *urlString = [NSString stringWithFormat:format,
                           self.host,
                           self.port];
    
    return [NSURL URLWithString:urlString];
}

- (BOOL)isValid
{
    return (self.name.length && self.host.length && self.port != 0);
}

+ (NSUInteger)defaultPortForClient:(SYClientSoftware)client
{
    switch (client) {
        case SYClientSoftware_Transmission:
            return 9091;
        case SYClientSoftware_uTorrent:
            return 18764;
    }
    return 0;
}

@end

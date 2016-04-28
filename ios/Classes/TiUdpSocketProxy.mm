/**
  *Appcelerator Titanium Mobile
  *Copyright (c) 2009-2011 by Appcelerator, Inc. All Rights Reserved.
  *Licensed under the terms of the Apache Public License
  *Please see the LICENSE included with this distribution for details.
 */
#import "TiUdpSocketProxy.h"
#import <Foundation/Foundation.h>
#import <CFNetwork/CFNetwork.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/fcntl.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>

@interface TiUdpSocketProxy (Private)

@end

@implementation TiUdpSocketProxy

#pragma mark Initialization and Deinitialization

-(id)init
{
    if ((self = [super init]))
    {
    }
    return self;
}

-(void)dealloc
{
    [self stop:nil];
    [super dealloc];
}

#pragma mark Private Utility

-(void)fireError:(NSError *)error
{
    [self fireEvent:@"error" withObject:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription],@"error",nil]];
}

-(void)send:(NSData*)data withDict:(NSDictionary*)args
{
    if (!isRunning) {
        [self fireEvent:@"error" withObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot send data before the socket is started!",@"error",nil]];
        return;
    }
    
    NSString *host = [TiUtils stringValue:[args objectForKey:@"host"]];
    NSString *group = [TiUtils stringValue:[args objectForKey:@"group"]];
    if (!group) {
        group = _group;
    }
    int port = [TiUtils intValue:[args objectForKey:@"port"] def:_port];
    NSError *error;
    
    [data retain];
    if (host && [host length] > 0) {
        [udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:tag];
    }
    else if (group && [group length] > 0) {
        if (![udpSocket enableBroadcast:YES error:&error]) {
            [self fireError:error];
            return;
        }
        [udpSocket sendData:data toHost:group port:port withTimeout:-1 tag:tag];
    }
    else {
        [udpSocket sendData:data withTimeout:-1 tag:tag];
    }
    tag++;
}

static NSArray *GetBytesFromData(NSData *data)
{
    NSMutableArray *result;
    NSUInteger dataLength;
    NSUInteger dataIndex;
    const uint8_t *dataBytes;
    
    assert(data != nil);
    
    dataLength = [data length];
    dataBytes = (uint8_t*)[data bytes];
    
    result = [NSMutableArray arrayWithCapacity:dataLength];
    assert(result != nil);
    
    for (dataIndex = 0; dataIndex < dataLength; dataIndex++)
    {
        int dataByte = dataBytes[dataIndex];
        NSNumber *number = [NSNumber numberWithUnsignedInt:dataByte];
        [result addObject:number];
    }
    
    return result;
}

#pragma mark Public API

-(void)start:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    int newPort = [TiUtils intValue:[args objectForKey:@"port"]];
    NSString *newGroup = [TiUtils stringValue:[args objectForKey:@"group"]];
    NSError *error = nil;
    
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    if (![udpSocket bindToPort:newPort error:&error])
    {
        [self fireError:error];
        return;
    }
    if (newGroup && [newGroup length] > 0 && ![udpSocket joinMulticastGroup:newGroup error:&error]) {
        [self fireError:error];
    }
    
    if (![udpSocket beginReceiving:&error])
    {
        [udpSocket close];
        [self fireError:error];
        return;
    }
    
    isRunning = YES;
    _port = newPort;
    _group = [newGroup retain];
    NSLog(@"[INFO] Socket Started!");
    [self fireEvent:@"started" withObject:nil];
}

-(void)sendString:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    [self send:[[TiUtils stringValue:[args objectForKey:@"data"]] dataUsingEncoding:NSUTF8StringEncoding] withDict:args];
}

-(void)sendBytes:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    NSArray *rawData = (NSArray*)[args objectForKey:@"data"];
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:[rawData count]];
    for (NSNumber *number in rawData)
    {
        char byte = [number charValue];
        [data appendBytes:&byte length:1];
    }
    
    [self send:data withDict:args];
    
    [data release];
}

-(void)stop:(id)args
{
    isRunning = NO;
    _port = 0;
    if (udpSocket != nil) {
        [udpSocket close];
        RELEASE_TO_NIL(udpSocket);
    }
    RELEASE_TO_NIL(_group);
    NSLog(@"[INFO] Stopped!");
}

#pragma mark Socket Delegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *bytesData = GetBytesFromData(data);
    NSString *host = nil;
    uint16_t port = 0;
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
    NSString *addr = [NSString stringWithFormat:@"%@:%d", host, port];
    
    [self fireEvent:@"data" withObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                        addr,@"address",
                                        bytesData,@"bytesData",
                                        stringData,@"stringData",
                                        nil]];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    // Well, isn't that nice?
    NSLog(@"[INFO] Data Sent!");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    [self fireError:error];
}

@end
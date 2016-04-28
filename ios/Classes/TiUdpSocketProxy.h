/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2011 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiProxy.h"
#import "TiUtils.h"
#import "GCDAsyncUdpSocket.h"

@interface TiUdpSocketProxy : TiProxy
{
	long tag;
	BOOL isRunning;
    NSUInteger _port;
    NSString *_group;
	GCDAsyncUdpSocket* udpSocket;
}

-(NSString*)apiName;
-(void)start:(id)args;
-(void)sendString:(id)args;
-(void)sendBytes:(id)args;
-(void)stop:(id)args;

@end
/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

#include once "fbNetwork.bi"

type simpleClient extends fbNetworkClient
	declare sub onConnect()
	declare sub onClose()
	declare sub onError()
	declare sub onMessage(message as string)
end type

const DEFAULT_HOST = "ipv6.icanhazip.com"

sub simpleClient.onConnect()
	const NEWLINE = !"\r\n"
	dim request as string
	request = "GET / HTTP/1.0" + NEWLINE + _
	             "Host: " + DEFAULT_HOST + NEWLINE + _
	             "Connection: close" + NEWLINE + _
	             "User-Agent: GetHTTP 0.0" + NEWLINE + _
	             NEWLINE
	this.connection->sendMessage(request)
	? "Connected!"
end sub

sub simpleClient.onClose()
	? "Disconnected!"
end sub

sub simpleClient.onError()
	? "Error!´!"
end sub

sub simpleClient.onMessage(message as string)
	? "Received: " + message
end sub


dim connection as fbNetwork
dim client as simpleClient

connection._client = @simpleClient

connection.open(DEFAULT_HOST, 80)

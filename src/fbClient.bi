/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

#include once "./common.bi"

	type _fbClient as fbClient

	type _openParams
		client as _fbClient ptr
		address as string
		port as uinteger
		timeoutValue as integer = 60
		protocol as TransportProtocol = TCP
	end type

type fbConnectionInfo
	ipAddress as string
	host as string
	protocol as TransportProtocol
	port as integer
end type

enum fbNetworkError
	net_undefined = 0
	net_timeout = 1
	net_cantCreateSocket = 2
	net_connectionInUse = 3
	net_invalidPort = 4
	net_connectionRefused = 5
	net_unknownHost = 6
end enum
	
type fbClient extends object
	private:
		_socket as SOCKET
		_addressInfo as addrInfo ptr
		_mutex as any ptr
		info as fbConnectionInfo
		_threadHandle as any ptr
		
		declare function setSocket() as boolean
		declare sub setInfo(port as integer, protocol as integer, host as string)
		declare sub errorHandler(socketError as fbNetworkError)
		declare static sub thunkOpen(params as _openParams ptr) 
	public:
		declare constructor()
		declare destructor()

		declare function open(address as string, _port as uinteger, timeoutValue as integer = 60, _protocol as TransportProtocol = TCP ) as boolean
		declare function openThreaded(address as string, _port as uinteger, timeoutValue as integer = 60, _protocol as TransportProtocol = TCP ) as boolean
		declare sub close()
		declare sub waitClose()
		declare function sendData(byref _data as string) as boolean

		declare property host() as string
		declare property ip() as string
		declare property port() as integer
		declare property isConnected() as boolean
		
		declare virtual sub onConnect()
		declare virtual sub onClose()
		declare virtual sub onError(errorCode as fbNetworkError = net_undefined)
		declare abstract sub onMessage(message as string)
end type

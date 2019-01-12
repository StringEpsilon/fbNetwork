/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

#ifdef __FB_WIN32__
#include once "win/winsock2.bi"
#else
#include once "crt/netdb.bi"
#include once "crt/sys/socket.bi"
#include once "crt/netinet/in.bi"
#include once "crt/arpa/inet.bi"
#include once "crt/unistd.bi"
#endif

declare function resolveHost( byref hostname as string, port as uinteger ) as addrinfo ptr
declare function getIpAdress(addressInfo as addrInfo ptr) as string

namespace fbNetwork
const RECVBUFFLEN = 7936
end namespace

enum TransportProtocol
	TCP = 0
	UDP = 1
end enum

type fbConnectionInfo
	ipAddress as string
	host as string
	protocol as TransportProtocol
	port as integer
end type

enum fbNetworkError
	net_undefined = 0
	net_timeout
	net_cantCreateSocket
	net_connectionInUse
	net_invalidPort
	net_connectionRefused	
end enum

type fbNetworkClient extends object
	private:
		_socket as SOCKET
		_addressInfo as addrInfo ptr
		_mutex as any ptr
		info as fbConnectionInfo
		
		declare function setSocket() as boolean
		declare sub setInfo(port as integer, protocol as integer, host as string)
	public:
		declare constructor()
		declare destructor()

		declare function open(address as string, port as uinteger, protocol as TransportProtocol = TCP) as boolean
		declare sub close()
		declare function sendData(byref _data as string) as boolean

		declare property host() as string
		declare property ip() as string
		declare property port() as integer
		
		declare abstract sub onConnect()
		declare abstract sub onClose()
		declare abstract sub onError(errorCode as fbNetworkError = net_undefined)
		declare abstract sub onMessage(message as string)
end type

/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

#ifdef __FB_WIN32__
	#include once "win/winsock2.bi"

	#include once "win/ws2tcpip.bi"
	#ifndef inet_ntop
	extern "C"
	' For some reason, inet_ntop from the ws2tcpip.bi isn't defined on my machine.
	declare function inet_ntop stdcall alias "inet_ntop"(byval Family as INT_, byval pAddr as PVOID, byval pStringBuf as LPSTR, byval StringBufSize as uinteger) as LPCSTR
	end extern
	#endif
	WSAStartup( MAKEWORD( 2, 0 ), new WSAData )
#else
	#include once "crt/netdb.bi"
	#include once "crt/fcntl.bi"
	#include once "crt/sys/socket.bi"
	#include once "crt/netinet/in.bi"
	#include once "crt/arpa/inet.bi"
	#include once "crt/unistd.bi"
	#include once "crt/sys/select.bi"
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
	net_timeout = 1
	net_cantCreateSocket = 2
	net_connectionInUse = 3
	net_invalidPort = 4
	net_connectionRefused = 5
	net_unknownHost = 6
end enum

type fbNetworkClient extends object
	private:
		_socket as SOCKET
		_addressInfo as addrInfo ptr
		_mutex as any ptr
		info as fbConnectionInfo
		
		declare function setSocket() as boolean
		declare sub setInfo(port as integer, protocol as integer, host as string)
		declare sub errorHandler(socketError as fbNetworkError)
	public:
		declare constructor()
		declare destructor()

		declare function open(address as string, _port as uinteger, timeoutValue as integer = 60, _protocol as TransportProtocol = TCP ) as boolean
		declare sub close()
		declare function sendData(byref _data as string) as boolean

		declare property host() as string
		declare property ip() as string
		declare property port() as integer
		declare property isConnected() as boolean
		
		declare abstract sub onConnect()
		declare abstract sub onClose()
		declare abstract sub onError(errorCode as fbNetworkError = net_undefined)
		declare abstract sub onMessage(message as string)
end type

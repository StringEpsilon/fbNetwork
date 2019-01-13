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

namespace fbNetwork
const RECVBUFFLEN = 7936
end namespace

enum TransportProtocol
	TCP = 0
	UDP = 1
end enum

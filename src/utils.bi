#ifdef __FB_WIN32__
#include once "win/winsock2.bi"
#else
#include once "crt/netdb.bi"
#include once "crt/sys/socket.bi"
#include once "crt/netinet/in.bi"
#include once "crt/arpa/inet.bi"
#include once "crt/unistd.bi"
#endif

/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

function resolveHost( byref hostname as string, port as uinteger ) as addrinfo ptr
	dim hints as addrInfo ptr = new addrinfo
	dim addressInfo as addrInfo ptr
	hints->ai_family = AF_UNSPEC
    hints->ai_socktype = SOCK_STREAM

	
	getAddrInfo(hostname, str(port), hints, @addressInfo)
	delete hints
	return addressInfo
end function

function getIpAdress(addressInfo as addrInfo ptr) as string
	if (addressInfo = 0) then return ""
	
	dim IP as string 
	if ( addressInfo->ai_family = AF_INET6 ) then
		IP = space(46)
		inet_ntop( addressInfo->ai_family, @(cast(sockaddr_in6 ptr,addressInfo->ai_addr)->sin6_addr), strptr(IP), len(IP) )
	else
		IP = space(16)
		inet_ntop( addressInfo->ai_family, @(cast(sockaddr_in ptr,addressInfo->ai_addr)->sin_addr), strptr(IP), len(IP) )
	end if
	
	return trim(IP)
end function

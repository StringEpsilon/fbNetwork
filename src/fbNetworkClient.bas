/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

#include once "./fbNetworkClient.bi"

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


constructor fbNetworkClient()
	this._mutex = mutexcreate()
end constructor

destructor fbNetworkClient()
	if (this._socket <> 0) then
		this.close()
	end if
	mutexdestroy(this._mutex)
end destructor

sub fbNetworkClient.setInfo(_port as integer, _protocol as integer, _host as string)
	this.info.ipAddress = getIpAdress(this._addressInfo)
	this.info.port = _port
	this.info.host = _host
	this.info.protocol = _protocol
end sub

function fbNetworkClient.setSocket() as boolean
	this._socket = opensocket( this._addressInfo->ai_family, SOCK_STREAM, IPPROTO_TCP )
	if (this._socket = 0) then
		freeaddrinfo(this._addressInfo)
		this.onError(net_cantCreateSocket)
		return false
	end if
	return true
end function

function fbNetworkClient.sendData( byref _data as string) as boolean
	mutexlock(this._mutex)
		if (this._socket = 0) then
			mutexunlock(this._mutex)
			return false
		end if
	mutexunlock(this._mutex)
	
	if( send( this._socket, _data, len( _data ), 0 ) = SOCKET_ERROR ) then
		this.onError()
		this.close()
		return false
	end if
	
	return true
end function

sub fbNetworkClient.close()
	mutexlock(this._mutex)
		closesocket( this._socket )
		freeaddrinfo(this._addressInfo)
		
		this._socket = 0
		this._addressInfo = 0
		
		this.onClose()
	mutexunlock(this._mutex)
end sub

function fbNetworkClient.open(address as string, _port as uinteger, _protocol as TransportProtocol ) as boolean
	mutexlock(this._mutex)
		if (this._socket <> 0) then
			mutexunlock(this._mutex)
			this.onError(net_connectionInUse)
			return false
		end if
		
		this._addressInfo = resolveHost(address, _port)
		this.setInfo(_port, _protocol, address)
		if (this.setSocket() = false) then
			mutexunlock(this._mutex)
			return false
		end if

		if( connect( this._socket, this._addressInfo->ai_addr, this._addressInfo->ai_addrlen ) = SOCKET_ERROR ) then
			closesocket( this._socket )
			freeaddrinfo(this._addressInfo)
			mutexunlock(this._mutex)
			this.onError(net_connectionRefused)
			return false
		end if		
	mutexunlock(this._mutex)
	this.onConnect()
		
	dim messageLength as integer
	dim recvbuffer as zstring * fbNetwork.RECVBUFFLEN+1
	do 
		messageLength = recv( this._socket, recvBuffer, fbNetwork.RECVBUFFLEN, 0 )
		if( messageLength  <= 0 ) then
			this.close()
			return true
		end if
		recvbuffer[messageLength] = 0
		this.onMessage(recvbuffer)
	loop
	
	return true
end function


property fbNetworkClient.host() as string
	return this.info.host
end property

property fbNetworkClient.ip() as string
	return this.info.ipAddress
end property

property fbNetworkClient.port() as integer
	return this.info.port
end property

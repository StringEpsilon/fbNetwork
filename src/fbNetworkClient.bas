/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

#include once "./fbNetworkClient.bi"
#include once "./common.bas"

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

sub fbNetworkClient.errorHandler(errorCode as fbNetworkError)
	mutexunlock(this._mutex)
	if (this._socket) then
		closesocket( this._socket )
		this._socket = 0
	end if
	if (this._addressInfo) then
		freeaddrinfo(this._addressInfo)		
		this._addressInfo = 0
	end if
	
	this.onError(errorCode)
end sub

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

function fbNetworkClient.open(address as string, _port as uinteger, timeoutValue as integer = 60, _protocol as TransportProtocol ) as boolean
	mutexlock(this._mutex)
		if (this._socket <> 0) then
			mutexunlock(this._mutex)
			return false
		end if
		
		this._addressInfo = resolveHost(address, _port)
		if (this._addressInfo = 0) then
			this.onError(net_unknownHost)
		end if
		
		this.setInfo(_port, _protocol, address)
		if (this.setSocket() = false) then
			mutexunlock(this._mutex)
			return false
		end if
		
		#ifdef __FB_WIN32__
			dim as integer blocking = 1
			ioctlsocket(this._socket, FIONBIO, @blocking)
		#else
			dim socketFlags as integer = fcntl(this._socket, F_GETFL, 0)
			fcntl(this._socket, F_SETFL, socketFlags or O_NONBLOCK)
		#endif
		
		if (connect( this._socket, this._addressInfo->ai_addr, this._addressInfo->ai_addrlen) <> 0) then
			dim timeout as timeval
			dim as fd_set fdset
			timeout.tv_sec = timeoutValue
			timeout.tv_usec = 0
			FD_ZERO(@fdset)
			FD_SET_(this._socket, @fdset)
			
			if ( select_(this._socket+1, 0, @fdset, 0, @timeout) = 1) then
				dim as integer socketError
				
				#ifdef __FB_WIN32__
					socketError = WSAGetLastError()
				#else
					dim as socklen_t length = sizeof(so_error)
					getsockopt(this._socket, SOL_SOCKET, SO_ERROR, @socketError, @length)
				#endif
				if (socketError) then
					this.errorHandler(net_undefined)
					return false
				end if
				#ifdef __FB_WIN32__
					blocking = 0 : ioctlsocket(this._socket, FIONBIO, @blocking)
				#else
					fcntl(this._socket, F_SETFL, socketFlags AND NOT O_NONBLOCK)
				#endif
			else
				this.errorHandler(net_timeout)
				return false
			end if
		else
			this.errorHandler(net_connectionRefused)
			return false
		end if
	mutexunlock(this._mutex)
	this.onConnect()
		
	dim messageLength as integer
	dim recvbuffer as zstring * fbNetwork.RECVBUFFLEN+1
	do 
		messageLength = recv( this._socket, recvBuffer, fbNetwork.RECVBUFFLEN, 0 )
		if( messageLength <= 0 ) then
			this.close()
			return true
		end if
		recvbuffer[messageLength] = 0
		this.onMessage(recvbuffer)
	loop
	
	return true
end function

property fbNetworkClient.isConnected() as boolean
	return this._socket <> 0
end property

property fbNetworkClient.host() as string
	return this.info.host
end property

property fbNetworkClient.ip() as string
	return this.info.ipAddress
end property

property fbNetworkClient.port() as integer
	return this.info.port
end property

sub fbNetworkClient.onConnect()
end sub

sub fbNetworkClient.onClose()
end sub

sub fbNetworkClient.onError(errorCode as fbNetworkError = net_undefined)
end sub

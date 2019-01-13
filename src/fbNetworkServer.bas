/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

#include once "./fbNetworkServer.bi"
#include once "./common.bas"
#include once "crt.bi"

constructor fbNetworkServer()
	this._mutex = mutexcreate()
end constructor

destructor fbNetworkServer()
	if (this._socket <> 0) then
		this.close()
	end if
	mutexdestroy(this._mutex)
end destructor

function fbNetworkServer.setSocket() as boolean
	this._socket = opensocket( AF_INET, SOCK_STREAM, IPPROTO_TCP )
	if (this._socket = 0) then
		this.onError()
		return false
	end if
	return true
end function

function fbNetworkServer.sendData(client as socket,  byref _data as string) as boolean
	mutexlock(this._mutex)
		if (this._socket = 0) then
			mutexunlock(this._mutex)
			return false
		end if
	mutexunlock(this._mutex)
	
	if( send( client, _data, len( _data ), 0 ) = SOCKET_ERROR ) then
		this.onError()
		return false
	end if
	
	return true
end function

sub fbNetworkServer.close()
	mutexlock(this._mutex)
		closesocket( this._socket )
		delete(this._addressInfo)
		this._socket = 0
		this._addressInfo = 0
		
		this.onClose()
	mutexunlock(this._mutex)
end sub

function fbNetworkServer.start(_port as uinteger, maxConnections as integer = 100, _protocol as TransportProtocol ) as boolean
	mutexlock(this._mutex)
		if (this._socket <> 0) then
			mutexunlock(this._mutex)
			return false
		end if
		
		this._addressInfo = new sockaddr_in
		this._addressInfo->sin_family = AF_INET
		this._addressInfo->sin_addr.s_addr = htonl(INADDR_ANY)
		this._addressInfo->sin_port = htons(_port)
		
		this._port = _port
		this._maxConnections = maxConnections
		
		if (this.setSocket() = false) then
			mutexunlock(this._mutex)
			return false
		end if

		if (bind( this._socket, cptr(sockaddr ptr,this._addressInfo), sizeof(sockaddr_in)) <> 0) then
			print errno
			mutexunlock(this._mutex)
			this.onError()
			return false
		end if
		
		if (listen(this._socket, this._maxConnections) = -1) then
			return false
		end if
	mutexunlock(this._mutex)
	this.onEstablish()
	this._handle = threadCreate(cast(any ptr, @fbNetworkServer.eventLoop), @this)
	return true
end function

sub fbNetworkServer.eventLoop(this as fbNetworkServer ptr)
	dim readfds as fd_set ptr = new fd_set
	dim maxSD as socket = this->_socket
	dim clientAddress as sockaddr ptr = cast(sockaddr ptr, new sockaddr_in)
	dim newSocket as socket
	dim addrLen as socklen_t = sizeof(sockaddr_in)
	dim as timeval ptr timeout = new timeval
	timeout->tv_sec = 1
	timeout->tv_usec = 0
	this->_clients = callocate(sizeof(socket)* this->_maxConnections)
	do
		FD_ZERO(readfds)     
		mutexlock(this->_mutex)
        FD_SET_(this->_socket, readfds)
		maxSd = this->_socket
		for i as integer = 0 to this->_maxConnections
			if (maxSd < this->_clients[i]) then
				maxSd = this->_clients[i]
			end if
		next
		if (select_( maxSD + 1 , readfds , NULL , NULL , timeout) < 0) then
			return
		end if
		
		if (FD_ISSET(this->_socket, readfds)) then
			newSocket = accept(this->_socket,clientAddress, @addrLen)
			if newSocket = -1 then 
				return
			end if
			for i as integer = 0 to this->_maxConnections
				if (this->_clients[i] = 0) then
					this->_clients[i] = newSocket
					exit for
				end if
			next
			maxSD = newSocket
			mutexunlock(this->_mutex)
            this->onConnection(newSocket)
		end if
		
		for i as integer = 0 to this->_maxConnections
			if (this->_clients[i] <> 0 ) then
				dim buffer as zstring * fbNetwork.RECVBUFFLEN+1
				dim messageLength as integer
				messageLength = recv( this->_clients[i], buffer, fbNetwork.RECVBUFFLEN,0)
				if ( messageLength = 0) then
					mutexunlock(this->_mutex)
					this->onDisconnect(this->_clients[i])
					closesocket(this->_clients[i])
					this->_clients[i] = 0
				elseif (messageLength > 0) then
					mutexunlock(this->_mutex)
					this->onMessage(this->_clients[i], buffer)
				end if
			end if
        next
	loop until this->_socket = 0
	this->onClose()
end sub

sub fbNetworkServer.waitForShutdown()
	threadwait this._handle
end sub

property fbNetworkServer.port() as integer
	return this._port
end property

sub fbNetworkServer.onEstablish()
end sub

sub fbNetworkServer.onConnection(clientSocket as socket)
end sub

sub fbNetworkServer.onDisconnect(clientSocket as socket)
end sub

sub fbNetworkServer.onMessage(client as socket, message as string)
end sub

sub fbNetworkServer.onClose()
end sub

sub fbNetworkServer.onError()
end sub


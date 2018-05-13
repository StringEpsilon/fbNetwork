/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/
#include once "utils.bi"

namespace fb_n
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
	dim recvbuffer as zstring * fb_n.RECVBUFFLEN+1
	do 
		messageLength = recv( this._socket, recvBuffer, fb_n.RECVBUFFLEN, 0 )
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

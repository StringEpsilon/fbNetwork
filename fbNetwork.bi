/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

#include once "utils/network.bi"

enum TransportProtocol
	TCP = 0
	UDP = 1
end enum

type fbConnectionInfo
	ipAddress as string
	protocol as TransportProtocol
	port as integer
	
end type


type fbNetwork as _fbNetwork

type fbNetworkClient extends object
	dim connection as fbNetwork ptr

	declare abstract sub onConnect()
	declare abstract sub onClose()
	declare abstract sub onError()
	declare abstract sub onMessage(message as string)
end type


type _fbNetwork extends object
	private:
		_socket as SOCKET
		_addressInfo as addrInfo ptr
		

	public:
		dim info as fbConnectionInfo
		dim status as string
		_client as fbNetworkClient ptr

		declare sub open(address as string, port as uinteger, protocol as TransportProtocol = TCP) 
		declare sub close()
		declare function sendMessage(message as string) as boolean
end type

function _fbNetwork.sendMessage(message as string) as boolean
	if( send( this._socket, message, len( message ), 0 ) = SOCKET_ERROR ) then
		this.close()
		return false
	end if
	
	return true
end function

sub _fbNetwork.close()
	closesocket( this._socket )
	freeaddrinfo(this._addressInfo)
	
	if ( this._client <> 0 ) then
		this._client->connection = 0
		this._client->onClose()
	end if
end sub

sub _fbNetwork.open(address as string, port as uinteger, protocol as TransportProtocol )
	this._addressInfo = resolveHost(address, port)
	this._socket = opensocket( this._addressInfo->ai_family, SOCK_STREAM, IPPROTO_TCP )
	if (this._socket = 0) then
		freeaddrinfo(this._addressInfo)
		return
	end if
	
	if( connect( this._socket, this._addressInfo->ai_addr, this._addressInfo->ai_addrlen ) = SOCKET_ERROR ) then
		closesocket( this._socket )
		freeaddrinfo(this._addressInfo)
		return
	end if
	
	this.info.ipAddress = getIpAdress(this._addressInfo)
	this.info.port = port
	this.info.protocol = protocol
	
	if ( this._client <> 0 ) then
		this._client->connection = @this
		this._client->onConnect()
	end if
	
	const RECVBUFFLEN = 7936
	dim messageLength as integer
	dim recvbuffer as zstring * RECVBUFFLEN+1
	sleep 100,1
	do
		messageLength = recv( this._socket, recvBuffer, RECVBUFFLEN, 0 )
		if( messageLength  <= 0 ) then
			this.close()
			exit do
		end if

		'' add the null-terminator
		recvbuffer[messageLength] = 0

		'' print buffer as a string
		if ( this._client <> 0 ) then
			this._client->onMessage(recvbuffer)
		end if
	loop
end sub

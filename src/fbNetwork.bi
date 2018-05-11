/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

#include once "utils.bi"

namespace fb_n
const RECVBUFFLEN = 7936
end namespace

enum fbNetworkErrors
	undefined = 0
	timeout
	connectionRefused
	
end enum

enum TransportProtocol
	TCP = 0
	UDP = 1
end enum

type fbConnectionInfo
	ipAddress as string
	protocol as TransportProtocol
	port as integer
	
end type

type fbNetwork extends object
	private:
		_socket as SOCKET
		_addressInfo as addrInfo ptr
		
		declare function setSocket() as boolean
		declare sub setInfo(port as integer, protocol as integer)

	public:
		dim info as fbConnectionInfo
		dim status as string
		_client as fbNetworkClient ptr

		declare destructor()

		declare function open(address as string, port as uinteger, protocol as TransportProtocol = TCP) as boolean
		declare sub close()
		declare function sendMessage(message as string) as boolean
end type

destructor fbNetwork()
	if (this._socket <> 0) then
		this.close()
	end if
end destructor

sub fbNetwork.setInfo(port as integer, protocol as integer)
	this.info.ipAddress = getIpAdress(this._addressInfo)
	this.info.port = port
	this.info.protocol = protocol
end sub

function fbNetwork.setSocket() as boolean
	this._socket = opensocket( this._addressInfo->ai_family, SOCK_STREAM, IPPROTO_TCP )
	if (this._socket = 0) then
		freeaddrinfo(this._addressInfo)
		this._client->onError()
		return false
	end if
	return true
end function

function fbNetwork.sendMessage(message as string) as boolean
	if( send( this._socket, message, len( message ), 0 ) = SOCKET_ERROR ) then
		this.close()
		return false
	end if
	
	return true
end function

sub fbNetwork.close()
	closesocket( this._socket )
	freeaddrinfo(this._addressInfo)
	
	this._socket = 0
	this._addressInfo = 0
	
	if ( this._client <> 0 ) then
		this._client->onClose()
		this._client->connection = 0
	end if
end sub

function fbNetwork.open(address as string, port as uinteger, protocol as TransportProtocol ) as boolean
	if (this._client = 0) then
		return false
	end if
	this._client->connection = @this	
	
	if (this._socket <> 0) then
		this._client->onError()
		return false
	end if
	
	this._addressInfo = resolveHost(address, port)
	
	if (this.setSocket() = false) then
		return false
	end if

	if( connect( this._socket, this._addressInfo->ai_addr, this._addressInfo->ai_addrlen ) = SOCKET_ERROR ) then
		closesocket( this._socket )
		freeaddrinfo(this._addressInfo)
		this._client->onError()
		return false
	end if
	

	this.setInfo(port, protocol)
	this._client->onConnect()
	
	
	dim messageLength as integer
	dim recvbuffer as zstring * fb_n.RECVBUFFLEN+1
	do 
		do
			messageLength = recv( this._socket, recvBuffer, fb_n.RECVBUFFLEN, 0 )
			if( messageLength  <= 0 ) then
				this.close()
				exit do, do
			end if
			'' add the null-terminator
			recvbuffer[messageLength] = 0

			'' print buffer as a string
			if ( this._client <> 0 ) then
				this._client->onMessage(recvbuffer)
			end if
			'recvbuffer = ""
		loop
	loop
	
	return true
end function

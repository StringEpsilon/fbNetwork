/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/
#include once "./common.bi"


type fbNetworkServer extends object
	private:
		_addressInfo as sockaddr_in ptr
		_socket as SOCKET
		_mutex as any ptr
		_port as integer
		_maxConnections as integer
		
		
		declare function setSocket() as boolean
		declare sub setInfo(port as integer, protocol as integer, host as string)
		declare static sub eventLoop(thisPtr as fbNetworkServer ptr)
	protected:
		_clients as socket ptr
	public:
	_handle as any ptr
		declare constructor()
		declare destructor()

		declare function start(_port as uinteger, maxConnections as integer = 100, _protocol as TransportProtocol = TCP ) as boolean
		declare sub close()
		declare function sendData(client as socket, byref _data as string) as boolean
		
		declare property port() as integer
		
		declare virtual sub onEstablish()
		declare virtual sub onConnection(clientSocket as socket)
		declare virtual sub onMessage(client as socket, message as string)
		declare virtual sub onClose()
		declare virtual sub onError()
end type

/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/
#include once "../src/fbNetworkClient.bas"
#include once "../src/fbNetworkServer.bas"
const NEWLINE = !"\r\n"

type echoServer extends fbNetworkServer
	declare sub onConnection(clientSocket as socket)
	declare sub onMessage(client as socket, message as string)
	declare sub onDisconnect(clientSocket as socket)
end type

sub echoServer.onConnection(clientSocket as socket)
	print "[Server] Client '"& clientSocket &"' connected"
end sub

sub echoServer.onDisconnect(clientSocket as socket)
	print "[Server] Client '"& clientSocket &"' disconnected"
end sub


sub echoServer.onMessage(client as socket, message as string)
	print "[Server] Client '"& client &"' sent "& message
	this.sendData(client,message)
end sub


type echoClient extends fbNetworkClient
	declare sub onConnect()
	declare sub onMessage(message as string)
end type

sub echoClient.onConnect()
	print "[Client]: Connected - sending ping."
	this.sendData("PING")
end sub

sub echoClient.onMessage(message as string)
	print "[Client] Server replied: "; message
	this.close()
end sub

dim client as echoClient
dim server as echoServer
server.start(8080)

client.open("127.0.0.1", 8080, 5)
client.open("127.0.0.1", 8080, 5)
client.open("127.0.0.1", 8080, 5)

server.close()
server.waitForShutdown()


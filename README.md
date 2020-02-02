# fbNetwork

fbNetwork is a simple, object oriented network library licensed under the MPL 2.0

## Motivation

Since you can't get a pointer to a method of a UDT / class instance, working with callback based
network libraries can be a bit of a hassle when the rest of your programm is OOP. This library aims to
fix that pain by implementing the network part itself in a class so the programmer can simply extend it to
implement their parsing, event handling and so on on top.

A very simple HTTP client can be found in the examples folder.

## TODO

High level:

* [ ] Testing under real conditions
* [ ] Test the client and server thoroughly on windows
* [ ] Get some feedback on the API
* [ ] Get some feedback on the actual network handling, especially the errorhandling

Detail:

* [ ] Make fbNetworkClient better aware of it's own connection status
* [x] Write and expose an isConnected property.
* [x] Make timeout configurable.
* [x] Figure out a way to close the server properly and end it's thread.
* [ ] Call handlers for client related events on server in thread.

## extending fbNetworkClient

fbNetworkClient (name might change) is the class you extend for writing your own network client.

Your class can to implement the following subs  as needed. 
Only onMessage must be implemented, as it it abstract in the base class.

```sub onConnect()```

Gets called when the connection is established.

```sub onClose()```

Gets called when a connection closes.

```sub onError(errorCode as fbNetworkError = net_undefined)```

Gets called when an error occurs on the network. See the fbNetworkError enum for details.

```sub onMessage(message as string)```

Gets called when a message / data is received from the server. 

## fbNetworkClient API

The following belong to the public API of the baseclass and thus your client:

```function open(address as string, port as uinteger, timeout as integer, protocol as TransportProtocol = TCP) as boolean```

Connect to the given address and port. 

Returns false if connection could not be established. 
Returns true **after** the connection was disconnected regularly. That might take a while ;-)

```sub close()```

Close the connection of the client, if there currently is a connection.

```function sendData(byref _data as string) as boolean```

Sends data to the server. Returns true if sending was successful.

## extending fbServer

Your class can to implement the following subs  as needed. Some of these might change from virtual to abstract later.

Also: I might later change how server implementations are supposed to handle clients. I don't like socket parameter.

```sub onEstablish()```

Gets called when the server is ready to listen for incomming connections.

```sub onConnection(client as socket)```

Gets called when a client connects, with the socket for that client as a parameter.

```sub onDisconnect(client as socket)```

Gets called when a client disconnects.

Note: The socket will immediately be closed after onDisconnect is called.

```sub onMessage(client as socket, message as string)```
Gets called when a client sent data.

```sub onClose()```
Called when the server closed and exited it's main eventloop. You can savely restart the server after this was called.

```sub onError()```
Currently unused and will probably get a parameter or two later.

## fbServer API

The following belong to the public API of the baseclass and thus your client:

```function open(port as uinteger, maxConnections as integer = 100, protocol as TransportProtocol = TCP) as boolean```

Starts the server with the given port, connection pool size and protocol. 

This also creates a thread interally you can await with ```waitForShutdown```.

```sub close()```

Closes the server. It can take up to a second for the internal thread to clear after you called this.

```sub waitForShutdown()```

Waits for the internal thread of the server to finish. 


```function sendData(client as socket, _data as string) as boolean```

Sends data to the specified client socket. Returns true if sending was successful.

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
* [ ] Testing in windows
* [ ] Get some feedback on the API
* [ ] Get some feedback on the actual network handling, especially the errorhandling
* [ ] Implement fbNetworkServer

Detail:

* [ ] Make fbNetworkClient better aware of it's own connection status
* [x] Write and expose an isConnected property.
* [x] Make timeout configurable.

## extending fbNetworkClient

fbNetworkClient is the class you extend for writing your own network client.

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

```function open(address as string, port as uinteger, protocol as TransportProtocol = TCP) as boolean```

Connect to the given address and port. 

Returns false if connection could not be established. 
Returns true **after** the connection was disconnected regularly. That might take a while ;-)

```sub close()```

Close the connection of the client, if there currently is a connection.

```function sendData(byref _data as string) as boolean```

Sends data to the server. Returns true if sending was successful.

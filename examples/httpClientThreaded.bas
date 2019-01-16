/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/
#include once "../src/fbClient.bas"
const NEWLINE = !"\r\n"

type httpClient extends fbClient
	' We only declare the callbacks we need for this example:
	declare sub onConnect()
	declare sub onError(errorCode as fbNetworkError)
	declare sub onMessage(message as string)
	'declare sub onClose()
end type

sub httpClient.onConnect()
	this.sendData(_
		!"GET / HTTP/1.1 \r\n" + _
		!"Host: httpstat.us \r\n" + _
		!"Connection: close \r\n" + _
		!"User-Agent: GetHTTP 0.0 \r\n\r\n")
end sub

sub httpClient.onError(errorCode as fbNetworkError)
	print "Error connecting to "& this.host & ":" & this.port
end sub

sub httpClient.onMessage(message as string)
	' For the sake of readable output, this cuts out just the IP part of the response.
	print "Your IP: "+ trim(right(message, len(message) - instrRev(message, NEWLINE)-1),any NEWLINE)
end sub

dim as httpClient client1, client2, client3

print "Testing timeout, 5 seconds", time
client3.openThreaded("198.51.100.0", 1234, 5)

print "Testing ipv4.icanhazip.com"
client1.openThreaded("ipv4.icanhazip.com", 80)

print "Testing ipv5.icanhazip.com"
client2.openThreaded("ipv6.icanhazip.com", 80)

client1.waitClose()
client2.waitClose()
client3.waitClose()

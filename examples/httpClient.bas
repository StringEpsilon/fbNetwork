/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

#include once "../src/fbNetworkClient.bas"

type httpClient extends fbNetworkClient
	declare sub onConnect()
	declare sub onClose()
	declare sub onError(errorCode as fbNetworkError)
	declare sub onMessage(message as string)
end type

sub httpClient.onConnect()
	const NEWLINE = !"\r\n"
	dim request as string

	this.sendData(_
		"GET / " + "HTTP/1.1" + NEWLINE + _
		"Host: httpstat.us " + NEWLINE + _
		"Connection: close" + NEWLINE + _
		"User-Agent: GetHTTP 0.0" + NEWLINE + _
		NEWLINE )
	
	print "Connected to "& this.host & ":" & this.port
end sub

sub httpClient.onClose()
	print "Disonnected from "& this.host & ":" & this.port
end sub

sub httpClient.onError(errorCode as fbNetworkError)
	print "Error connecting to"& this.host & ":" & this.port
end sub

sub httpClient.onMessage(message as string)
	print "Got data: ";
	print trim(right(message, len(message) - instrRev(message, !"\r\n")-1),any !"\r\n")
end sub


dim client as httpClient
print "Testing ipv4.icanhazip.com"
client.open("ipv4.icanhazip.com", 80)

print
print "Testing ipv4.icanhazip.com"
client.open("ipv6.icanhazip.com", 80)
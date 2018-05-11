/'	
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/. 
'/

type _fbNetwork as fbNetwork

type fbNetworkClient extends object
	dim connection as _fbNetwork ptr

	declare abstract sub onConnect()
	declare abstract sub onClose()
	declare abstract sub onError()
	declare abstract sub onMessage(message as string)
end type

#include once "./fbNetwork.bi"


# WiFi-Ninja
Copyright (C) 2017 - Christof Torres

![WiFi-Ninja-Logo](https://raw.githubusercontent.com/christoftorres/WiFi-Ninja/master/WiFi-Ninja/Images.xcassets/AppIcon.appiconset/Ninja-icon.png?raw=true "WiFi-Ninja-Logo")

License/usage:
=========================
This software is released under the terms of the MIT license, a copy
of which should be included with this distribution.
This software is provided "AS IS", without any warranties of any kind,
either expressed or implied.

What Does It Do?
================

WiFi-Ninja is based on [unixpickle's JamWiFi](https://github.com/unixpickle/JamWiFi) and allows you to select one or more nearby wireless networks, thereupon presenting a list of clients which are currently active on the network(s). Furthermore, WiFi-Ninja allows you to disconnect clients of your choosing for as long as you wish, but also let's you impersonate a client by changing your MAC address to be the same as the one of the client. This might be useful to bypass login's of WiFi hotspots. Finally, WiFi-Ninja also captures WiFi Probe Requests and lists them in a table, allowing you to see where the clients near you have been!

How Does It Work?
=================

Under the hood, WiFi-Ninja uses Apple's CoreWLAN API for channel hopping and network scanning. For a raw packet interface, libpcap provides a good point of abstraction for sending/receiving raw 802.11 frames at the MAC layer. All 802.11 MAC packets include a MAC address source and destination. This allows WiFi-Ninja to determine the stations on a given Access Point.

WiFi-Ninja "kicks off" clients using a disassociation frame. When a client receives a disassociation frame from an Access Point, it will assume that any connection which it had with the AP is no longer active. However, once a client receives a disassociation frame, it may immediately attempt to establish a new session with the AP. To prevent against this, WiFi-Ninja continually sends disassociation frames to every client quite frequently.

Caveats
=======

Some networks include more than one Access Point. Moreover, there may be scenarios in which more than one usable WiFi network is available to a client. In this scenario, even if a client is disassociated from one AP, it may successfully be able to establish a session with another AP. To overcome this, WiFi-Ninja sends disassociation frames to every client from every AP, whether or not that client may be associated with the AP. While this may seem like unnecessary overhead, it is necessary for more complex networks with >1 access point.

I can't wait to ruin my neighbors' networks!
--------------------------------------------

Just a second, there. I am not responsible for any damage you may do to anybody using this tool. This is for experimental and learning purposes only. Please, please, please, think twice before you do something stupid with this. How would you like it if your WiFi never worked because you had a jerk for a neighbor?

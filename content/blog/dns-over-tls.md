---
title: "DNS over TLS on Arch Linux"
date: 2020-08-20
slug: "dns-over-tls"
draft: false
---

Domain name resolution is not standardized, some application use NSS, some use D-Bus, others use stub resolvers.
`systemd-resolved` handles all of them and comes with systemd that Arch Linux uses.

`systemd-resolved` configuration file is at `/etc/systemd/resolved.conf`, yours should look like this:

	[Resolve]
	DNS=1.1.1.1
	FallbackDNS=127.0.0.1 ::1
	Domains=~.
	#LLMNR=yes
	#MulticastDNS=yes
	DNSSEC=yes
	DNSOverTLS=yes
	#Cache=yes
	#DNSStubListener=yes
	#ReadEtcHosts=yes

You should enable the `systemd-resolved` service.

	sudo systemctl enable --now systemd-resolved

## NetworkManager

Since you are probably using NetworkManager,
you should tell it to use `systemd-resolved` by going to its configuration file (`/etc/NetworkManager/NetworkManger.conf`)
and specifying `dns` property.

This is how your `/etc/NetworkManager/NetworkManger.conf` should look like:

	[main]
	plugins=keyfile
	dns=systemd-resolved

**You will probably need to restart your computer for changes to take effect.**

If you found any mistakes or that something is outdated, please [contact me](/contact/).

---
title: "DNS over TLS on Arch Linux"
date: 2020-08-20
lastmod: 2022-07-09
description: "In this guide I will show you how to set up DNS over TLS on Arch Linux using systemd-resolved."
slug: "dns-over-tls"
draft: false
---

In the GNU/Linux ecosystem there isn't really a standardized way for applications to resolve domain names.
Some application use NSS, some use D-Bus, others use stub resolvers.
`systemd-resolved` handles all of those methods and comes with systemd that Arch Linux uses.

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
you should tell it to use `systemd-resolved` by going to its configuration file (`/etc/NetworkManager/NetworkManager.conf`)
and specifying `dns` property.

This is how your `/etc/NetworkManager/NetworkManager.conf` should look like:

	[main]
	plugins=keyfile
	dns=systemd-resolved

**You will probably need to restart your computer for changes to take effect.**

If you found any mistakes or that something is outdated, please
feel free to [contact me](/contact/) or contribute to [this site's repository](https://github.com/MatejaMaric/blog).

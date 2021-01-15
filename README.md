# DarkFlare
Flarum, but on the Darknet

This script will install Flarum as a Tor hidden service on a Debian 10 machine. Useful for quickly standing up disposable, anonymous, Flarum communites.

Requires Debian 10 machine to host on

### Install
* ???

### Operator Opsec
This section will teach you how to run a DarkFlare community, and never get caught. Warning - for the ultimate security, it will cost a bit in hardware.
#### Safe Hardware
To be truely safe, you must purchase a clean laptop and a raspberryPI. These two devices are the fundamental building blocks through which you will interact with
the darknet and your DarkFlare community.
##### Laptop
Get cash at a random ATM for the entire ammount of the laptop you want to buy. You'll want to buy this at a Best Buy, or other electronics store.
Park away from the store, and try to walk through an area where there will be no cameras. Cover your head, face, and eyes with a hat, sunglasses, and a mask/scarf.
##### RaspberryPI
The rPI will be used as a hardware TOR router, and will ensure any network traffic leaving your new laptop will be sent via TOR. RaspberryPIs aren't
a suspicious item, and is at low risk of interdiction, so it's likely safe to purchase this via normal channels & methods.
Once you get your rPI, you'll need to install PORTAL of Pi and set it up as your laptops upstream router - https://github.com/grugq/PORTALofPi
#### Safe Harbor
You'll need a web hoster that will allow you pay anonymously, and that doesn't collect any personal information. Bulletproof, off-shore hosts that accept
Monero would be prefereable. Ideally, you'll backup your Flarum data regularly to another anoymous hosting provider or at home (always via TOR) for redundancy.
#### OpSec
* Never log into your hosting provider, or Flarum server without going through your PORTAL of Pi
* Never use personal information for anything. Not even email addresses.
* When sendind data around, always prefer using TOR as the transport

# DarkFlare
Flarum, but on the Darknet

!!! - This project is currently in Beta: Do not use in production unless you know how to harden Debian, Flarum, and PHP (more on this later)

This script will install Flarum as a Tor hidden service on a Debian 10 machine. Useful for quickly standing up disposable, anonymous, Flarum communites.

Requires Debian 10 machine to host on

### Install
wget https://github.com/0x9090/DarkFlare/blob/main/setup.sh && chmod +x setup.sh && sudo ./setup.sh

### Server Hardening
( TO DO )
https://github.com/0x9090/DarkFlare/blob/main/harden.sh

This server hardening scripts assumes that the setup.sh has already been successfully run, and Flarum is working properly.

### Operator Opsec
This section will teach you how to run a DarkFlare community, and never get caught. Warning - for the ultimate security, it will cost a bit in hardware.
#### Safe Hardware
To be truely safe, you must purchase a clean laptop and a raspberryPI. These two devices are the fundamental building blocks through which you will interact with the darknet and your DarkFlare community.
##### Laptop
Get cash at a random ATM for the entire ammount of the laptop you want to buy. You'll want to buy this at a Best Buy, or other electronics store.
Park away from the store, and try to walk through an area where there will be no cameras. Cover your head, face, and eyes with a hat, sunglasses, and a mask/scarf. Wear non-descript clothing. If you're compelled to ID yourself, scrap the whole trip and start over later.
##### RaspberryPI
The rPI will be used as a hardware TOR router, and will ensure any network traffic leaving your new laptop will be sent via TOR. RaspberryPIs aren't
a suspicious item, and is at low risk of interdiction, so it's likely safe to purchase this via normal channels & methods.
Once you get your rPI, you'll need to install PORTAL of Pi and set it up as your laptops upstream router - https://github.com/grugq/PORTALofPi
#### Server / VPS
You'll need a web hoster that will allow you pay anonymously, and that doesn't collect any personal information. Bulletproof, off-shore hosts that accept
Monero would be prefereable. Ideally, you'll backup your Flarum data regularly to another anoymous hosting provider or at home (always via TOR) for redundancy. Treat your server as disposable, and expect that it is compromised at all times. Operating this way means you won't have to care about PHP, or Flarum, or Nginx, or Linux, or ... from being hacked. Keep the Flarum database and TOR keys backed up, and you'll be fine.
#### OpSec
* Never log into your hosting provider, or Flarum server without going through your PORTAL of Pi
* Never use personal information for anything. Not even email addresses.
* Pay for things only using Monero.
* When sending data around, always prefer using TOR as the transport. Your DarkFlare instance has a TOR HTTP socket listening on 127.0.0.1:9050
* Don't talk about yourself at all. Not even what the weather is like outside.

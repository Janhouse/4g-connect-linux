4g-connect-linux
================

Huawei 4g modem E3276 (and possibly others) connect script 
by Janhouse (Janis Jansons) - janis.jansons@janhouse.lv

This has been tested with Latvian based operator LMT on a laptop with  Archlinux 
running kernel 3.9.5.
It should work for many other modems and networks.
Just make sure you have a recent kernel with working driver (>3.9.4 or something).

Modem:

```Bus 001 Device 020: ID 12d1:1506 Huawei Technologies Co., Ltd. E398 LTE/UMTS/GSM Modem/Networkcard```


I made this script because at the time of writing ModemManager and wvdial does
not support these USB modems and there isn't much information on how to get it
working.


Basically it is really simple and you can probably do it without this script but
I wanted some extra automation + quality monitoring.


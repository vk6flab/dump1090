README for Dump1090
===
Dump1090 is a Mode S decoder that can display received messages on the console
or an interactive map on an embedded web-server. It can also act as a network
hub for Mode S messages.

This version supports the ADALM Pluto and Open Street Map.

This tool was originally developed for an RTLSDR device. It has been updated by
'jocover' <jiangwei0402@gmail.com> to be compatible with the ADALM Pluto
(PlutoSDR).

The main features are:

* Robust decoding of weak messages, with dump1090 many users observed
  improved range compared to other popular decoders.
* Network support: TCP 30003 stream (MSG5...), Raw packets, HTTP.
* Embedded port HTTP server that displays the currently detected aircraft 
  on Open Street Map. (port 8080)
* Single bit errors correction using the 24 bit CRC.
* Ability to decode DF11, DF17 messages.
* Ability to decode DF formats like DF0, DF4, DF5, DF16, DF20 and DF21
  where the checksum is XORed with the ICAO address by brute forcing the
  checksum field using recently seen ICAO addresses.
* Decode raw I/Q samples from file (using `--ifile` command line switch).
* Interactive command-line-interface mode where aircraft currently detected
  are shown as a list refreshing as more data arrives.
* CPR coordinates decoding and track calculation from velocity.
* TCP server streaming and receiving raw data to/from connected clients
  (using `--net`).

This is purposefully a minimalist tool intended as a proof-of-concept of an
application running on a PlutoSDR.


Installation
---

To use the included automated build tool requires the installation of Docker.

    git clone https://github.com/vk6flab/dump1090.git
    cd dump1090/tools
    ./build.sh

This will use Docker to create a cross-compiled binary called dump1090 and copy 
it to a device called 'pluto.local'. (root@pluto.local:/root/dump1090)

Note that you should check that the firmware version on your PlutoSDR is the same
as the version in the Dockerfile and update either. (Firmware v0.31) Each Analog
firmware release also includes a matching systemroot. See the Analog Pluto
[firmware releases](https://github.com/analogdevicesinc/plutosdr-fw/releases/)
for details.

It can also be compiled without Docker (as long as all the pre-requisites are 
installed) by typing:

    make

Warning
===

This tool has the ability to provide networking services. The PlutoSDR can be
connected to your local network to access these services. The PlutoSDR is both
an embedded Linux device and an RF transmitter. For these reasons you should 
**never _ever_ connect the PlutoSDR directly to the internet**.

The **root** password for any PlutoSDR is **analog**.

Note that transmitting outside your licensed frequencies can attract heavy
fines and criminal prosecution in most jurisdictions across the globe.

_You've been warned._


Normal usage
---

To capture traffic directly from your device and show the captured traffic
on standard output, run the program without options:

    ./dump1090

To output hexadecimal messages:

    ./dump1090 --raw

To run the program in interactive mode:

    ./dump1090 --interactive

To run the program with an embedded web-server and networking support:

    ./dump1090 --net

To combine both interactive and networking modes:

    ./dump1090 --interactive --net

In interactive mode it is possible to have a less information dense but more
"arcade style" output, where the screen is refreshed every second displaying
all the recently seen aircraft with some additional information such as
altitude and flight number, extracted from the received Mode S packets.

In networking mode, you can connect to the PlutoSDR with your web browser and
see currently heard aircraft on an Open Street Map. Point your browser at: 
http://pluto.local:8080/ (See below for other network options.)


Using files as source of data
---

To decode data from file, use:

    ./dump1090 --ifile /path/to/binfile

The binary file can be created using `rtl_sdr` like this (or with any other
program that is able to output 8-bit unsigned I/Q samples at 2 MHz sample rate).

    rtl_sdr -f 1090000000 -s 2000000 -g 50 output.bin

In the example `rtl_sdr` a gain of 50 is used. You should use the highest
gain available for your tuner. This is not needed when calling Dump1090 itself
as it is able to select the highest gain supported automatically.

It is possible to feed the program with data via standard input using
the `--ifile` option with `-` as argument.


Additional options
---

Dump1090 can be called with other command line options to set a different
gain, frequency, and so forth. For a list of options use:

    ./dump1090 --help

Everything not documented here should be obvious, and for most users calling
it without arguments at all is the best thing to do.

```text
# ./dump1090.bin --help
--gain <db>              Set gain (default: auto-gain. Use -100 for auto-gain).
--enable-agc             Enable the Automatic Gain Control (default: on).
--freq <hz>              Set frequency (default: 1090 Mhz).
--ifile <filename>       Read data from file (use '-' for stdin).
--interactive            Interactive mode refreshing data on screen.
--interactive-rows <num> Max number of rows in interactive mode (default: 15).
--interactive-ttl <sec>  Remove from list if idle for <sec> (default: 60).
--raw                    Show only messages hex values.
--net                    Enable networking.
--net-only               Enable just networking, no RTL device or file used.
--net-ro-port <port>     TCP listening port for raw output (default: 30002).
--net-ri-port <port>     TCP listening port for raw input (default: 30001).
--net-http-port <port>   HTTP server port (default: 8080).
--net-sbs-port <port>    TCP listening port for BaseStation format output (default: 30003).
--no-fix                 Disable single-bits error correction using CRC.
--no-crc-check           Disable messages with broken CRC (discouraged).
--aggressive             More CPU for more messages (two bits fixes, ...).
--stats                  With --ifile print stats at exit. No other output.
--onlyaddr               Show only ICAO addresses (testing purposes).
--metric                 Use metric units (meters, km/h, ...).
--snip <level>           Strip IQ file removing samples < level.
--debug <flags>          Debug mode (verbose), see README for details.
--help                   Show this help.

Debug mode flags: d = Log frames decoded with errors
                  D = Log frames decoded with zero errors
                  c = Log frames with bad CRC
                  C = Log frames with good CRC
                  p = Log frames with bad preamble
                  n = Log network debugging info
                  j = Log frames to frames.js, loadable by debug.html.
```


Reliability
---

By default Dump1090 tries to fix single bit errors using the checksum.
Basically the program will try to flip every bit of the message and check if
the checksum of the resulting message matches.

This is indeed able to fix errors and works reliably in most cases,
however if you are interested in very reliable data you can use the `--no-fix`
command line switch in order to disable error fixing.


Performances and sensibility of detection
---

Dump1090 was able to decode a large number of messages even in conditions where
other programs encountered problems, however no formal test was performed so
there is no claim that this program is better or worse compared to other similar 
programs.


Network server features
===

By enabling the networking support with `--net` Dump1090 starts listening
for clients connections on port 30002 and 30001 (you can change both the
ports if you want, see `--help` output).


Port 30002
---

Connected clients are served with data ASAP as they arrive from the device
(or from file if `--ifile` is used) in the raw format similar to the following:

    *8D451E8B99019699C00B0A81F36E;

Every entry is separated by a simple newline (LF character, hex 0x0A).


Port 30001
---

Port 30001 is the raw input port, and can be used to feed Dump1090 with
data in the same format as specified above, with hex messages starting with
a `*` and ending with a `;` character.

So for instance if there is another remote Dump1090 instance collecting data
it is possible to sum the output to a local Dump1090 instance doing something
like this:

    nc remote-dump1090.example.net 30002 | nc localhost 30001

It is important to note that what is received via port 30001 is also
broadcast to clients listening to port 30002.

In general everything received from port 30001 is handled exactly as the
normal traffic from the receiver or from file when `--ifile` is used.

It is possible to use Dump1090 just as an hub using `--ifile` with /dev/zero
as argument as in the following example:

    ./dump1090 --net-only

Or alternatively to see what's happening on the screen:

    ./dump1090 --net-only --interactive

Then you can feed it from different data sources from the internet.


Port 30003
---

Connected clients are served with messages in SBS1 (BaseStation) format,
similar to:

    MSG,4,,,738065,,,,,,,,420,179,,,0,,0,0,0,0
    MSG,3,,,738065,,,,,,,35000,,,34.81609,34.07810,,,0,0,0,0

This can be used to feed data to various sharing sites without the need to use another decoder.


Port 8080
---

An embedded web-server serves a landing page that loads an Open Street Map which
displays aircraft within range of the receiver. The data is served as a JSON file
from http://pluto.local:8080/data.json.

The embedded map uses leaflet.js to retrieve and render OSM data.

You can change the port number with `--net-http-port`


Antenna
---

Mode S messages are transmitted in the 1090 MHz frequency. If you have a decent
antenna you'll be able to pick up signals from aircraft pretty far from your
position, especially if you are outdoor and in a position with a good sky view.

You can easily build a very cheap antenna following the instructions at:

* http://antirez.com/news/46

This trivial antenna was able to pick up signals of aircraft 200+ km away.

If you are interested in a more serious antenna check the following
resources:

* http://gnuradio.org/data/grcon11/06-foster-adsb.pdf
* http://www.lll.lu/~edward/edward/adsb/antenna/ADSBantenna.html
* http://modesbeast.com/pix/adsb-ant-drawing.gif


Aggressive mode
---

With `--aggressive` it is possible to activate the *aggressive mode* that is a
modified version of the Mode S packet detection and decoding.
The aggressive mode uses more CPU usually (especially if there are many planes
sending DF17 packets), but can detect a few more messages.

The algorithm in aggressive mode is modified in the following ways:

* Up to two demodulation errors are tolerated (adjacent entries in the magnitude
  vector with the same eight). Normally only messages without errors are
  checked.
* It tries to fix DF17 messages trying every two bits combination.

The use of aggressive mode is only advised in places where there is low traffic
in order to have a chance to capture some more messages.


Debug mode
---

The Debug mode is a visual help to improve the detection algorithm or to
understand why the program is not working for a given input.

In this mode messages are displayed in an ASCII-art style graphical
representation, where the individual magnitude bars sampled at 2 MHz are
displayed.

An index shows the sample number, where 0 is the sample where the first
Mode S peak was found. Some additional background noise is also added
before the first peak to provide some context.

To enable debug mode and check what combinations of packets you can
log, use `dump1090 --help` to obtain a list of available debug flags.

Debug mode includes an optional Javascript output that is used to visualise
packets using a web browser, you can use the file debug.html under the
'tools' directory to load the generated 'frames.js' file.


How does this program work?
---

The code is documented and written in order to be easy to understand. For the
diligent programmer with a Mode S specification it should be trivial to 
understand how it works.

The algorithms used were obtained by looking at many messages as displayed using
a throwaway SDL program, and trying to model the algorithm
based on how the messages look graphically.


How to test the program?
---

If you have a PlutoSDR device and you happen to be in an area where there
are aircraft flying over your head, just run the program and check for signals.

However if you don't have a PlutoSDR device, or if in your area the presence
of aircraft is very limited, you may want to try the sample file distributed
with the Dump1090 distribution under the 'testfiles' directory.

Just run it like this:

    ./dump1090 --ifile testfiles/modes1.bin


What is --strip mode?
---

It is just a simple filter that will get raw I/Q 8 bit samples in input
and will output a file missing all the parts of the file where I and Q
are lower than the specified \<level\> for more than 32 samples.

Use it like this:

    cat big.bin | ./dump1090 --snip 25 > small.bin

It was used to create a small test file included inside this source code
distribution.


Credits
---

Dump1090 was written by Salvatore Sanfilippo <antirez@gmail.com> and is
released under the BSD three clause license.

Commits have been made by:

Alan McCullagh <tyrower@kiffduskiff.com>\
Frederik De Bleser <frederik@debleser.be>\
Jon Williams <jonathan.williams@gmail.com>\
Karel Heyse <karel.heyse@gmail.com>\
Kemal Hadimli <kemal@vnil.la>\
Michael Weber <michael@xmw.de>\
Onno Benschop <cq@vk6flab.com>\
Skip Tavakkolian <skip.tavakkolian@gmail.com>\
Steve Markgraf <steve@steve-m.de>\
Steven Kreuzer <skreuzer@FreeBSD.org>\
Yuval Adam <_@yuv.al>\
Yuval Adam <yuval@y3xz.com>\
Salvatore Sanfilippo <antirez@gmail.com>\
jocover <jiangwei0402@gmail.com>

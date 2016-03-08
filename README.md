# Wireshark Statsd Protocol Dissector

This is a wireshark protocol dissector for the statsd protocol written in lua.

## Usage

    wireshark -X lua_script:/path/to/statsd_dissector.lua

or

    tshark -X lua_script:/path/to/statsd_dissector.lua -r capture.pcap

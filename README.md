# Q68NTP
An NTP client for the Q68

More of a demo on how to write network clients in assembly than an actual program - But it's still useful!

Adapt to your likings (NTP server address and your UTC time offset in seconds) at the end.

Minimal functionality: Simply asks the time server for the time, retrieves it and sets the internal clock (NOT the RTC!), ignoring all sub-seconds.

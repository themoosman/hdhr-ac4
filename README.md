# hdhr-ac4 v1.6.0

This is a fork of [johnb-7/hdhr-ac4](https://github.com/johnb-7/hdhr-ac4), with some simplification and a much smaller image.

## Description

>This project aims to emulate an HDHomerun tuner that supplies ATSC 3.0 programs with AC3 audio.

## About

>This project started as a way for me to support ATSC 3.0 programs on my home netowrk. I already have an HDHR5-4k tuner and thought the transition would be straight forward when ATSC 3.0 programs went live in Atlanta. The signal and video quality were much better, but the AC4 audio every program was using was supported by nothing I owned.

>This application pretends to be an HDHomerun device that offers ATSC 3.0 programs. When a request comes in to tune one of the programs, it forwards that request to a real HDHomerun device and passes the resulting stream back to the original requester after converting the AC4 audio stream to AC3 audio.

## Why?

>This allows my HDHR5-4K to serve ATSC 3.0 programs to my Emby server(now native support?) and PLEX server with Live TV and DVR functionality. Converting audio to AC3 before the server receives it allows everything to work as it always has with HDHomerun tuners.

## Configuration 
>Set in docker environent
>>- HDHR_IP - REQUIRED. The IP address of your real HDHomerun device
>>- DEVICEID_SWAP - OPTIONAL (1 or 0, default 1) If the Device of the HDHomerun you are connecting to should be reversed. This ensures you have a unique DeviceID to prevent any collision with your physical HDHomerun device.

>### hd_home_run.py
>>Contains the ffmpeg command:
```
[
    "/bin/usr/ffmpeg",
    "-nostats",
    "-hide_banner",
    "-loglevel",
    "warning",
    "-i",
    "pipe:",
    "-c:a",
    "ac3",
    "-c:v",
    "copy",
    "-f",
    "mpegts",
    "-",
]
```
>>This should not need to be changed, but can be modified if the ATSC 3.0 streams needs specifi ffmpeg handling.

## Build Image
>Example Containerfile build command:

>`podman build -f Containerfile -t hdhr-ac4 .`

>This build uses ffmpeg binary from Emby. The Emby team has a custom version of ffmpeg tha has several improvements over the original ffmpeg branch. 
>A quick explanation for the image build that is based on Debian Bookworm, Python 3.12 (Slim Version):
>1. The ffmpeg container extracts Emby installer
>2. The final container copies in ffmpeg binaries. A few python modules are added and the two python files are copied over and the launch command is set.

## Run Container
>Example container run command:

>`podman run --name hdhr-ac4 --rm -p 8080:8080 -p 5004:5004 -e HDHR_IP=10.1.1.2 hdhr-ac4`

>You can use any host port you want for port 80 (8080 in the example), but port 5004 can't be changed.
>The HDHomerun API being implemented is here: https://info.hdhomerun.com/info/http_api 

>The container runs HTTP servers on port 8080 and 5004 and supports the following HTTP requests:
>>- http://HOST:8080/ - returns info and version about hdhr-ac4 docker
>>- http://HOST:8080/discover.json - returns the same response as the real HDHomerun device, but substitutes the hdhr-ac4 IP address in the appropriate locations.
>>- http://HOST:8080/lineup.json - queries the real HDHomerun device for its service list and then does the following:
>>>1. replaces all the IP addresses with the hdhr-ac4 IP address
>>>2. replaces the ATSC3=1 entry with AudioCodec=AC3
>>>3. strips out all non ATSC3 programs
>>- http://HOST:5004/auto/{program} - forwards the request to the real HDHomerun device, and then pipes the stream through ffmpeg and then back to the orignal requester
>>- http://HOST:8080/lineup_status.json - returns the same response as the real HDHomerun device

## Notes
>- Please report issues or send pull requests here: https://github.com/themoosman/hdhr-ac4
>- Channel changes are a little slower due to the extra step
>- VLC was used a lot in the early testing. Example URL for host 192.168.1.1 with program 111.1: http://192.168.1.1:5004/auto/v111.1
>- The development container (Containerfile-dev) is very similar but does not automatically launch the application and can be mounted using your editor of choice for debugging the Python application or ffmpeg. It also installs some extra software specifically for development.
>- Many thanks to the Emby team for the ffmpeg with working AC4. Since its open source software, there should not be any problems here.

## TODO
>-Make official release on ghcr

## License
>This project is release under the Apache 2.0 license

#FROM ubuntu:22.04 AS base
FROM python:3.12-slim AS base

WORKDIR /home

RUN apt-get -yqq update && \
    apt-get install -yq --no-install-recommends curl binutils xz-utils ca-certificates expat libgomp1 && \
    apt-get autoremove -y && \
    apt-get clean -y

# Extract ffmpeg from Emby installer (change file name as needed)
# https://emby.media/linux-server.html add in repo directory
FROM base as ffmpeg
RUN curl -L -o emby.deb https://github.com/MediaBrowser/Emby.Releases/releases/download/4.8.10.0/emby-server-deb_4.8.10.0_amd64.deb
RUN ar x emby.deb data.tar.xz && \
    tar xf data.tar.xz


# Setup python and copy over ffmpeg
FROM base AS final

WORKDIR /home

#RUN apt-get install -y python3 pip libfontconfig
#RUN apt-get install -y python3-pip libfontconfig
RUN apt-get install -y libfontconfig
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY *.py ./

COPY --from=ffmpeg /home/opt/emby-server/bin/ffmpeg /usr/bin/ffmpeg
COPY --from=ffmpeg /home/opt/emby-server/lib/libav*.so.* /usr/lib/
COPY --from=ffmpeg /home/opt/emby-server/lib/libpostproc.so.* /usr/lib/
COPY --from=ffmpeg /home/opt/emby-server/lib/libsw* /usr/lib/
COPY --from=ffmpeg /home/opt/emby-server/extra/lib/libva*.so.* /usr/lib/
COPY --from=ffmpeg /home/opt/emby-server/extra/lib/libdrm.so.* /usr/lib/
COPY --from=ffmpeg /home/opt/emby-server/extra/lib/libmfx.so.* /usr/lib/
COPY --from=ffmpeg /home/opt/emby-server/extra/lib/libOpenCL.so.* /usr/lib/

CMD ["/bin/bash", "-c", "uvicorn main:app --host 0.0.0.0 --port 8080 --workers 2 & uvicorn main:tune --host 0.0.0.0 --port 5004 --workers 4"]

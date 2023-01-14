FROM        ubuntu:20.04 AS base

WORKDIR     /home

RUN     apt-get -yqq update && \
    apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 && \
    apt-get autoremove -y && \
    apt-get clean -y

# Extract ffmpeg from Emby installer (change file name as needed)
# https://emby.media/linux-server.html add in repo directory
FROM base as ffmpeg
RUN apt-get install -y binutils xz-utils
COPY emby-server-deb_4.8.0.21_amd64.deb ./
RUN ar x emby-server-deb_4.8.0.21_amd64.deb data.tar.xz && \
    tar xf data.tar.xz

# Setup python and copy over ffmpeg
FROM base AS final

WORKDIR /home

RUN apt-get install -y python3 pip libfontconfig curl
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

CMD [ "python3", "./main.py" ]

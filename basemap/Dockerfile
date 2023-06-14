FROM debian:stable-slim

# postgresql-client is required to use psql from Makefile
RUN apt-get update && apt-get -y install wget gnupg2
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt-get install libssl-dev openssl make cmake g++ \
    && wget https://www.python.org/ftp/python/2.7.5/Python-2.7.5.tgz \
    && tar xzvf Python-2.7.5.tgz \
    && cd Python-2.7.5 \
    && ./configure \
    && make \
    && make install

# install osm2pgsql dependencies
RUN apt-get update && apt-get install -y pigz postgresql-client-14 aria2 gdal-bin golang python-is-python3 2to3 awscli git \
  libboost-dev libboost-system-dev \
  libboost-filesystem-dev libexpat1-dev zlib1g-dev \
  libbz2-dev libpq-dev libproj-dev lua5.3 liblua5.3-dev pandoc npm

# build and install osm2pgsql
RUN git clone https://github.com/openstreetmap/osm2pgsql.git \
    && mkdir osm2pgsql/build \
    && cd osm2pgsql/build \
    && cmake .. \
    && make \
    && make install

COPY osm2pgsql_styles /osm2pgsql_styles
COPY scripts /scripts
COPY sprite /sprite
COPY styles /styles
COPY tile_generator /tile_generator
COPY Makefile /Makefile
COPY start.sh /start.sh
COPY .psqlrc /.psqlrc

RUN chmod +x /start.sh

CMD [ "/start.sh" ]

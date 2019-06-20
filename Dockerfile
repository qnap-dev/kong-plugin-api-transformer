FROM debian

RUN apt-get update

RUN apt-get install -y \
  vim \
  lua5.1 \
  liblua5.1-dev \
  luarocks \
  git \
  libssl1.0-dev \
  m4 \
  make

ADD Makefile .
RUN make setup

ADD kong-plugin-api-transformer-*.rockspec .

ENV LUA_PATH="/api-transformer/?.lua;;"

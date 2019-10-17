FROM erlang:latest

WORKDIR /tmp
RUN curl https://sh.rustup.rs -sSf > rust_install.sh && chmod +x rust_install.sh && ./rust_install.sh -y
RUN ~/.cargo/bin/cargo install --git https://github.com/dsprenkels/sss-cli

ENV LD_LIBRARY_PATH /usr/local/lib
RUN apt-get update
RUN apt-get install -y autoconf automake libtool flex bison libgmp-dev cmake build-essential emacs libssl-dev

RUN git clone -b stable https://github.com/jedisct1/libsodium.git
RUN cd libsodium && ./configure --prefix=/usr && make check && make install && cd ..

RUN mkdir -p /opt/key-sharding
WORKDIR /opt/key-sharding

ADD rebar.config rebar.config
RUN rebar3 get-deps
RUN rebar3 compile

ADD src/ src/
RUN rebar3 compile
RUN rebar3 release

ADD run.sh run.sh
RUN chmod +x run.sh

CMD ["/bin/bash"]
FROM alpine:latest

ADD bin/kid /kid

ADD entrypoint.sh /entrypoint.sh

RUN apk --update add ca-certificates

RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2

CMD ["/entrypoint.sh"]

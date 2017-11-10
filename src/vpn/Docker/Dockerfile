FROM ubuntu:16.04

RUN echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.4.list \
    && echo "deb http://repo.pritunl.com/stable/apt xenial main" > /etc/apt/sources.list.d/pritunl.list \
    && echo "deb http://build.openvpn.net/debian/openvpn/stable xenial main" > /etc/apt/sources.list.d/openvpn-aptrepo.list \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 0C49F3730359A14518585931BC711F9BA15703C6 \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 8E6DA8B4E158C569 \
    && apt-get update -q \
    && apt-get install locales \
    && locale-gen en_US en_US.UTF-8 \
    && dpkg-reconfigure locales \
    && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && apt-get upgrade -y -q \
    && apt-get dist-upgrade -y -q \
    && apt-get -y install pritunl mongodb-org iptables \
    && apt-get clean \
    && apt-get -y -q autoclean \
    && apt-get -y -q autoremove \
    && rm -rf /tmp/*

ADD start-pritunl /bin/start-pritunl

EXPOSE 80
EXPOSE 443
EXPOSE 1194
EXPOSE 1194/udp

ENTRYPOINT ["/bin/start-pritunl"]

CMD ["/usr/bin/tail", "-f","/var/log/pritunl.log"]

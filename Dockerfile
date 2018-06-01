FROM ruby:2.5-alpine

RUN \
  echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
  apk --no-cache add \
  nmap \
  msmtp \
  confd@testing

ADD files/etc/confd /etc/confd
ADD files/usr/local/bin/scan_server.rb /usr/local/bin/scan_server.rb

ENTRYPOINT ["/usr/local/bin/scan_server.rb"]

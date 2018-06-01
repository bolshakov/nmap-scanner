FROM ruby:2.5-alpine

RUN \
  echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
  apk --no-cache add \
  nmap \
  msmtp \
  confd@testing

ADD files/etc/confd /etc/confd
ADD files/usr/local/bin/docker_entrypoint.rb /usr/local/bin/docker_entrypoint.rb

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.rb"]

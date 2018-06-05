FROM ruby:2.5-alpine

RUN apk --no-cache add nmap && gem install 'mail' --version '=2.7.0'

ADD files/docker_entrypoint.rb /usr/local/bin/docker_entrypoint.rb

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.rb"]

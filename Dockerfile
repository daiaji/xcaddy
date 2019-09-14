#
# Builder
#

FROM ubuntu:latest as builder

ARG plugins="git,cors,realip,expires,cache,cloudflare"

RUN apt-get update \
&& apt-get install \		
git \
musl-dev \
g++ \
gcc \
libc6-dev \
make \
pkg-config \
curl \
golang \
-y \
&& curl -fsSL https://getcaddy.com | bash -s personal ${plugins} \
&& go get -v github.com/abiosoft/parent

#
# Final stage
#
FROM alpine
LABEL maintainer "Abiola Ibrahim <abiola89@gmail.com>"

# Let's Encrypt Agreement
ENV ACME_AGREE="false"

RUN apk add --no-cache \

    ca-certificates \

    git \

    mailcap \

    openssh-client \

    tzdata \
    libcap

# install caddy
COPY --from=builder /usr/local/bin/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

EXPOSE 80 443 2015
RUN setcap 'cap_net_bind_service=+ep' /usr/bin/caddy
VOLUME /root/.caddy /srv
#WORKDIR /caddy/www

COPY Caddyfile /etc/Caddyfile
#COPY index.html /srv/index.html

# install process wrapper
COPY --from=builder /root/go/bin/parent /bin/parent

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE", "-quic"]

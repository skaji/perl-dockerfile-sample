FROM buildpack-deps:bullseye as deps

ADD https://github.com/skaji/perl-dockerfile-sample/releases/download/v0.0.1/perl.tar.gz /opt/
RUN set -eux; \
  cd /opt; \
  tar xf perl.tar.gz; \
  :

# If you use some XS modules, and they will be linked to some shared objects,
# you may want to install libXXX-dev APT packages here.
#
# **NOTE**
# buildpack-deps:bullseye already have libssl-dev package,
# so you do not need to install libssl-dev for Net::SSLeay
#
# RUN set -eux; \
#   apt-get update; \
#   apt-get install -y --no-install-recommends libxml2-dev; \
#   :

COPY cpanfile /app/cpanfile
RUN set -eux; \
  curl -fsSL -o /tmp/cpm https://git.io/cpm
  export PATH=/opt/perl/bin:$PATH; \
  cd /app; \
  perl /tmp/cpm install --show-build-log-on-failure; \
  :

ARG TINI_VERSION=v0.19.0
RUN set -eux; \
  curl -fsSL -o /sbin/tini https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini-amd64; \
  chmod +x /sbin/tini; \
  :


FROM debian:bullseye

# If you use some XS modules, and they are linked to some shared objects,
# you may want to install libXXX APT packages here.
#
# **NOTE**
# debian:bullseye already have libssl.so.1.1;
# so you do not need to install libssl for Net::SSLeay
#
# RUN set -eux; \
#   apt-get update; \
#   apt-get install -y --no-install-recommends libxml2; \
#   rm -rf /var/lib/apt/lists/*; \
#   :

# If you want to change timezone (say Asia/Tokyo), then:
#
# RUN set -eux; \
#   echo Asia/Tokyo > /etc/timezone; \
#   rm -f /etc/localtime; \
#   dpkg-reconfigure -f noninteractive tzdata; \
#   :

COPY --from=deps /opt/perl /opt/perl
COPY --from=deps /sbin/tini /sbin/tini
COPY --from=deps /app/local /app/local
COPY app.psgi /app/app.psgi
COPY lib /app/lib

WORKDIR /app
EXPOSE 8080
ENV PATH /app/local/bin:/opt/perl/bin:$PATH
ENV PERL5LIB /app/lib:/app/local/lib/perl5

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["plackup", "--server", "Starlet", "--port", "8080", "app.psgi"]

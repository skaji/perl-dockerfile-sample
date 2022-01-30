FROM buildpack-deps:bullseye as deps

ARG TINI_VERSION=v0.19.0

ADD https://github.com/skaji/perl-dockerfile-sample/releases/download/v0.0.1/perl.tar.gz /opt/
RUN set -eux; \
  cd /opt; \
  tar xf perl.tar.gz; \
  :

COPY cpanfile /app/cpanfile
RUN set -eux; \
  export PATH=/opt/perl/bin:$PATH; \
  cd /app; \
  curl -fsSL https://git.io/cpm | perl - install --show-build-log-on-failure; \
  :

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
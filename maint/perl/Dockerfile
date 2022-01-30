FROM buildpack-deps:bullseye

ARG PERL_VERSION=5.34.0

ADD https://www.cpan.org/src/5.0/perl-$PERL_VERSION.tar.gz perl-$PERL_VERSION.tar.gz

RUN tar xf perl-$PERL_VERSION.tar.gz

# You may want to append more configure options,
# such as -Duseshrplib, -Duseithreads, -DDEBUGGING=-g
RUN set -eux; \
  cd perl-$PERL_VERSION; \
  ./Configure \
    -des \
    -Dprefix=/opt/perl \
    -Dscriptdir=/opt/perl/bin \
    -Dman1dir=none \
    -Dman3dir=none \
  ; \
  make -j8 install; \
  :

RUN set -eux; \
  cd /opt/perl/bin; \
  rm -f perl$PERL_VERSION perlthanks; \
  ln -s perl perl$PERL_VERSION; \
  ln -s perlbug perlthanks; \
  :

RUN set -eux; \
  cd /opt; \
  tar czf /perl.tar.gz perl; \
  ls -al /perl.tar.gz

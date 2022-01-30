# perl dockerfile sample

This repository gives a sample Dockerfile for perl applications.

# Description

### (0) First, build perl once, and upload it to somewhere.

I don't think we should build perl from source code in the main Dockerfile;
instead, just build perl once, and upload it to somewhere accessible via HTTP.

In this sample, I built perl as in [maint/perl/Dockerfile](), and upload it to [GitHub Releases](https://github.com/skaji/perl-dockerfile-sample/releases/tag/v0.0.1).

```
cd maint/perl
docker build -t perl-build .
ID=$(docker create perl-build)
docker cp $ID:/perl.tar.gz .
# upload perl.tar.gz to somewhere
```

### (1) Second, install dependencies in a separate stage

To reduce the size of your final image,
we should use a separate stage to install dependencies:

```Dockerfile
FROM buildpack-deps:bullseye as deps

COPY cpanfile /app/cpanfile
RUN set -eux; \
  cd /app; \
  curl -fsSL https://git.io/cpm | perl - install --show-build-log-on-failure; \
  :
```

We here use [cpanfile]() for describing dependencies, and [cpm](https://github.com/skaji/cpm) for installing dependencies.

### (2) Copy necessary files to the "final" stage

```
FROM debian:bullseye

COPY --from=deps /opt/perl /opt/perl
COPY --from=deps /sbin/tini /sbin/tini
COPY --from=deps /app/local /app/local
COPY app.psgi /app/app.psgi
COPY lib /app/lib
```

We here use `debian:bullseye` for base image.

### (3) Set up environment variables, especially `PATH` and `PERL5LIB`

We have installed the dependencies into `/app/local`,
so we should append the directory to `@INC`:

```
ENV PATH /app/local/bin:/opt/perl/bin:$PATH
ENV PERL5LIB /app/lib:/app/local/lib/perl5
```

### (4) Set ENTRYPOINT and CMD for your applications

```
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["plackup", "--server", "Starlet", "--port", "8080", "app.psgi"]
```

We here use [tini](https://github.com/krallin/tini) for `ENTRYPOINT`.

Note that, if you use `--init` option for `docker run`,
then docker automatically use `tini`.
So it doesn't seem that we need to set `tini` by ourselves
OTOH, in some situation, such as kubernetes,
we cannot rely on `docker run --init` option,
so I think we should set `tini` as `ENTRYPOINT` explicitly.

# Try it

The image built by [Dockerfile]() is uploaded to [ghcr.io](https://github.com/skaji/perl-dockerfile-sample/pkgs/container/perl-dockerfile-sample).
So you can easily try it on your local machine:

```
❯ docker run -p 8080:8080 ghcr.io/skaji/perl-dockerfile-sample:v0.0.2
Plack::Handler::Starlet: Accepting connections at http://0:8080/

❯ curl http://localhost:8080
Hello world!
```

# Discussion

* [dockerfile_best-practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
covers recommended best practices and methods for building efficient images.
* I didn't use `USER` to change to a non-root user. I'm not sure it is worth doing so.
* If you want to reduce the size of your image more, then you can try
[alpine](https://hub.docker.com/_/alpine) or
[distroless](https://github.com/GoogleContainerTools/distroless).
* Leave your comment on [Discussions](https://github.com/skaji/perl-dockerfile-sample/discussions)!

# Author

Shoichi Kaji

# License

The same as Perl

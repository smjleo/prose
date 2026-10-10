# syntax=docker/dockerfile:1
FROM debian:bookworm-slim@sha256:7c7b2c966bc9ee8cedfeef67e0e279108992c77681fa595db4a9d65c06ccc587 AS builder

ARG BUILD_JOBS=2
ARG OPAM_REPOSITORY=b0f29298c11859482484f6237c75de5d6d4682a7

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    MPLBACKEND=Agg \
    MPLCONFIGDIR=/tmp/matplotlib \
    OPAMROOT=/opt/opam \
    OPAMYES=1 \
    OPAMJOBS=${BUILD_JOBS} \
    PATH=/home/artifact/.local/bin:/opt/ghc/9.6.7/bin:/opt/opam/5.2.0/bin:/opt/prism/bin:${PATH}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash build-essential bzip2 ca-certificates curl git m4 patch pkg-config \
       rsync unzip xz-utils zsh time \
       libffi-dev libgmp-dev libncurses-dev libnuma-dev zlib1g-dev \
       openjdk-17-jre-headless \
       python3 python3-matplotlib python3-numpy python3-pandas python3-scipy \
       fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/date /usr/local/bin/gdate

COPY docker/install-tools.sh /tmp/install-tools.sh
RUN sh /tmp/install-tools.sh && rm /tmp/install-tools.sh

RUN groupadd --gid 1000 artifact \
    && useradd --uid 1000 --gid artifact --create-home --shell /bin/bash artifact \
    && mkdir -p /opt/opam /opt/opam-repository /opt/artifact \
    && curl -fsSL --retry 3 \
       "https://github.com/ocaml/opam-repository/archive/${OPAM_REPOSITORY}.tar.gz" \
       -o /tmp/opam-repository.tar.gz \
    && tar -xzf /tmp/opam-repository.tar.gz --strip-components=1 -C /opt/opam-repository \
    && rm /tmp/opam-repository.tar.gz \
    && chown -R artifact:artifact /opt/opam /opt/artifact

USER artifact
ENV HOME=/home/artifact

RUN opam init --bare --disable-sandboxing --no-setup default /opt/opam-repository \
    && opam switch create 5.2.0 ocaml-base-compiler.5.2.0 \
    && opam install dune.3.23.1 menhir.20260209 \
       core.v0.17.2 core_unix.v0.17.1 ppx_jane.v0.17.0

WORKDIR /opt/artifact
COPY --chown=artifact:artifact LICENSE ./
COPY --chown=artifact:artifact promt/ promt/
COPY --chown=artifact:artifact prose/ prose/

# PROMT's dependencies are bundled with GHC; no Hackage index is needed.
RUN mkdir -p /home/artifact/.config/cabal \
    && touch /home/artifact/.config/cabal/config \
    && cd promt \
    && printf 'constraints: containers == 0.6.7\n' > cabal.project.local \
    && cabal build exe:promt --offline

RUN cd prose && opam exec -- dune build bin/main.exe

RUN mkdir -p /home/artifact/.local/bin \
    && ln -s /usr/bin/timeout /home/artifact/.local/bin/gtimeout \
    && ln -s "$(cd promt && cabal list-bin exe:promt)" /home/artifact/.local/bin/promt \
    && ln -s /opt/artifact/prose/_build/default/bin/main.exe /home/artifact/.local/bin/prose

# Wrapper and documentation edits can reuse the compiled tools.
COPY --chown=artifact:artifact . .

RUN { \
      printf 'opam repository: %s\n' "${OPAM_REPOSITORY}"; \
      ghc --version; ghc-pkg list; cabal --version; opam --version; ocamlc -version; dune --version; \
      prism -version; java -version 2>&1; python3 --version; \
      opam list --installed; dpkg-query -W; \
    } > /opt/artifact/toolchain.txt \
    && sh docker/check.sh

RUN mkdir -p /home/artifact/runtime-bin \
    && install -m 755 "$(cd promt && cabal list-bin exe:promt)" /home/artifact/runtime-bin/promt \
    && install -m 755 prose/_build/default/bin/main.exe /home/artifact/runtime-bin/prose \
    && strip /home/artifact/runtime-bin/promt /home/artifact/runtime-bin/prose

CMD ["bash"]

# The default image contains the compiled tools, source, and runtime dependencies.
FROM debian:bookworm-slim@sha256:7c7b2c966bc9ee8cedfeef67e0e279108992c77681fa595db4a9d65c06ccc587 AS runtime

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    MPLBACKEND=Agg \
    MPLCONFIGDIR=/tmp/matplotlib \
    PATH=/opt/prism/bin:${PATH}

# Munkres satisfies fonttools without SciPy's compiler dependencies.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash coreutils mawk ca-certificates \
       libgmp10 libffi8 libnuma1 libncurses6 libtinfo6 zlib1g libgomp1 libstdc++6 \
       openjdk-17-jre-headless \
       python3 python3-munkres python3-matplotlib python3-numpy python3-pandas \
       fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/date /usr/local/bin/gdate \
    && ln -s /usr/bin/timeout /usr/local/bin/gtimeout \
    && groupadd --gid 1000 artifact \
    && useradd --uid 1000 --gid artifact --create-home --shell /bin/bash artifact

COPY --from=builder /home/artifact/runtime-bin/ /usr/local/bin/
COPY --from=builder /opt/prism/ /opt/prism/
COPY --from=builder /opt/prism-source.tar.gz /opt/prism-source.tar.gz
COPY --chown=artifact:artifact . /opt/artifact/
COPY --from=builder /opt/artifact/toolchain.txt /opt/artifact/toolchain.txt
RUN chmod 755 /opt/artifact/artifact.py /opt/artifact/benchmark.py \
    /opt/artifact/compare-session-types.sh

USER artifact
ENV HOME=/home/artifact
WORKDIR /opt/artifact
RUN dpkg-query -W > runtime-packages.txt && sh docker/check.sh

CMD ["bash"]

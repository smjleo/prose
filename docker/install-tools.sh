#!/bin/sh
set -eu

# SHA256 values from official manifests and release assets.
case "$(dpkg --print-architecture)" in
    amd64)
        ghc_archive=ghc-9.6.7-x86_64-deb11-linux.tar.xz
        ghc_sha=fc6a6247d1831745c67b27d6212f6911c35a933043f3b6851724e2e01484d077
        cabal_archive=cabal-install-3.12.1.0-x86_64-linux-deb12.tar.xz
        cabal_sha=05ae13d0e1cfc5e8da524d1b62a0932dc5869a3a91e5c60eb232865da38c81bd
        opam_binary=opam-2.5.2-x86_64-linux
        opam_sha=edfca2630c373b44b7ee1c2f81cd8dcf67468d0db57d6c02158de553ac63dbd4
        prism_archive=prism-4.10.1-linux64-x86.tar.gz
        prism_sha=9f2135b1d49293cdc9b16b1756a24f99beff320b78134825c1f477f43942ab17
        ;;
    arm64)
        ghc_archive=ghc-9.6.7-aarch64-deb10-linux.tar.xz
        ghc_sha=3cfa843687856de304a946dbe849a497c4fdad021f0275628b8ca7b55ccf8082
        cabal_archive=cabal-install-3.12.1.0-aarch64-linux-deb12.tar.xz
        cabal_sha=98ea64386f354869264c0c1cfca9eb041c5fa2c9e272d7ac6bc9c49f798967fe
        opam_binary=opam-2.5.2-arm64-linux
        opam_sha=c4106ece84bcb60c68342573d2d6b4f0d6770ee088015c2216adc83d8854dcf9
        prism_archive=prism-4.10.1-linux64-arm.tar.gz
        prism_sha=cebe4a34f6cf5037d136782dd7c826bffc15ac675739283b7c9b605d2b50bd47
        ;;
    *) echo 'Supported architectures: amd64 and arm64' >&2; exit 1 ;;
esac

tool_tmp=$(mktemp -d)
trap 'rm -rf "$tool_tmp"' EXIT HUP INT TERM
cd "$tool_tmp"

fetch() {
    curl -fsSL --retry 3 "$1" -o "$2"
    printf '%s  %s\n' "$3" "$2" | sha256sum -c -
}

fetch "https://downloads.haskell.org/ghc/9.6.7/$ghc_archive" ghc.tar.xz "$ghc_sha"
mkdir ghc
tar -xJf ghc.tar.xz --strip-components=1 -C ghc
(cd ghc && ./configure --prefix=/opt/ghc/9.6.7 && make install)

fetch "https://downloads.haskell.org/~cabal/cabal-install-3.12.1.0/$cabal_archive" cabal.tar.xz "$cabal_sha"
mkdir cabal
tar -xJf cabal.tar.xz -C cabal
install -m 755 cabal/cabal /usr/local/bin/cabal

fetch "https://github.com/ocaml/opam/releases/download/2.5.2/$opam_binary" opam "$opam_sha"
install -m 755 opam /usr/local/bin/opam

fetch "https://github.com/prismmodelchecker/prism/releases/download/v4.10.1/$prism_archive" prism.tar.gz "$prism_sha"
mkdir -p /opt/prism
tar -xzf prism.tar.gz --strip-components=1 -C /opt/prism
(cd /opt/prism && ./install.sh)

# Retain the corresponding PRISM source distribution alongside its binaries.
fetch 'https://github.com/prismmodelchecker/prism/releases/download/v4.10.1/prism-4.10.1-src.tar.gz' \
    /opt/prism-source.tar.gz dc8f3e4e31fd7b2f2a77ac1607dddcfd07bbd0887faeb8c2e0a7b55d42670097

ghc --version
cabal --version
opam --version
prism -version

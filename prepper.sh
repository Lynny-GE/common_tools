#!/bin/bash

set -e

rm -rf ${HOME}/Downloads
mkdir -p ${HOME}/Downloads
cd ${HOME}/Downloads

# Make a new Python and put it first in your $PATH
wget https://www.python.org/ftp/python/2.7.13/Python-2.7.13.tar.xz
tar xf Python-2.7.13.tar.xz
find . -type d | xargs chmod 0755
pushd Python-2.7.13
mkdir -p ${HOME}/python
./configure --prefix=${HOME}/python
make
make install
popd
export PATH=${HOME}/python/bin:$PATH

wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py

pip install Pyyaml
pip install awscli

ar_tar() {
	rm -f data.tar.* control.tar.*
	ar x $1
	tar xf data.tar.* --directory $HOME
	rm -f $1
}

# Get suitable versions of the CF CLI, psql, tmux, and the libraries they
# depend on.
# Glossary of Mystery Arguments(R) to wget
# -q == quiet
# -nd == save to current directory rather than creating a hierarchy
# -l1 == descend only one directory down
# -r == recurse
# -A == pattern to accept.  Make sure these patterns are specific enough.
wget -q -O cf.cli.deb "https://cli.run.pivotal.io/stable?release=debian64"
wget -q -nd -l1 -r -A 'libpq5_9.5*pgdg15.10+1_amd64.deb' http://apt.postgresql.org/pub/repos/apt/pool/main/p/postgresql-9.5/
wget -q -nd -l1 -r -A 'postgresql-client*pgdg14.04+1_amd64.deb' http://apt.postgresql.org/pub/repos/apt/pool/main/p/postgresql-9.5/
wget -q -nd -l1 -r -A 'libevent-2.0*14.04.2*amd64.deb' http://mirrors.kernel.org/ubuntu/pool/main/libe/libevent/
wget -q -nd -l1 -r -A 'tmux_1.8*amd64.deb' http://mirrors.kernel.org/ubuntu/pool/main/t/tmux/

for deb in ./*.deb ; do
	ar_tar $deb
done

# Set things up so psql will be functional.
export LD_LIBRARY_PATH="${HOME}/usr/lib/x86_64-linux-gnu/:${LD_LIBRARY_PATH}"
export PATH="${HOME}/usr/bin:${HOME}/usr/lib/postgresql/9.5/bin:${PATH}"

# jq, for all your JSON queries
wget -q -O ${HOME}/usr/bin/jq "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64"
chmod +x ${HOME}/usr/bin/jq

# y2j, for querying YAML with jq
wget https://github.com/wildducktheories/y2j/archive/master.tar.gz
tar xf master.tar.gz --strip-components=1 -C ${HOME}/usr/bin

# Go, without which none of this would actually work
LATEST=$(git ls-remote --tags https://github.com/golang/go.git | sort -r -t '/' -k 3 | egrep -v '(beta|rc)' |egrep -o '\bgo.*' |head -n 1)
wget -q -O golang.tgz "https://storage.googleapis.com/golang/${LATEST}.linux-amd64.tar.gz"
mkdir -p ${HOME}/usr/local
tar xf golang.tgz --directory ${HOME}/usr/local

export GOROOT="${HOME}/usr/local/go/"
export PATH="$PATH:$GOROOT/bin"

cat <<EOT > $HOME/.bash_profile
export GOROOT=$GOROOT
export HISTCONTROL=ignoreboth
export HISTFILESIZE=10000000
export HISTSIZE=1000000
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH
export PATH=$PATH
EOT

cd $HOME
rm -rf Downloads
gotty -w bash

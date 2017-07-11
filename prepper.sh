#!/bin/bash
# We always want .env.sh sourced before anything else if it exists
echo '[ -r ${HOME}/.env.sh ] && source ${HOME}/.env.sh' >> .bashrc.tmp

mkdir ~/Downloads
cd ~/Downloads

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
    rm data.tar.*
    ar x $1
    tar xf data.tar.* --directory $HOME
}
export PATH="${HOME}/usr/bin:${PATH}"

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
wget -q http://mirrors.kernel.org/ubuntu/pool/main/libe/libevent/libevent-2.0-5_2.0.21-stable-2_amd64.deb
wget -q http://mirrors.kernel.org/ubuntu/pool/main/t/tmux/tmux_1.8-5_amd64.deb

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

# Install perl, DBD and sqitch if necessary
export LYNNY="${HOME}/src/github.build.ge.com/Lynny/Lynny-Whitebox"
if [ -e ${LYNNY}/db ]; then
    echo "Installing sqitch"
    wget -O - https://install.perlbrew.pl | bash
    echo 'source ~/perl5/perlbrew/etc/bashrc' >> .bashrc.tmp
    source ~/perl5/perlbrew/etc/bashrc
    perlbrew install-cpanm
    cpanm install App::Sqitch DBD::Pg
    echo export PATH="$PATH:$HOME/perl5/bin" >> ${HOME}/.env.sh
    echo export PERL5LIB=$HOME/perl5/lib/perl5 >> ${HOME}/.env.sh
else
    echo "Skipping sqitch install (no db directory in $LYNNY)"
fi

export GOROOT="${HOME}/usr/local/go/"
export PATH="$PATH:$GOROOT/bin"

cd ${HOME}
rm -rf ~/Downloads

tar xf src.tgz

export GOPATH=${HOME}

y2j -r -f ${HOME}/getenv.jq < ${HOME}/lynny-wb-dev-manifest.yml > ${HOME}/.env.sh
source ${HOME}/.env.sh
egrep '^export' $0 >> ${HOME}/.env.sh

# These are here just to ensure they make it into .env.sh. Note that they're
# just pulled out via grep, so they can't do anything fancy.
export USER="`cat username.txt``cat cf_target.txt`"
export DB_USER="$USER_test" # We over-ride this because in the most common case we're doing testing...
export PGPASSFILE=$HOME/.pgpass
export PGSSLMODE=require

# Why do we want this? export HISTCONTROL=ignoreboth
export HISTFILESIZE=10000000
export HISTSIZE=1000000

# Copy some variables to standard PG variables
echo 'source ~/.pg.env' >> ${HOME}/.env.sh

cd ${HOME}
tar zxf src.tgz

# Other scripts use .bashrc as an indicator that prepper is done, so do this last
mv .bashrc.tmp .bashrc

[ "$1" != "-n" ] && ./test.sh

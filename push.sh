#!/bin/sh

set -e

mydir=`dirname $0`
mydir=`cd $mydir; pwd`

# TODO: CF_TARGET is a horrible name for what this is actually doing :(
workspace=${LYNNY_WB_WORKSPACE:-${HOME}/${CF_TARGET:-dev}}
lynny=${LYNNY:-${workspace}/src/github.build.ge.com/Lynny/Lynny-Whitebox}
secret=${LYNNY_SECRET:-${workspace}/Lynny-Whitebox-Secrets}
dev_manifest=${DEV_MANIFEST:-${secret}/deployments/cf3/manifest.cf3-devel.yml}

error() {
    echo $@ 1>&2
}
die() {
    rc=$1
    shift
    error $@
    exit $rc
}

[ -d "$lynny" ] || die 2 "LYNNY directory '$lynny' does not exist"
cd $lynny
gitbranch=`git symbolic-ref --short HEAD`
[ $? -eq 0 ] || die 3

cd $mydir
echo "Updating branch.txt"
echo $gitbranch > branch.txt
echo "Copying manifest"
cp $dev_manifest lynny-wb-dev-manifest.yml || die 3 "Unable to copy dev manifest"

echo "Creating tar of git branch $gitbranch"
# TODO: tarring this full path is a bad idea since you can pick up other random stuff
tar jcf src.tgz --exclude=.git --exclude=mocks --directory=$workspace src/

echo $USER>username.txt
if [ -z "$CF_TARGET" ]; then
    echo '' > cf_target.txt
else
    # We want a dash to magically show up in what prepper.sh does
    echo "-$CF_TARGET" > cf_target.txt
fi

echo "Pushing to cloud foundry using options $@"

if [ -z "$@" ]; then
    cf push "${CF_TARGET:-dev}-${USER}"
else
    cf push $@
fi

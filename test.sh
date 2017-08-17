#!/usr/bin/env bash
# This NEEDS to be bash, otherwise the source command won't work

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  source $HOME/env.sh
fi

cd ${HOME}/src/github.build.ge.com/Lynny/Lynny-Whitebox

## If needed, recreate the per-developer test database
# TODO: test to see if DB exists or not...
# ./build_db.sh

# Create a fake commit so that build.sh does not fail when it's extracting the commit-id
git init
git -c "user.name=none" -c "user.email=none" commit --allow-empty -m wip

# Since this session might disconnect while tests are running, start `tmux` and
# execute the tests in a new session. After a disconnection, use the `tmux a`
# command to reconnect to this session.
#
# Note that on tmux session termination, all the output emitted by the command
# is lost. So we inject an infinite loop at the end to give us an opportunity to
# reconnect to the session and inspect and/or save the command output.

# Run the integration tests
if [ -d bin ]; then
  script_dir=bin
elif [ -d scripts ]; then
  script_dir=scripts
else
  echo "unable to find test script" >&2
  exit 1
fi

test_script="$script_dir/integration_tests.sh"

tmux new-session "$test_script 2>&1 | tee -a ~/test.log; echo Results available in ~/test.log. Sleeping until cancelled; while sleep 1; do :; done"

# vi: expandtab sw=2 ts=2

#!/bin/sh

Testoutput=.testoutput

RC=0

executeTest() {
  local experr=$1
  shift;

  echo "Executing $*"
  ( echo ; echo "Running $*" ) >> $Testoutput

  if $experr
  then
    if $* >> $Testoutput 2>&1
    then
      echo "Unexpected success from $*"
      RC=1
    fi
  else
    if ! $* >> $Testoutput 2>&1
    then
      echo "Unexpected failure from $*"
      RC=1
    fi
  fi
}

die() {
  echo "*** " $* " --- bailing out"
  exit 1
}

if [ -f $Testoutput ]
then rm -f $Testoutput || die "Failed to remove existing log file $Testoutput"
fi

trap "rm -f $Testoutput" EXIT

executeTest false q runtests.q test_runtests_empty.q -q
executeTest true  q runtests.q test_runtests_noload.q -q
executeTest true  q runtests.q test_runtests_notestlist.q -q
executeTest true  q runtests.q test_runtests_crash.q -q
executeTest true  q runtests.q test_runtests_two.q -q

if ! cmp expected_testresults $Testoutput > /dev/null
then
  echo
  echo "The actual test output does not match expectations"
  diff expected_testresults $Testoutput
  RC=1
fi

exit $RC
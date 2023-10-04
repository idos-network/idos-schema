#! /bin/bash
set -ueo pipefail

ENVIRONMENT="$1"
REMOTE_FILE="$2"
LOCAL_FILE="$3"

CONNECTION_STRING=$(PRODUCT=idos PROJECT=kwil frctls ssh $ENVIRONMENT echo 2>&1 | grep '^# Running' | sed 's|^# Running ssh ||' | sed 's| echo$||')

scp $CONNECTION_STRING:$REMOTE_FILE $LOCAL_FILE

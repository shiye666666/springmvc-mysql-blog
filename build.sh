#!/bin/bash

set -eu
Prompt(){
	echo "[$(date '+%D %H:%M:%S')] $@"
}

WORKSPACE=$(cd $(dirname $0); pwd)
Prompt "Work dir: $WORKSPACE"

cd $WORKSPACE

export LANG="en_US.UTF-8"

Prompt "Setting up environment variables OK..."


OUTPUT=$WORKSPACE/target/blog-1.0.0-BUILD-SNAPSHOT/output

Prompt "Clean and Package"
mvn clean -U package -Dmaven.test.skip=true || exit $?

Prompt "Package for deploy"
rm -fr $WORKSPACE/output
mv $OUTPUT ./

mkdir $WORKSPACE/output/opbin

Prompt "Generate version and timestamp..."
echo $(date -d  today +%Y%m%d%H%M%S) > $WORKSPACE/output/version
git log | head -1 | awk '{print $2}' >> $WORKSPACE/output/version
Prompt "version::"`cat $WORKSPACE/output/version`

Prompt "download jdk"
curl http://172.22.132.84/hawkeye-deps/jdk-8u111-linux-x64.tar.gz > $WORKSPACE/output/jdk-8u111-linux-x64.tar.gz


Prompt "build finish exit:"$?

exit $?

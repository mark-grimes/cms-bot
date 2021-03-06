#!/bin/sh -x
TARGET=$1
WORKER_USER=${2-cmsbuild}
WORKER_DIR=${3-/build1/cmsbuild}
JENKINS_MASTER_ROOT=/build/cmsbuild/jenkins


kinit $WORKER_USER@CERN.CH -k -t /build/cmsbuild/jenkins/$WORKER_USER.keytab
aklog
klist
SSH_OPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ServerAliveInterval=60"
ssh -f $SSH_OPTS $TARGET mkdir -p $WORKSPACE
ssh -f $SSH_OPTS $TARGET mkdir -p $WORKER_DIR
ssh -f $SSH_OPTS $TARGET ls -la $WORKER_DIR
ssh -f $SSH_OPTS $TARGET curl -k -o$WORKER_DIR/slave.jar https://cmssdt.cern.ch/SDT/slave.jar
scp -p $SSH_OPTS /build/cmsbuild/jenkins/$WORKER_USER.keytab $TARGET:$WORKER_DIR/$WORKER_USER.keytab
scp -p $SSH_OPTS /var/lib/jenkins/cmsos $TARGET:$WORKER_DIR/cmsos
HOST_ARCH=`ssh -f $SSH_OPTS $TARGET cat /proc/cpuinfo | grep vendor_id | sed 's|.*: *||' | tail -1`
HOST_CMS_ARCH=`ssh -f $SSH_OPTS $TARGET sh $WORKER_DIR/cmsos`
WORKER_JENKINS_NAME=`echo $TARGET | sed s'|.*@||;s|\..*||'`
java -jar /var/lib/jenkins/jenkins-cli.jar -s http://localhost:8080/jenkins groovy /var/lib/jenkins/add-cpu-labels.groovy "$WORKER_JENKINS_NAME" "$HOST_ARCH" "$HOST_CMS_ARCH"
sleep 1
ssh $SSH_OPTS $TARGET k5start -U -f $WORKER_DIR/$WORKER_USER.keytab -K 10 -l 10h  -- java -jar $WORKER_DIR/slave.jar -jar-cache /tmp/

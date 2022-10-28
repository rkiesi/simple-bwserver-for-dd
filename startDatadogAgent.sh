#!/usr/bin/bash
source ./dd-agent.conf

# check if we have a stoped dd-agent container
if [[ $(docker container ls --filter "status=exited" --filter "ancestor=gcr.io/datadoghq/agent:7" | wc -l) > 1 ]]
then
  echo "[INFO] Removing stoppped dd-agent container"
  docker rm dd-agent
fi
echo "DONE"
exit 1
# starting dd-agent container on localhost docker
# agent on docker container gets read only access to
# - docker demon:         -v /var/run/docker.sock:/var/run/docker.sock:ro
#                         -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
# - host proc filesystem: -v /proc/:/host/proc/:ro
# - app metrics realy:    -p 8126:8126/tcp
# dd-agent is starting to report to DD cloud servers on metrics for the local server,
# docker infrastructure and any app connected to it.
echo "[INFO] Starting a new dd-agent container"
docker run -d \
 --name dd-agent \
 --rm \
 -v /var/run/docker.sock:/var/run/docker.sock:ro \
 -v /proc/:/host/proc/:ro \
 -v /opt/datadog-agent/run:/opt/datadog-agent/run:rw \
 -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
 -p 8125:8125/udp \
 -p 8126:8126/tcp \
 -e DD_API_KEY=${DATADOG_API_KEY} \
 -e DD_SITE=${DATADOG_SITE} \
 -e DD_LOGS_ENABLED=true \
 -e DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL=true \
 gcr.io/datadoghq/agent:7

echo "[INFO] waiting for dd-agent container initialization"
sleep 3
if (( $(netstat -tulpn 2> /dev/null | grep 8126 | wc -l) == 0 ))
then
  echo "[ERROR] Datadog agent container is not running or port is not reachable"
  exit 1
fi
echo "[INFO] dd-agent container is ready!"
exit 0
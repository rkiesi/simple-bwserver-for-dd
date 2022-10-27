#!/usr/bin/bash
# terminating and deleting dd-agent container on local docker

if [ $(docker container ls --filter "status=running" --filter "ancestor=gcr.io/datadoghq/agent:7" | wc -l) > 1  ]
then
  echo "[INFO] stopping dd-agent container"
  docker stop dd-agent
fi

if [ $(docker container ls --filter "status=exited" --filter "ancestor=gcr.io/datadoghq/agent:7" | wc -l) > 1  ]
then
  echo "[INFO] deleting dd-agent container"
  docker rm dd-agent
fi

exit 0
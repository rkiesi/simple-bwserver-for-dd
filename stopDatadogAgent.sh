#!/usr/bin/bash
# terminating and deleting dd-agent container on local docker
docker stop dd-agent
docker rm dd-agent

exit 0
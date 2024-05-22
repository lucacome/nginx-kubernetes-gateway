#!/usr/bin/env bash

set -eo pipefail

source scripts/vars.env

NGF_DIR=$(dirname "$PWD")/
NGF_REPO=${NGF_REPO:-nginxinc}

gcloud compute config-ssh --ssh-config-file ngf-gcp.ssh >/dev/null

if [ -n "${NGF_REPO}" ] && [ "${NGF_REPO}" != "nginxinc" ]; then
    gcloud compute ssh --zone "${GKE_CLUSTER_ZONE}" --project="${GKE_PROJECT}" username@"${RESOURCE_NAME}" \
        --command="bash -i <<EOF
rm -rf nginx-gateway-fabric
git clone https://github.com/${NGF_REPO}/nginx-gateway-fabric.git
EOF" -- -t
fi

rsync -ave 'ssh -F ngf-gcp.ssh' "${NGF_DIR}" username@"${RESOURCE_NAME}"."${GKE_CLUSTER_ZONE}"."${GKE_PROJECT}":~/nginx-gateway-fabric

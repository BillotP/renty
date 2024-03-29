#!/usr/bin/env bash
# exit when any command fails
set -e
docker build -t repo.treescale.com/dave-lopeur/kubebeber/inception . 
docker push repo.treescale.com/dave-lopeur/kubebeber/inception
k3s kubectl delete deployment inception || true
k3s kubectl apply -f deployment.yaml
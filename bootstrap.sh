#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="todo-kind"
CHART_DIR=".infrastructure/helm-chart/todoapp"
NAMESPACE="todoapp"
RELEASE_NAME="todoapp"

echo ">>> 1) Create kind cluster"
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  kind create cluster --name "${CLUSTER_NAME}" --config cluster.yml
else
  echo "Kind cluster ${CLUSTER_NAME} already exists, skipping..."
fi

echo ">>> 2) Ensure kubectl context"
kubectl cluster-info

echo ">>> 3) Inspect nodes for labels/taints"
kubectl get nodes --show-labels

echo ">>> 4) Taint nodes labeled app=mysql with app=mysql:NoSchedule"
MYSQL_NODES=$(kubectl get nodes -l app=mysql -o name || true)
if [ -n "${MYSQL_NODES}" ]; then
  for n in ${MYSQL_NODES}; do
    kubectl taint "${n}" app=mysql:NoSchedule --overwrite || true
  done
else
  echo "No nodes labeled app=mysql found."
fi

echo ">>> 5) Helm dependency update"
helm dependency update "${CHART_DIR}"

echo ">>> 6) Install/upgrade Helm release"
helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --create-namespace

echo ">>> 7) Wait for deployment"
kubectl -n "${NAMESPACE}" rollout status deploy/${RELEASE_NAME}-deployment --timeout=180s || true

echo ">>> 8) Collect output"
kubectl get all,cm,secret,ing -A -o wide | tee output.log
echo "Done."

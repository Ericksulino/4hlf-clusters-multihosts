cat > swarm_warmup.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

NET="${1:-first-network}"
shift || true

if [[ "$#" -lt 1 ]]; then
  echo "Uso: $0 <network> <node.hostname> [node.hostname...]"
  echo "Ex:  $0 first-network ip-172-31-38-66 ip-172-31-43-175"
  exit 1
fi

for NODE in "$@"; do
  SVC="net-warmup-${NODE}"

  echo "==> Criando warmup no nó: $NODE (service: $SVC)"

  # remove se já existir
  sudo docker service rm "$SVC" >/dev/null 2>&1 || true

  sudo docker service create --name "$SVC" \
    --constraint "node.hostname==${NODE}" \
    --network "$NET" \
    --restart-condition any \
    alpine:3.19 sleep 1d

done

echo "OK. Verifique com: sudo docker service ls && sudo docker service ps <service>"
EOF

chmod +x swarm_warmup.sh

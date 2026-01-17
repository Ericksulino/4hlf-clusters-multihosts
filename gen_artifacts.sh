#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(cd "$(dirname "$0")" && pwd)"

docker run --rm \
  -v "$WORKDIR":/work \
  -w /work \
  -e FABRIC_CFG_PATH=/work \
  hyperledger/fabric-tools:2.5 \
  configtxgen -profile SampleMultiNodeEtcdRaft \
    -channelID system-channel \
    -outputBlock ./channel-artifacts/genesis.block

docker run --rm \
  -v "$WORKDIR":/work \
  -w /work \
  -e FABRIC_CFG_PATH=/work \
  hyperledger/fabric-tools:2.5 \
  configtxgen -profile TwoOrgsChannel \
    -channelID mychannel \
    -outputCreateChannelTx ./channel-artifacts/channel.tx

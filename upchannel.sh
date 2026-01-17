#!/usr/bin/env bash
set -euo pipefail

CHANNEL_NAME="mychannel"
ORDERER_ADDR="orderer.example.com:7050"
BLOCK_FILE="./channel-artifacts/${CHANNEL_NAME}.block"
CHANNEL_TX="./channel-artifacts/channel.tx"
ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

# --- Create channel (gera o bloco) ---
docker exec cli peer channel create \
  -o "${ORDERER_ADDR}" \
  -c "${CHANNEL_NAME}" \
  -f "${CHANNEL_TX}" \
  -b "${BLOCK_FILE}" \
  --tls --cafile "${ORDERER_CA}"

sleep 5

# --- Join: Org1 peer0 (default do container cli, mas usando bloco correto) ---
docker exec cli peer channel join -b "${BLOCK_FILE}"

# --- Join: Org1 peer1 ---
docker exec \
  -e CORE_PEER_ADDRESS=peer1.org1.example.com:8051 \
  -e CORE_PEER_LOCALMSPID="Org1MSP" \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt \
  cli peer channel join -b "${BLOCK_FILE}"

# --- Join: Org2 peer0 ---
docker exec \
  -e CORE_PEER_LOCALMSPID="Org2MSP" \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  cli peer channel join -b "${BLOCK_FILE}"

# --- Join: Org2 peer1 ---
docker exec \
  -e CORE_PEER_LOCALMSPID="Org2MSP" \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  -e CORE_PEER_ADDRESS=peer1.org2.example.com:10051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt \
  cli peer channel join -b "${BLOCK_FILE}"

# --- Update anchors: Org1 (rodando como Org1 admin; use peer0 ou peer1, tanto faz) ---
docker exec \
  -e CORE_PEER_LOCALMSPID="Org1MSP" \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  cli peer channel update \
    -o "${ORDERER_ADDR}" \
    -c "${CHANNEL_NAME}" \
    -f ./channel-artifacts/Org1MSPanchors.tx \
    --tls --cafile "${ORDERER_CA}"

# --- Update anchors: Org2 ---
docker exec \
  -e CORE_PEER_LOCALMSPID="Org2MSP" \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  cli peer channel update \
    -o "${ORDERER_ADDR}" \
    -c "${CHANNEL_NAME}" \
    -f ./channel-artifacts/Org2MSPanchors.tx \
    --tls --cafile "${ORDERER_CA}"

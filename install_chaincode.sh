#!/bin/bash
#
# Script de automação da instalação do Chaincode "Asset Transfer Basic"
# em ambiente Hyperledger Fabric (Org1 e Org2)
# Autor: Erick (baseado em Fabric Samples)
#

set -euo pipefail

# === Definições de variáveis ===
CC_NAME="basic"
CC_LABEL="basic"
CC_VERSION="1"
CC_SEQUENCE="1"
CC_LANG="golang"
CC_PATH="/opt/gopath/src/github.com/chaincode/asset-transfer-basic/chaincode-go"
CC_PACKAGE="${CC_NAME}.tar.gz"
CHANNEL_NAME="mychannel"
ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

echo "===================================================="
echo " 🚀 Iniciando implantação do chaincode '${CC_NAME}'"
echo "===================================================="

# === Etapa 6.1 - Copiar o chaincode para o container CLI ===
echo "==> Copiando chaincode para o container CLI..."
if [ -d "../asset-transfer-basic" ]; then
  docker cp ../asset-transfer-basic/ cli:/opt/gopath/src/github.com/chaincode/
else
  echo "❌ Diretório 'asset-transfer-basic' não encontrado! Execute o script no diretório fabric-samples."
  exit 1
fi

# === Etapa 6.2 - Empacotando chaincode ===
echo "==> Etapa 1: Empacotando chaincode..."
docker exec cli peer lifecycle chaincode package ${CC_PACKAGE} \
  --path ${CC_PATH} --label ${CC_LABEL}
echo "✔ Chaincode empacotado: ${CC_PACKAGE}"

# === Etapa 6.3 - Instalando chaincode em todos os peers ===
echo "==> Etapa 2: Instalando chaincode em peer0.org1..."
docker exec cli peer lifecycle chaincode install ${CC_PACKAGE}

echo "==> Instalando em peer1.org1..."
docker exec \
  -e CORE_PEER_ADDRESS=peer1.org1.example.com:8051 \
  -e CORE_PEER_LOCALMSPID="Org1MSP" \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt \
  cli peer lifecycle chaincode install ${CC_PACKAGE}

echo "==> Instalando em peer0.org2..."
docker exec \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
  -e CORE_PEER_LOCALMSPID="Org2MSP" \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  cli peer lifecycle chaincode install ${CC_PACKAGE}

# === Etapa 6.4 - Obter o Package ID ===
echo "==> Etapa 3: Coletando Package ID..."
PACKAGE_ID=$(docker exec cli peer lifecycle chaincode queryinstalled | grep "${CC_LABEL}" | head -n 1 | awk -F 'Package ID: ' '{print $2}' | awk -F ', Label:' '{print $1}')
if [ -z "$PACKAGE_ID" ]; then
  echo "❌ ERRO: Não foi possível obter o Package ID. Verifique se o chaincode foi instalado corretamente."
  exit 1
fi
echo "✔ Package ID obtido: ${PACKAGE_ID}"

# === Aprovação Org1 ===
echo "==> Etapa 4: Aprovando chaincode para Org1..."
docker exec \
  -e CORE_PEER_LOCALMSPID="Org1MSP" \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli peer lifecycle chaincode approveformyorg \
  --tls --cafile ${ORDERER_CA} \
  --channelID ${CHANNEL_NAME} \
  --name ${CC_NAME} \
  --version ${CC_VERSION} \
  --sequence ${CC_SEQUENCE} \
  --waitForEvent \
  --package-id ${PACKAGE_ID}
echo "✔ Org1 aprovou o chaincode."

# === Aprovação Org2 ===
echo "==> Aprovando chaincode para Org2..."
docker exec \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
  -e CORE_PEER_LOCALMSPID="Org2MSP" \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  cli peer lifecycle chaincode approveformyorg \
  --tls --cafile ${ORDERER_CA} \
  --channelID ${CHANNEL_NAME} \
  --name ${CC_NAME} \
  --version ${CC_VERSION} \
  --sequence ${CC_SEQUENCE} \
  --waitForEvent \
  --package-id ${PACKAGE_ID}
echo "✔ Org2 aprovou o chaincode."

# === Checar readiness ===
echo "==> Etapa 5: Verificando aprovações..."
docker exec cli peer lifecycle chaincode checkcommitreadiness \
  --channelID ${CHANNEL_NAME} \
  --name ${CC_NAME} \
  --version ${CC_VERSION} \
  --sequence ${CC_SEQUENCE} \
  --output json

# === Etapa 6: Commit chaincode ===
echo "==> Etapa 6: Commitando o chaincode..."
docker exec cli peer lifecycle chaincode commit \
  -o orderer.example.com:7050 \
  --tls --cafile ${ORDERER_CA} \
  --peerAddresses peer0.org1.example.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  --peerAddresses peer0.org2.example.com:9051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  --channelID ${CHANNEL_NAME} \
  --name ${CC_NAME} \
  --version ${CC_VERSION} \
  --sequence ${CC_SEQUENCE}

# === Verificar commit ===
echo "==> Etapa 7: Verificando commit..."
docker exec cli peer lifecycle chaincode querycommitted \
  --channelID ${CHANNEL_NAME} \
  --name ${CC_NAME}

echo "===================================================="
echo " ✅ Chaincode '${CC_NAME}' instalado, aprovado e commitado com sucesso!"
echo "===================================================="

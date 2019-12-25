#!/bin/bash

set -exu

CERT_EXPIRATION_PERIOD=365
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
DST_DIR=$1
PKI_DIR="$DST_DIR/pki"
CSR_CFG_FILE=$(mktemp)

trap "rm -f $CSR_CFG_FILE" SIGINT SIGTERM EXIT

cat << EOF > $CSR_CFG_FILE
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[ dn ]
O=system:masters
CN=kubernetes-admin

[ v3_ext ]
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
EOF

function die
{
    echo "ERROR: $1"
    exit 1
}

function genCA
{
    local dir=$1
    local svc=$2
    local period=$3

    mkdir -p $dir
    openssl genrsa -out "$dir/$svc.key" 2048 || die "Failed to create $svc.key"
    openssl req -x509 -new -nodes -key "$dir/$svc.key" -subj "/CN=kubernetes" \
        -days $period -out "$dir/$svc.crt" || die "Failed to create $svc.crt"
}

test "$DST_DIR" = "" && die "Specify dir for certs"

test -d "$DST_DIR" || die "Dir for certs not found"

genCA "$PKI_DIR" "ca" "$CERT_EXPIRATION_PERIOD"
genCA "$PKI_DIR" "front-proxy-ca" "$CERT_EXPIRATION_PERIOD"
genCA "$PKI_DIR/etcd" "ca" "$CERT_EXPIRATION_PERIOD"
genCA "$PKI_DIR" "sa" "$CERT_EXPIRATION_PERIOD"
openssl rsa -in "$PKI_DIR/sa.key" -pubout -out "$PKI_DIR/sa.pub"

#!/bin/bash

set -xe

WORKSPACE=/root

function setup_workspace() {
  # Setup workspace directories
  mkdir -p ${WORKSPACE}/collected
  mkdir -p ${WORKSPACE}/genesis
  # Open permissions for output from Promenade
  chmod -R 777 ${WORKSPACE}/genesis
}

function install_dependencies() {
    apt -qq update
    # Install docker
    apt -y install --no-install-recommends docker.io jq nmap
}

echo "172.18.164.51 airsloop-control-1" > /etc/hosts
hostname airsloop-control-1

rm -f /etc/apt/apt.conf.d/90cloud-init-aptproxy
setup_workspace
install_dependencies

trasuremap_clone_dir=treasuremap
[ -d "$trasuremap_clone_dir" ] || git clone https://github.com/dukov/treasuremap "$trasuremap_clone_dir"
cd $trasuremap_clone_dir
rm site/airsloop/secrets/certificates/certificates.yaml

mkdir -p certs
mkdir -p bundle
mkdir -p collect

tools/airship pegleg site -r /target collect airsloop -s collect
tools/airship promenade generate-certs -o /target/certs /target/collect/*.yaml
tools/airship promenade build-all -o /target/bundle /target/collect/*.yaml /target/certs/*.yaml

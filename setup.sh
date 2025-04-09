#!/bin/bash

set -e
echo "Running"
git submodule update --init --recursive

cd lib/t1
bun install

cd contracts
bun install
bun run build
cd ../../../

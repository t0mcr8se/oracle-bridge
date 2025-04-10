#!/bin/bash

set -e
echo "Installing submodules"
git submodule update --init --recursive

echo "Installing submodule deps"
cd lib/t1
bun install

echo "Installing contract deps & building contracts"
cd contracts
bun install
bun run build
cd ../../../

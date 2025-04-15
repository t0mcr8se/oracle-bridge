#!/usr/bin/env bash

# Exit immediately if any command fails and treat unset variables as errors
set -euo pipefail

# Function to load environment variables from .env
reload_env() {
  set -o allexport
  source .env || true
  set +o allexport
}

# Initial environment load
reload_env

# Function to determine RPC URL and verification settings
get_rpc_and_verifier() {
  local script_name=$1
  local rpc_url=""
  local verifier=""
  local verifier_url=""
  local api_key_flag=""
  local private_key=""

  if [[ $script_name == *"L1"* ]]; then
    rpc_url="$T1_L1_RPC"
    verifier="etherscan"
    verifier_url="https://api-sepolia.etherscan.io/api"
    api_key_flag="--etherscan-api-key $ETHERSCAN_API_KEY" # Only needed for Etherscan
    private_key="$L1_DEPLOYER_PRIVATE_KEY"
  elif [[ $script_name == *"L2"* ]]; then
    rpc_url="$T1_L2_RPC"
    verifier="blockscout"
    verifier_url="$BLOCKSCOUT_API_URL"  # Ensure this is set in your .env
    api_key_flag=""  # Blockscout does not require an API key
    private_key="$L2_DEPLOYER_PRIVATE_KEY"
  else
    echo "ERROR: Could not determine RPC URL for script: $script_name" >&2
    exit 1
  fi

  echo "$rpc_url $verifier $verifier_url $private_key $api_key_flag"
}

# Function to execute a script with the correct RPC URL and verify it
run_script() {
  local script_path=$1
  local contract_name=$2
  local rpc_url verifier verifier_url private_key api_key_flag

  read rpc_url verifier verifier_url private_key api_key_flag < <(get_rpc_and_verifier "$contract_name")

  echo "=== Deploying $contract_name on $( [[ $verifier == "etherscan" ]] && echo 'Sepolia' || echo 'L2 Blockscout' ) ==="
  echo "=== RPC Url $rpc_url"

  # Deploy contracts
  # ADD -g 200 or so if the network is slow
  forge script "$script_path:$contract_name" --rpc-url "$rpc_url" --broadcast

  # Wait in L2 due to a forge bug to verify contracts in Blockscout
  if [[ $contract_name == *"L2"* ]]; then
    sleep 15
  fi

  # Verify contracts
  # ADD -g 200 or so if the network is slow
  forge script "$script_path:$contract_name" --rpc-url "$rpc_url" --private-key $private_key --resume --verify --verifier "$verifier" --verifier-url "$verifier_url" $api_key_flag

  echo "=== Deployment & Verification of $contract_name completed ==="

  # Wait for the .env file to be updated
  sleep 10
}

# Deploy & verify contracts
run_script script/deploy/DeployL1Consumer.s.sol DeployL1Consumer 
run_script script/deploy/DeployL2Consumer.s.sol DeployL2Consumer

forge script script/configure/ConfigureL1Consumer.s.sol --rpc-url "$T1_L1_RPC" --broadcast
forge script script/configure/ConfigureL2Consumer.s.sol --rpc-url "$T1_L2_RPC" --broadcast

#!/usr/bin/env bash
# ==============================================================================
# import_to_vault_kv.sh
# Automated import of eMudhra CAs into HashiCorp Vault KV v2 Secrets Engine
# ==============================================================================
set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-https://127.0.0.1:8200}"
export VAULT_ADDR

KV_MOUNT="${KV_MOUNT:-kv}"
BASE_SECRET_PATH="${BASE_SECRET_PATH:-infrastructure/certs/emudhra}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== HashiCorp Vault KV Import for eMudhra CAs ==="
echo "Target Vault Address: ${VAULT_ADDR}"
echo "Target KV Path: ${KV_MOUNT}/data/${BASE_SECRET_PATH}"

# Ensure client is authenticated
if ! vault token lookup >/dev/null 2>&1; then
  echo "Error: Vault token is not valid or expired."
  echo "Please authenticate to Vault (e.g., 'vault login') before running this script."
  exit 1
fi

CAS=(
  "01_EM-DV-TLS-CA-G3B"
  "02_EM-DV-TLS-CA-G3C"
  "03_EM-OV-TLS-CA-G3B"
  "04_EM-OV-TLS-CA-G3C"
  "05_EM-EV-TLS-CA-G3B"
  "06_EM-EV-TLS-CA-G3C"
  "07_EM-OV-CS-CA-G3B"
  "08_EM-OV-CS-CA-G3C"
)

for ca_id in "${CAS[@]}"; do
  payload_file="${SCRIPT_DIR}/${ca_id}/vault_kv_payload.json"
  target_path="${KV_MOUNT}/data/${BASE_SECRET_PATH}/${ca_id}"
  
  echo ""
  echo ">>> Storing [${ca_id}] -> ${target_path}"
  
  if [ ! -f "${payload_file}" ]; then
    echo "Payload file not found: ${payload_file}" >&2
    exit 1
  fi
  
  # Using vault write / put with the json payload
  vault kv put -mount="${KV_MOUNT}" "${BASE_SECRET_PATH}/${ca_id}" @"${payload_file}"
  echo "  Stored ${target_path} successfully."
done

echo ""
echo "=== All 8 eMudhra CAs successfully stored in HashiCorp Vault KV! ==="

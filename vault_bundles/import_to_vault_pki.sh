#!/usr/bin/env bash
# ==============================================================================
# import_to_vault_pki.sh
# Automated import of eMudhra CAs into HashiCorp Vault PKI Secrets Engine
# ==============================================================================
set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-https://127.0.0.1:8200}"
export VAULT_ADDR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== HashiCorp Vault PKI Import for eMudhra CAs ==="
echo "Target Vault Address: ${VAULT_ADDR}"

# Ensure client is authenticated
if ! vault token lookup >/dev/null 2>&1; then
  echo "Error: Vault token is not valid or expired."
  echo "Please authenticate to Vault (e.g., 'vault login') before running this script."
  exit 1
fi

CAS=(
  "01_EM-DV-TLS-CA-G3B:pki/emudhra/dv-g3b:eMudhra BV DV TLS CA G3B"
  "02_EM-DV-TLS-CA-G3C:pki/emudhra/dv-g3c:eMudhra Inc DV TLS CA G3C"
  "03_EM-OV-TLS-CA-G3B:pki/emudhra/ov-g3b:eMudhra BV OV TLS CA G3B"
  "04_EM-OV-TLS-CA-G3C:pki/emudhra/ov-g3c:eMudhra Inc OV TLS CA G3C"
  "05_EM-EV-TLS-CA-G3B:pki/emudhra/ev-g3b:eMudhra BV EV TLS CA G3B"
  "06_EM-EV-TLS-CA-G3C:pki/emudhra/ev-g3c:eMudhra Inc EV TLS CA G3C"
  "07_EM-OV-CS-CA-G3B:pki/emudhra/ov-cs-g3b:eMudhra BV OV Code Signing CA G3B"
  "08_EM-OV-CS-CA-G3C:pki/emudhra/ov-cs-g3c:eMudhra Inc OV Code Signing CA G3C"
)

for entry in "${CAS[@]}"; do
  IFS=":" read -r ca_id mount_path desc <<< "${entry}"
  bundle_file="${SCRIPT_DIR}/${ca_id}/vault_pki_bundle_full.pem"
  
  echo ""
  echo ">>> Processing [${ca_id}] -> mount: ${mount_path}"
  
  if [ ! -f "${bundle_file}" ]; then
    echo "Bundle file not found: ${bundle_file}" >&2
    exit 1
  fi
  
  # 1. Enable PKI secrets engine at mount path if not already mounted
  if ! vault secrets list -format=json | grep -q "\"${mount_path}/\""; then
    echo "  Mounting PKI secrets engine at ${mount_path}..."
    vault secrets enable -path="${mount_path}" -description="${desc}" pki
  else
    echo "  PKI secrets engine already mounted at ${mount_path}."
  fi
  
  # 2. Tune max lease TTL to 15 years (131400h) matching 2040 CA expiration
  echo "  Tuning max lease TTL to 131400h..."
  vault secrets tune -max-lease-ttl=131400h "${mount_path}"
  
  # 3. Import CA Certificate and Private Key bundle
  echo "  Importing CA bundle into ${mount_path}/config/ca..."
  vault write "${mount_path}/config/ca" pem_bundle=@"${bundle_file}"
  
  # 4. Configure AIA (issuing and CRL distribution points)
  echo "  Configuring AIA distribution endpoints..."
  vault write "${mount_path}/config/urls" \
    issuing_certificates="${VAULT_ADDR}/v1/${mount_path}/ca" \
    crl_distribution_points="${VAULT_ADDR}/v1/${mount_path}/crl"
    
  echo "  Successfully configured ${mount_path}!"
done

echo ""
echo "=== All 8 eMudhra CAs successfully imported into HashiCorp Vault PKI! ==="

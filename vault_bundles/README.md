# eMudhra CA Bundles for HashiCorp Vault

This directory contains verified CA certificate and private key bundles generated from `/workspace/cartographer/emudhra_certs`, structured for direct import into **HashiCorp Vault** (either the **PKI Secrets Engine** or **KV v2 Secrets Engine**).

---

## 1. CA Inventory & Cryptographic Specifications

All certificates and private keys use ECDSA Curve `secp384r1` (P-384) with SHA-384 signatures.

| CA Identifier | Common Name | Organization / Country | Key Type | Extended Key Usage | Validity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`01_EM-DV-TLS-CA-G3B`** | `EM DV TLS CA - G3B` | eMudhra BV (NL) | ECDSA `secp384r1` | Server Auth, Client Auth | 2025-04-30 to 2040-04-28 |
| **`02_EM-DV-TLS-CA-G3C`** | `EM DV TLS CA - G3C` | eMudhra Inc (US) | ECDSA `secp384r1` | Server Auth, Client Auth | 2025-04-30 to 2040-04-28 |
| **`03_EM-OV-TLS-CA-G3B`** | `EM OV TLS CA - G3B` | eMudhra BV (NL) | ECDSA `secp384r1` | Server Auth, Client Auth | 2025-04-30 to 2040-04-28 |
| **`04_EM-OV-TLS-CA-G3C`** | `EM OV TLS CA - G3C` | eMudhra Inc (US) | ECDSA `secp384r1` | Server Auth, Client Auth | 2025-04-30 to 2040-04-28 |
| **`05_EM-EV-TLS-CA-G3B`** | `EM EV TLS CA - G3B` | eMudhra BV (NL) | ECDSA `secp384r1` | Server Auth, Client Auth | 2025-04-30 to 2040-04-28 |
| **`06_EM-EV-TLS-CA-G3C`** | `EM EV TLS CA - G3C` | eMudhra Inc (US) | ECDSA `secp384r1` | Server Auth, Client Auth | 2025-04-30 to 2040-04-28 |
| **`07_EM-OV-CS-CA-G3B`** | `EM OV CS CA - G3B` | eMudhra BV (NL) | ECDSA `secp384r1` | Code Signing | 2025-04-30 to 2040-04-28 |
| **`08_EM-OV-CS-CA-G3C`** | `EM OV CS CA - G3C` | eMudhra Inc (US) | ECDSA `secp384r1` | Code Signing | 2025-04-30 to 2040-04-28 |

---

## 2. Certificate Hierarchy & Trust Chains

### A. TLS CAs (`01` through `06`)
Three-tier certificate hierarchy:
```
[Root CA] emSign ECC Root CA - G3 (Self-Signed, secp384r1)
  │   Issuer: CN=emSign ECC Root CA - G3, OU=emSign PKI, O=eMudhra Technologies Limited, C=IN
  │   Valid: 2018-02-18 to 2043-02-18
  │   File: signers/emsign_ecc_root_ca_g3.crt.pem
  │
  └── [Intermediate CA] emSign Root TLS CA - G3 (secp384r1)
        │   Issuer: CN=emSign ECC Root CA - G3
        │   Valid: 2024-07-11 to 2039-07-09
        │   File: signers/emsign_root_tls_ca_g3.crt.pem
        │
        └── [Subordinate Issuing CA] EM {DV,OV,EV} TLS CA - G3{B,C} (secp384r1)
              Issuer: CN=emSign Root TLS CA - G3
              Valid: 2025-04-30 to 2040-04-28
              Files: 01_EM-DV-TLS-CA-G3B .. 06_EM-EV-TLS-CA-G3C
```

### B. Code Signing CAs (`07` and `08`)
Two-tier certificate hierarchy:
```
[Root CA] emSign Root CS CA - G3 (Self-Signed, secp384r1)
  │   Issuer: CN=emSign Root CS CA - G3, O=eMudhra Technologies Limited, C=IN
  │   Valid: 2024-02-08 to 2049-02-07
  │   File: signers/emsign_root_cs_ca_g3.crt.pem
  │
  └── [Subordinate Issuing CA] EM OV CS CA - G3{B,C} (secp384r1)
        Issuer: CN=emSign Root CS CA - G3
        Valid: 2025-04-30 to 2040-04-28
        Files: 07_EM-OV-CS-CA-G3B, 08_EM-OV-CS-CA-G3C
```

---

## 3. Directory Layout & Bundle Contents

Under `vault_bundles/`:

```
vault_bundles/
├── <CA_ID>.bundle.pem              # Flat bundles for quick CLI consumption
├── import_to_vault_pki.sh          # Turnkey script to mount and configure Vault PKI engines
├── import_to_vault_kv.sh           # Turnkey script to store certificates/keys in Vault KV v2
└── <CA_ID>/                        # Per-CA isolated directories
    ├── private.key                 # Private key (mode 0600)
    ├── ca_cert.pem                 # CA Certificate
    ├── issuing_chain.pem           # Upstream Intermediate and/or Root certificates
    ├── full_chain.pem              # CA Certificate + Full Upstream Chain
    ├── vault_pki_bundle.pem        # Key + CA Cert + Intermediate (standard Vault PKI bundle)
    ├── vault_pki_bundle_full.pem   # Key + CA Cert + Intermediate + Root (full chain bundle)
    ├── vault_pki_import.json       # JSON payload for Vault API /config/ca endpoint
    └── vault_kv_payload.json       # JSON payload for Vault KV v2 secret storage
```

---

## 4. How to Import into HashiCorp Vault

### Option A: Automated PKI Import (Recommended)

Run the included import script:
```bash
# Ensure you are logged into Vault:
vault login

# Execute import:
/workspace/cartographer/emudhra_certs/vault_bundles/import_to_vault_pki.sh
```

### Option B: Manual PKI CLI Import (Single CA Example)

To import **01_EM-DV-TLS-CA-G3B** under `pki/emudhra/dv-g3b`:

```bash
# 1. Mount PKI engine
vault secrets enable -path=pki/emudhra/dv-g3b -description="eMudhra BV DV TLS CA G3B" pki

# 2. Tune max lease TTL to match 2040 expiration (~15 years = 131400h)
vault secrets tune -max-lease-ttl=131400h pki/emudhra/dv-g3b

# 3. Write PEM bundle
vault write pki/emudhra/dv-g3b/config/ca \
  pem_bundle=@/workspace/cartographer/emudhra_certs/vault_bundles/01_EM-DV-TLS-CA-G3B/vault_pki_bundle_full.pem

# 4. Configure AIA distribution points
vault write pki/emudhra/dv-g3b/config/urls \
  issuing_certificates="${VAULT_ADDR}/v1/pki/emudhra/dv-g3b/ca" \
  crl_distribution_points="${VAULT_ADDR}/v1/pki/emudhra/dv-g3b/crl"

# 5. Create an issuing role
vault write pki/emudhra/dv-g3b/roles/server-cert \
  allowed_domains="example.com" \
  allow_subdomains=true \
  max_ttl="720h" \
  key_type="ec" \
  key_bits=384
```

### Option C: Vault REST API Import (Direct HTTP)

```bash
curl --header "X-Vault-Token: ${VAULT_TOKEN}" \
     --request POST \
     --data @/workspace/cartographer/emudhra_certs/vault_bundles/01_EM-DV-TLS-CA-G3B/vault_pki_import.json \
     "${VAULT_ADDR}/v1/pki/emudhra/dv-g3b/config/ca"
```

### Option D: Vault KV v2 Storage

If storing as data secrets rather than an active PKI issuing engine:

```bash
vault kv put -mount=kv infrastructure/certs/emudhra/01_EM-DV-TLS-CA-G3B \
  @/workspace/cartographer/emudhra_certs/vault_bundles/01_EM-DV-TLS-CA-G3B/vault_kv_payload.json
```
Or execute `/workspace/cartographer/emudhra_certs/vault_bundles/import_to_vault_kv.sh`.

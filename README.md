# eMudhra Subordinate CA Certificates & Keys

This repository contains Subordinate Certificate Authority (CA) certificates, private keys, and public signer chains for **eMudhra** (operating under eMudhra BV and eMudhra Inc).

All certificates and private keys utilize ECDSA curve **`secp384r1`** (P-384) with SHA-384 signatures, valid through April 2040.

---

## 1. CA Inventory & Specifications

| ID | Common Name | Type | Organization / Country | Extended Key Usage (EKU) | Validity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`01`** | `EM DV TLS CA - G3B` | TLS | eMudhra BV (NL) | Server Auth, Client Auth | 2025-04-30 to 2040-04-28 |
| **`02`** | `EM DV TLS CA - G3C` | TLS | eMudhra Inc (US) | Server Auth, Client Auth | 2025-04-30 to 2040-04-28 |
| **`03`** | `EM OV TLS CA - G3B` | TLS | eMudhra BV (NL) | Server Auth, Client Auth | 2025-04-30 to 2040-04-28 |
| **`04`** | `EM OV TLS CA - G3C` | TLS | eMudhra Inc (US) | Server Auth, Client Auth | 2025-04-30 to 2040-04-28 |
| **`05`** | `EM EV TLS CA - G3B` | TLS | eMudhra BV (NL) | Server Auth, Client Auth | 2025-04-30 to 2040-04-28 |
| **`06`** | `EM EV TLS CA - G3C` | TLS | eMudhra Inc (US) | Server Auth, Client Auth | 2025-04-30 to 2040-04-28 |
| **`07`** | `EM OV CS CA - G3B` | Code Signing | eMudhra BV (NL) | Code Signing | 2025-04-30 to 2040-04-28 |
| **`08`** | `EM OV CS CA - G3C` | Code Signing | eMudhra Inc (US) | Code Signing | 2025-04-30 to 2040-04-28 |

---

## 2. Certificate Trust Hierarchy

### TLS Subordinates (`01`–`06`)
```
[Root CA] emSign ECC Root CA - G3 (Self-Signed, secp384r1)
  │   File: signers/emsign_ecc_root_ca_g3.crt.pem
  │
  └── [Intermediate CA] emSign Root TLS CA - G3 (secp384r1)
        │   File: signers/emsign_root_tls_ca_g3.crt.pem
        │
        └── [Subordinate CA] EM {DV,OV,EV} TLS CA - G3{B,C} (secp384r1)
              Files: 01_EM-DV-TLS-CA-G3B .. 06_EM-EV-TLS-CA-G3C
```

### Code Signing Subordinates (`07`–`08`)
```
[Root CA] emSign Root CS CA - G3 (Self-Signed, secp384r1)
  │   File: signers/emsign_root_cs_ca_g3.crt.pem
  │
  └── [Subordinate CA] EM OV CS CA - G3{B,C} (secp384r1)
        Files: 07_EM-OV-CS-CA-G3B, 08_EM-OV-CS-CA-G3C
```

---

## 3. HashiCorp Vault Integration

Pre-compiled bundles, API payloads, and automated mount scripts ready for HashiCorp Vault (PKI secrets engine or KV v2 secrets engine) are located in [`vault_bundles/`](vault_bundles/):

- **Turnkey Import Script:** [`vault_bundles/import_to_vault_pki.sh`](vault_bundles/import_to_vault_pki.sh) automatically mounts and tunes 8 dedicated PKI engines, configures AIA issuing and CRL endpoints, and sets up the full CA chain.
- **KV Storage Script:** [`vault_bundles/import_to_vault_kv.sh`](vault_bundles/import_to_vault_kv.sh) stores the CA assets and keys into Vault KV v2.
- **Detailed Documentation:** Refer to [`vault_bundles/README.md`](vault_bundles/README.md) for full Vault CLI and REST API import examples.

Quick Vault PKI import example:
```bash
# Mount PKI secrets engine
vault secrets enable -path=pki/emudhra/dv-g3b -description="eMudhra BV DV TLS CA G3B" pki
vault secrets tune -max-lease-ttl=131400h pki/emudhra/dv-g3b

# Import CA certificate, private key, and upstream intermediate chain in one call
vault write pki/emudhra/dv-g3b/config/ca \
  pem_bundle=@vault_bundles/01_EM-DV-TLS-CA-G3B.bundle.pem
```

---

## 4. Usage with mitmproxy

The prepared PEM bundles contain the Subordinate CA private key, Subordinate CA certificate, and the upstream intermediate CA certificate concatenated in standard PEM format. This layout is directly compatible with **mitmproxy** (`mitmproxy`, `mitmweb`, `mitmdump`) for dynamic SSL/TLS interception and certificate generation.

### A. Command Line Usage

Use the `--certs` option with `*=<bundle-path>` to use a Subordinate CA for all intercepted hostnames:

```bash
# Using Domain Validation (G3B):
mitmproxy --certs *=vault_bundles/01_EM-DV-TLS-CA-G3B.bundle.pem

# Or with mitmweb (web interface on :8081):
mitmweb --certs *=vault_bundles/01_EM-DV-TLS-CA-G3B.bundle.pem

# Or headless with mitmdump:
mitmdump --certs *=vault_bundles/01_EM-DV-TLS-CA-G3B.bundle.pem -p 8080
```

To intercept a specific domain with a specific CA:
```bash
mitmproxy --certs example.com=vault_bundles/01_EM-DV-TLS-CA-G3B.bundle.pem
```

### B. Configuration File Usage (`~/.mitmproxy/config.yaml`)

Add the bundle to your mitmproxy configuration file:

```yaml
# ~/.mitmproxy/config.yaml
certs:
  - "*=/path/to/vault_bundles/01_EM-DV-TLS-CA-G3B.bundle.pem"
listen_port: 8080
```

### C. Client Trust Anchor

When mitmproxy intercepts TLS traffic using one of the TLS bundles (`01`–`06`), it dynamically mints leaf certificates signed by the Subordinate CA and serves the Subordinate CA cert plus the intermediate `emSign Root TLS CA - G3` to the client.

For clients to trust the intercepted connection, import the root CA certificate into the client's or OS trust store:
- **Root Certificate:** `signers/emsign_ecc_root_ca_g3.crt.pem`

---

## 5. Repository Structure

```
.
├── README.md                               # Top-level documentation
├── 01_EM-DV-TLS-CA-G3B.crt.pem             # CA Certificate
├── 01_EM-DV-TLS-CA-G3B.key                 # Matching Private Key (secp384r1)
├── 01_EM-DV-TLS-CA-G3B.pub.pem             # Public Key SPKI
├── ...                                     # (02 through 08 CAs)
├── signers/                                # Upstream Root and Intermediate CAs
│   ├── emsign_ecc_root_ca_g3.crt.pem       # Root CA for TLS hierarchy
│   ├── emsign_root_tls_ca_g3.crt.pem       # Intermediate CA for TLS hierarchy
│   ├── emsign_root_cs_ca_g3.crt.pem        # Root CA for Code Signing hierarchy
│   └── sectigo_aaa_certificate_services_root.crt.pem
└── vault_bundles/                          # Production-ready HashiCorp Vault bundles
    ├── README.md                           # Vault import instructions & API guide
    ├── import_to_vault_pki.sh              # Turnkey Vault PKI mount & config script
    ├── import_to_vault_kv.sh               # Turnkey Vault KV v2 storage script
    ├── <CA_ID>.bundle.pem                  # Flat full-chain bundles (Private Key + Chain)
    └── <CA_ID>/                            # Per-CA isolated directories
```

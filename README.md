# InnovaTech Solutions - Case 2: Hybride Cloud & SOAR Infrastructure

Dit project bevat de Infrastructure as Code (OpenTofu / Terraform) configuraties voor **Case 2: InnovaTech Solutions** binnen de opleiding HBO-ICT (MA-NCA Semester 3).

Het doel van deze infrastructuur is het realiseren van een veilige, hybride cloudomgeving waarbij een on-premises filiaal/datacenter versleuteld is gekoppeld aan een AWS Cloud Hub via een IPsec Site-to-Site VPN-tunnel, ingericht volgens Zero-Trust netwerksegmentatie.

---

## 🏗️ Architectuur & Modulestructuur

De infrastructuur is volledig modulair opgebouwd in OpenTofu:

```
case2_infra/
├── versions.tf                     # OpenTofu & AWS Provider configuratie
├── variables.tf                    # Centrale variabelen (CIDR-blocks, regio's)
├── outputs.tf                      # Belangrijke outputs (VPC IDs, Gateway IPs)
├── main.tf                         # Root orchestrator
│
└── modules/
    ├── onprem_sim/                 # Simulatie On-Premises kantoor & vestiging
    │   ├── main.tf                 # On-prem VPC, Gateway, Workstations & Server subnets
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── cloud_hub/                  # AWS Transit Cloud Hub VPC
    │   ├── main.tf                 # Ingress, Observability (PLG) & SOAR Subnets + VGW
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── vpn_tunnel/                 # IPsec Site-to-Site VPN Connectie
    │   ├── main.tf                 # Customer Gateway, VPN Connection & Route propagation
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── security/                   # Zero-Trust Security & Network Access Control
        ├── main.tf                 # Security Groups met strikte least-privilege regels
        ├── variables.tf
        └── outputs.tf
```

---

## 🔒 Beveiliging & Zero-Trust Uitgangspunten

1. **Strikte Netwerksegmentatie (REQ-01 / REQ-02):** Geen plat netwerk. Werkstations in de on-premises branch hebben geen directe toegang tot centrale databases zonder tussenkomst van gecontroleerde services.
2. **Platformscheiding (REQ-03):** Het SOAR-platform en de Observability stack draaien in geïsoleerde subnets binnen de Cloud Hub VPC.
3. **Geen Geheimen in Versiebeheer:** State files (`.tfstate`), credentials en `.env` variabelen zijn strikt uitgesloten via `.gitignore`.

---

## 🚀 Uitrolinstructies

### Vereisten
* OpenTofu `v1.8+` (of Terraform `v1.5+`)
* Geconfigureerde AWS CLI credentials (`aws configure`)

### Stappen
1. **Initialiseren:**
   ```bash
   tofu init
   ```

2. **Valideren:**
   ```bash
   tofu validate
   ```

3. **Infrastructuurplan inspecteren:**
   ```bash
   tofu plan
   ```

4. **Infrastructuur uitrollen:**
   ```bash
   tofu apply
   ```

---

## 👨‍💻 Auteur & Portfolio Context
* **Auteur:** Emir Özcan
* **Opleiding:** Fontys HBO-ICT / Associate Degree — MA-NCA (Network & Cloud Automation)
* **Semester:** Semester 3 (Periode 2 - Case 2)

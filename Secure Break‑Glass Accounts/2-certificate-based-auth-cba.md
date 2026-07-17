# Certificate-Based Authentication (CBA) for Emergency Access Accounts

> **Why this matters:** When physical FIDO2 security keys are unavailable or lost, certificate-based authentication provides hardware-independent phishing-resistant access — this lab provisions self-signed certs, uploads the root CA to Entra, and enforces CBA via Authentication Strength without excluding emergency accounts from Conditional Access.

A portal-based and PowerShell-assisted lab implementing Certificate-Based Authentication as the primary phishing-resistant MFA method for emergency access accounts in Microsoft Entra ID.

Last validated on: 2026-06-22
Portal experience note: Steps validated against Microsoft Entra admin center as of June 2026; labels can vary slightly by tenant and feature rollout.

> **Note:** This lab focuses on CBA as the phishing-resistant MFA method and is independent of Lab 1. Lab 1 uses FIDO2 security keys as the primary credential; this lab uses X.509 certificates installed on secure devices. Both labs follow Microsoft's 2025 security baseline — emergency accounts are **never excluded from Conditional Access**.

---

## Module / Track Structure

```text
Secure Break‑Glass Accounts/
├── README.md                          ← Track entry point
├── 1-Secure Break‑Glass Accounts.md   ← Lab 1: Emergency Accounts + FIDO2
└── 2-certificate-based-auth-cba.md ← Lab 2: CBA (you are here)
```

---

## Quick Navigation

- [Prerequisites](#prerequisites)
- [Learning Objectives](#learning-objectives)
- [Scenario](#scenario)
- [Design Approach](#design-approach)
- [Step 1: Create Emergency Access Accounts](#step-1-create-emergency-access-accounts)
- [Step 2: Generate Certificates (Lab / Self-Signed)](#step-2-generate-certificates-lab--self-signed)
- [Step 3: Upload Root CA to Entra ID](#step-3-upload-root-ca-to-entra-id)
- [Step 4: Enable and Configure CBA](#step-4-enable-and-configure-cba)
- [Step 5: Configure Certificate User Mapping](#step-5-configure-certificate-user-mapping)
- [Step 6: Install Certificates on Secure Devices](#step-6-install-certificates-on-secure-devices)
- [Step 7: Create Authentication Strength for CBA](#step-7-create-authentication-strength-for-cba)
- [Step 8: Create Conditional Access Policy](#step-8-create-conditional-access-policy)
- [Step 9: Test CBA Authentication](#step-9-test-cba-authentication)
- [Step 10: Monitor and Alert](#step-10-monitor-and-alert)
- [Validation Checklist](#validation-checklist)
- [Recovery Runbook](#recovery-runbook)

---

## Prerequisites

| Requirement | Detail |
| --- | --- |
| Azure Role | **Global Administrator** on the target Entra ID tenant |
| Tenant Type | Cloud-only (hybrid/federated not required) |
| Device | Windows device with PowerShell for certificate generation |
| Estimated Time | 90–120 minutes |
| Tools | Entra Admin Center + PowerShell (Windows) |
| Lab 1 Dependency | None — this lab is standalone and complements Lab 1 |

### Assumptions and Scope Boundaries

- This lab uses self-signed certificates suitable for lab environments. Production deployments should use an enterprise CA or trusted public CA.
- Break-glass accounts are cloud-only with no federation or external IdP.
- CBA is configured as MFA-level authentication, not as a single factor.

---

## Learning Objectives

By the end of this lab, you will have:

- Generated a self-signed root CA and issued user certificates using PowerShell
- Uploaded the root CA to Entra ID's Certificate Authorities trust store
- Configured CBA in Microsoft Entra ID with certificate-to-user mapping
- Installed user certificates on designated secure emergency devices
- Created a custom Authentication Strength policy enforcing CBA
- Created a Conditional Access policy requiring CBA for emergency accounts (not excluding them)
- Tested successful CBA sign-in for both emergency accounts
- Configured monitoring and alerting for emergency account sign-ins

---

## Scenario

**Your organization needs hardware-independent emergency access using digital certificates.**

Phishing-resistant MFA can be delivered through:

- **FIDO2 security keys** — physical hardware tokens (Lab 1)
- **Certificate-Based Authentication** — digital certificates on secure devices (this lab)

CBA is preferred when:

- Physical FIDO2 tokens are unavailable or impractical to provision
- The organization already operates a PKI infrastructure
- Emergency devices need to be pre-provisioned with credentials
- Air-gapped or highly controlled environments restrict hardware token use

---

## Design Approach

| Element | Lab 1 (FIDO2) | Lab 2 (CBA) |
| --- | --- | --- |
| Phishing-resistant method | FIDO2 security key | X.509 certificate |
| Credential storage | Physical hardware token | Certificate store on secure device |
| Enrollment | Interactive portal registration | Certificate issuance via CA + PowerShell |
| CA dependency | None | Root CA required (self-signed for lab) |
| Entra trust store required | No | Yes — root CA must be uploaded |
| Conditional Access | Authentication Strength (FIDO2/CBA) | Authentication Strength (CBA only) |
| Emergency accounts excluded from CA | No | No |

> Both labs follow Microsoft's 2025 security baseline: break-glass accounts are **never excluded from Conditional Access**. A dedicated Authentication Strength policy enforces the required MFA method.

---

## Step 1: Create Emergency Access Accounts

### 1.1 Sign In to Microsoft Entra Admin Center

1. Navigate to **<https://entra.microsoft.com>**
2. Sign in using an account with **Global Administrator** permissions

### 1.2 Create Two Cloud-Only Emergency Accounts

1. Navigate to **Identity** → **Users** → **All users**
2. Click **+ New user** → **Create new user**
3. Create the first emergency account:
   - **User principal name:** `emergency-cba-01@tenant.onmicrosoft.com` (replace `tenant` with your actual tenant name)
   - **Display name:** `Emergency CBA Admin 01`
   - **Password:** Generate a strong, random password (16+ characters, mixed case, numbers, symbols)
   - Click **Create**
4. Repeat for the second account:
   - **User principal name:** `emergency-cba-02@tenant.onmicrosoft.com`
   - **Display name:** `Emergency CBA Admin 02`
   - Click **Create**
5. **Store both passwords securely** in a sealed envelope or offline vault

### 1.3 Assign Global Administrator Role

1. Navigate to **Roles & Administrators** → **Global Administrator**
2. Click **+ Add assignments**
3. Search for and select **Emergency CBA Admin 01**, click **Add**
4. Repeat for **Emergency CBA Admin 02**
5. **Verification:** Both accounts appear under Global Administrator with **Assignment type: Active**

---

## Step 2: Generate Certificates (Lab / Self-Signed)

> For lab environments, use PowerShell to generate a self-signed root CA and issue user certificates. For production, use your organization's enterprise CA or a trusted public CA.

### 2.1 Create Output Directory

Run the following in **PowerShell (Run as Administrator)**:

```powershell
New-Item -ItemType Directory -Path "C:\EmergencyAccess" -Force
```

### 2.2 Generate a Self-Signed Root CA Certificate

```powershell
# Create a self-signed Root CA
$rootCA = New-SelfSignedCertificate `
    -Subject "CN=EmergencyAccessRootCA, O=Lab, C=US" `
    -KeyUsage CertSign, CRLSign `
    -KeyExportPolicy Exportable `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -NotAfter (Get-Date).AddYears(5)

Write-Host "Root CA Thumbprint: $($rootCA.Thumbprint)"
```

### 2.3 Issue User Certificates Signed by the Root CA

```powershell
# Replace 'tenant' with your actual tenant domain in both UPNs below

# Issue certificate for Emergency CBA Admin 01
$cert01 = New-SelfSignedCertificate `
    -Subject "CN=Emergency CBA Admin 01" `
    -Signer $rootCA `
    -KeyUsage DigitalSignature `
    -KeyExportPolicy Exportable `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.17={text}upn=emergency-cba-01@tenant.onmicrosoft.com") `
    -NotAfter (Get-Date).AddYears(2)

# Issue certificate for Emergency CBA Admin 02
$cert02 = New-SelfSignedCertificate `
    -Subject "CN=Emergency CBA Admin 02" `
    -Signer $rootCA `
    -KeyUsage DigitalSignature `
    -KeyExportPolicy Exportable `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.17={text}upn=emergency-cba-02@tenant.onmicrosoft.com") `
    -NotAfter (Get-Date).AddYears(2)

Write-Host "CBA Admin 01 Thumbprint: $($cert01.Thumbprint)"
Write-Host "CBA Admin 02 Thumbprint: $($cert02.Thumbprint)"
```

### 2.4 Export the Root CA Certificate (.cer for Entra ID upload)

```powershell
# Export root CA public certificate (no private key) for upload to Entra ID
Export-Certificate `
    -Cert $rootCA `
    -FilePath "C:\EmergencyAccess\RootCA.cer"

Write-Host "Root CA exported to C:\EmergencyAccess\RootCA.cer"
```

### 2.5 Export User Certificates (.pfx for device installation)

```powershell
# Use a strong password to protect the PFX files
$pfxPassword = ConvertTo-SecureString -String "ReplaceWithStrongPassword!" -Force -AsPlainText

Export-PfxCertificate -Cert $cert01 -FilePath "C:\EmergencyAccess\EmergencyCBA01.pfx" -Password $pfxPassword
Export-PfxCertificate -Cert $cert02 -FilePath "C:\EmergencyAccess\EmergencyCBA02.pfx" -Password $pfxPassword

Write-Host "PFX files exported to C:\EmergencyAccess\"
```

> **Security:** Transfer PFX files to secure devices using encrypted media. Delete PFX files from the source machine after transfer is confirmed.

---

## Step 3: Upload Root CA to Entra ID

Entra ID must trust your root CA before CBA will work. This is configured in the Certificate Authorities trust store.

### 3.1 Navigate to Certificate Authorities

1. In the **Entra Admin Center**, navigate to:
   **Protection** → **Show more** → **Certificate authorities**

   *Alternative path:* **Identity** → **Security** → **Certificate authorities**

### 3.2 Upload the Root CA Certificate

1. Click **+ Upload**
2. Click **Browse** and select the `RootCA.cer` file exported in Step 2.4
3. Set **Certificate type** to **Root**
4. Leave **Certificate Revocation List (CRL) URL** blank for lab environments
5. Click **Save**
6. **Verification:** The root CA appears in the list with status **Active**

---

## Step 4: Enable and Configure CBA

### 4.1 Navigate to Authentication Methods

1. Navigate to **Protection** → **Authentication methods**
2. Select **Certificate-based authentication** from the list

### 4.2 Enable CBA

1. Under **Enable**, toggle to **Yes**
2. Under **Target**, select **All users** (or scope to a group containing only the emergency accounts)
3. Click **Save**

### 4.3 Configure Authentication Binding

1. In the CBA settings, scroll to **Authentication binding**
2. Under **Default authentication protection level**, select **Multi-factor authentication**
3. Click **Save**

> **Why this matters:** Setting CBA to MFA-level prevents it from being used as a single factor. The CA policy in Step 8 requires an Authentication Strength at MFA level, so this binding must match.

---

## Step 5: Configure Certificate User Mapping

Entra ID maps certificate fields to the correct user account using these settings.

### 5.1 Navigate to User Certificate Mappings

1. In the **Certificate-based authentication** settings, scroll to **User certificate mappings**
2. Click **+ Add new mapping**

### 5.2 Configure the Mapping

| Field | Value |
| --- | --- |
| X.509 certificate field | Principal Name |
| User attribute | User Principal Name |
| Binding type | SubjectAlternativeName |
| Priority | 1 (highest) |

1. Click **Save**

### 5.3 Verify UPN Match

The UPN in the certificate's Subject Alternative Name must match exactly:

- Certificate SAN UPN: `emergency-cba-01@tenant.onmicrosoft.com`
- Entra ID UPN: `emergency-cba-01@tenant.onmicrosoft.com`

---

## Step 6: Install Certificates on Secure Devices

### 6.1 Designate Secure Emergency Devices

- Use dedicated, physically secured devices for emergency access only
- Do not use daily-use workstations
- Restrict physical access to authorized personnel

### 6.2 Install User Certificate

**Windows:**

1. Copy the `.pfx` file to the secure device using encrypted media
2. Double-click the `.pfx` file to launch the **Certificate Import Wizard**
3. Select **Current User** as the store location
4. Enter the PFX password when prompted
5. Select **Automatically select the certificate store**, click **Finish**

**macOS:**

1. Double-click the `.pfx` file
2. Enter the PFX password when prompted
3. Import into the **login** keychain

### 6.3 Verify Certificate Installation

Run in PowerShell on the secure device:

```powershell
# Confirm the certificate is in the user personal store
Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*Emergency CBA*" }
```

Expected output: the certificate appears with the correct Subject and a valid expiry date.

---

## Step 7: Create Authentication Strength for CBA

Break-glass accounts must be protected by a dedicated Authentication Strength policy. This ensures CBA is **required**, not optional.

### 7.1 Navigate to Authentication Strengths

1. Navigate to **Protection** → **Authentication strengths**
2. Click **+ New authentication strength**

### 7.2 Configure the Strength Policy

- **Name:** `Emergency Access – CBA Required`
- **Description:** `Enforces certificate-based authentication for emergency access accounts`
- Under **Allowed authentication methods**, select:
  - Certificate-based authentication (multi-factor)
- Ensure the following are **not** selected:
  - Microsoft Authenticator
  - SMS
  - Voice call
  - Password only

1. Click **Create**

---

## Step 8: Create Conditional Access Policy

> **Design note:** Emergency accounts are **not excluded** from Conditional Access. This lab enforces CBA via a dedicated CA policy — consistent with Microsoft's 2025 security baseline and distinct from older designs that relied on CA exclusions.

### 8.1 Navigate to Conditional Access

1. Navigate to **Protection** → **Conditional Access**
2. Click **+ New policy**

### 8.2 Configure the Policy

**Basic Information:**

- **Name:** `Emergency CBA Admin – CBA Authentication Required`
- **Enable policy:** Toggle **On**

**Assignments:**

- **Users:**
  - Click **Include** → **Select users and groups**
  - Select **Emergency CBA Admin 01** and **Emergency CBA Admin 02**
- **Target resources:**
  - Click **Include** → **All cloud apps**
- **Conditions:** No additional conditions (applies to all sign-in scenarios)

**Access Controls:**

- Click **Grant** → **Require authentication strength**
- Select **Emergency Access – CBA Required**
- Click **Select**

1. Click **Create**

**Result:** Emergency accounts must authenticate with a valid certificate on every sign-in. All weaker methods are blocked.

---

## Step 9: Test CBA Authentication

### 9.1 Prerequisites for Testing

- Secure device with user certificate installed (Step 6)
- Root CA uploaded to Entra ID (Step 3)
- CBA enabled and mapped (Steps 4–5)
- Conditional Access policy active (Step 8)

### 9.2 Attempt Sign-In

1. On the secure device, navigate to **<https://portal.azure.com>**
2. Enter the emergency account UPN: `emergency-cba-01@tenant.onmicrosoft.com`
3. When prompted for an authentication method, select **Sign in with a certificate**
4. Select the installed user certificate from the list
5. Click **OK**

### 9.3 Validate Successful Authentication

- You are signed in without a password prompt or additional MFA step
- Navigate to **My Account** → **Security Info** to confirm the session method
- Check sign-in logs to confirm `Certificate-based authentication` is listed as the authentication method

### 9.4 Validate CA Policy Enforcement

1. On a device **without** the certificate installed, attempt to sign in as an emergency account
2. **Expected result:** Access is blocked — the Authentication Strength policy requires CBA but no certificate is available on this device

---

## Step 10: Monitor and Alert

### 10.1 Review Sign-In Logs

1. Navigate to **Identity** → **Monitoring & health** → **Sign-in logs**
2. Filter by **User**: `emergency-cba-01` or `emergency-cba-02`
3. Verify:
   - Authentication method: `Certificate-based authentication`
   - Sign-in result: `Success`
   - No unexpected sign-in attempts from unknown locations or devices

### 10.2 Configure Alerts

Set up alerts to trigger when:

- Either emergency CBA account signs in (expected to be rare)
- Global Administrator role is added or removed on these accounts
- CBA authentication methods are changed
- Conditional Access policies affecting these accounts are modified

### 10.3 Recommended Tooling

| Tool | Purpose |
| --- | --- |
| **Entra ID Sign-In Logs** | Native monitoring, visible in portal immediately |
| **Microsoft Defender for Cloud Apps** | Advanced anomaly detection and risk signals |
| **Log Analytics** | Custom KQL queries and long-term dashboards |

---

## Validation Checklist

Before completing the lab, verify:

- [ ] Two cloud-only emergency accounts created (`emergency-cba-01`, `emergency-cba-02`)
- [ ] Global Administrator role assigned (Active, not PIM-eligible)
- [ ] Root CA generated and exported to `.cer`
- [ ] User certificates issued with correct UPN in Subject Alternative Name
- [ ] Root CA uploaded to Entra ID Certificate Authorities trust store
- [ ] CBA enabled and set to **Multi-factor authentication** level
- [ ] Certificate user mapping configured (Principal Name → UPN)
- [ ] User certificates installed on designated secure devices
- [ ] Authentication Strength policy created (`Emergency Access – CBA Required`)
- [ ] Conditional Access policy created (enforcing CBA — accounts are **not excluded**)
- [ ] Successful CBA sign-in tested for both accounts
- [ ] Sign-in logs confirm `Certificate-based authentication` as authentication method
- [ ] Monitoring alerts configured

---

## Recovery Runbook

If locked out and needing to use emergency CBA accounts:

1. **Access the secure emergency device** — Retrieve the physically secured device with the user certificate installed
2. **Navigate to the portal** — Go to `https://portal.azure.com`
3. **Sign in using certificate** — Enter `emergency-cba-01@tenant.onmicrosoft.com` and select the installed certificate when prompted
4. **Navigate to the problem** — Go to **Conditional Access** and disable or fix the misconfigured policy
5. **Restore normal admin access** — Validate that regular admin accounts can sign in successfully
6. **Rotate emergency account passwords** — Generate new passwords for both emergency accounts and store securely
7. **Review sign-in logs** — Check for unauthorized access attempts during the incident window
8. **Document the incident** — Record the time, root cause, resolution steps, and any required follow-up actions
9. **Return secure device to storage** — Ensure the device is returned to its physically secured location

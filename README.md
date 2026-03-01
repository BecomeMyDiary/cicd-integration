# DevSecOps CI/CD Pipeline Integration

> นำเครื่องมือ Security เข้าไปใส่ในกระบวนการ CI/CD เพื่อตรวจสอบช่องโหว่โดยอัตโนมัติก่อนที่จะ Deploy ขึ้น Cloud (GCP)

## 📌 Pipeline Overview

```
 Developer Push Code
        │
        ▼
 ┌──────────────────────────────────────────────────────┐
 │              GitHub Actions Pipeline                 │
 │                                                      │
 │  ┌────────────┐  ┌────────────┐  ┌────────────────┐  │
 │  │  Secret     │  │   SAST     │  │     SCA        │  │
 │  │  Scanning   │  │  (Bandit)  │  │  (Safety)      │  │
 │  │ (TruffleHog)│  │            │  │ Dependency Scan│  │
 │  └─────┬──────┘  └─────┬──────┘  └───────┬────────┘  │
 │        │               │                 │           │
 │        └───────┬───────┘─────────────────┘           │
 │                ▼                                     │
 │       ┌────────────────┐                             │
 │       │  Docker Build   │                            │
 │       └───────┬────────┘                             │
 │               ▼                                      │
 │       ┌────────────────┐                             │
 │       │  Trivy Image   │  Container Vulnerability    │
 │       │  Scan          │  Scanning                   │
 │       └───────┬────────┘                             │
 │               ▼                                      │
 │       ┌────────────────┐                             │
 │       │  Push to GCP   │  Google Artifact Registry   │
 │       │  Artifact Reg. │                             │
 │       └───────┬────────┘                             │
 │               ▼                                      │
 │       ┌────────────────┐                             │
 │       │  Deploy to     │  Google Cloud Run           │
 │       │  Cloud Run     │                             │
 │       └────────────────┘                             │
 └──────────────────────────────────────────────────────┘
```

## 🛡️ Security Tools ที่ใช้ในแต่ละขั้นตอน

| Stage | Tool | วัตถุประสงค์ |
|-------|------|-------------|
| **Secret Scanning** | TruffleHog | ตรวจจับ API Keys, Passwords, Tokens ที่หลุดเข้ามาใน Source Code |
| **SAST** | Bandit | วิเคราะห์ Python Source Code แบบ Static เพื่อหาช่องโหว่ เช่น SQL Injection, Hardcoded Passwords |
| **SCA** | Safety | ตรวจสอบ Dependencies ใน `requirements.txt` ว่ามี CVE (ช่องโหว่ที่รู้จัก) หรือไม่ |
| **Container Scan** | Trivy | สแกน Docker Image หา OS-level และ Library-level Vulnerabilities ก่อน Push ขึ้น Registry |

## 📁 โครงสร้างไฟล์

```
CICD secure/
├── .github/
│   └── workflows/
│       └── devsecops.yml        # GitHub Actions Pipeline หลัก
├── scripts/
│   └── security-scan-local.sh   # สคริปต์รัน Security Scan บนเครื่อง Local
├── .bandit.yaml                 # Config สำหรับ Bandit SAST
├── .trivyignore                 # รายการ CVE ที่ต้องการข้าม (Trivy)
├── .gitignore                   # Git ignore
├── .dockerignore                # Docker ignore
├── Dockerfile                   # สร้าง Container Image
├── requirements.txt             # Python Dependencies
└── README.md                    # เอกสารนี้
```

## 🚀 วิธีใช้งาน

### 1. ตั้งค่า GCP Project

แก้ไขค่าใน `.github/workflows/devsecops.yml`:

```yaml
env:
  PROJECT_ID: your-gcp-project-id       # ← ใส่ GCP Project ID
  GAR_LOCATION: asia-southeast1         # ← ใส่ Region
  REPOSITORY: ids-repo                  # ← ใส่ชื่อ Artifact Registry Repo
  SERVICE_NAME: ids-service             # ← ใส่ชื่อ Cloud Run Service
```

### 2. ตั้งค่า GitHub Secrets

ไปที่ GitHub Repository → Settings → Secrets and variables → Actions แล้วเพิ่ม:

| Secret Name | ค่า |
|------------|-----|
| `GCP_CREDENTIALS` | JSON Key ของ Service Account |

### 3. ทดสอบบนเครื่อง Local ก่อน Push

```bash
# ให้สิทธิ์รันสคริปต์
chmod +x scripts/security-scan-local.sh

# รัน Security Scan ทั้งหมดบนเครื่อง Local
./scripts/security-scan-local.sh
```

### 4. Push Code ขึ้น GitHub

```bash
git add .
git commit -m "Add DevSecOps pipeline"
git push origin main
```

Pipeline จะทำงานอัตโนมัติ และตรวจสอบช่องโหว่ทุกขั้นตอนก่อน Deploy ขึ้น GCP Cloud Run

## ⚙️ การปรับแต่ง

- **ปรับ Bandit rules:** แก้ไข `.bandit.yaml` เพื่อข้าม test ID ที่ไม่เกี่ยวข้อง
- **ข้าม CVE เฉพาะ:** เพิ่ม CVE ID ลงใน `.trivyignore`
- **เพิ่ม DAST:** สามารถเพิ่ม OWASP ZAP scan ใน pipeline ได้ (สำหรับ staging environment)

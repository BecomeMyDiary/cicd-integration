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

<<<<<<< HEAD
=======
## 📦 SBOM (Software Bill of Materials)

Pipeline จะสร้างรายงาน SBOM อัตโนมัติในรูปแบบ **CycloneDX** ทุกครั้งที่รัน โดยจะสร้าง 2 ไฟล์:

| ไฟล์ | เนื้อหา |
|------|---------|
| `source-sbom.json` | รายการ Library/Dependencies ทั้งหมดของ Source Code (เช่น Flask, requests) |
| `image-sbom.json` | รายการแพ็กเกจทั้งหมดใน Docker Image รวมถึงแพ็กเกจระดับ OS (เช่น openssl, libcurl) |

### วิธีดาวน์โหลดและดู SBOM

1. ไปที่หน้า **Actions** ของ Repository บน GitHub
2. คลิกเข้าไปที่ Workflow Run ที่ต้องการ (เลือกรอบที่มีเครื่องหมาย ✅ สีเขียว)
3. เลื่อนลงมาด้านล่างสุดของหน้า **Summary**
4. ที่หัวข้อ **Artifacts** ให้คลิกดาวน์โหลด **`sbom-reports`**
5. แตกไฟล์ `.zip` ที่ได้ จะพบไฟล์ JSON ทั้ง 2 ไฟล์

### ตัวอย่างเนื้อหาภายในไฟล์ SBOM

```json
{
  "bomFormat": "CycloneDX",
  "components": [
    {
      "name": "flask",
      "version": "3.0.0",
      "type": "library"
    },
    {
      "name": "openssl",
      "version": "3.0.13",
      "type": "library"
    }
  ]
}
```

### เครื่องมือสำหรับวิเคราะห์ SBOM เพิ่มเติม

- **[Dependency-Track](https://dependencytrack.org/)** — ระบบ Open Source สำหรับจัดการ SBOM แบบรวมศูนย์ สามารถ Import ไฟล์ CycloneDX เข้าไปเพื่อดูกราฟ Components และติดตามช่องโหว่แบบ Real-time
- **[Grype](https://github.com/anchore/grype)** — สแกนไฟล์ SBOM เพื่อตรวจหา CVE ด้วยคำสั่ง `grype sbom:source-sbom.json`

>>>>>>> 19cd87864a9037290c9798c1fb97940382f03f8f
## ⚙️ การปรับแต่ง

- **ปรับ Bandit rules:** แก้ไข `.bandit.yaml` เพื่อข้าม test ID ที่ไม่เกี่ยวข้อง
- **ข้าม CVE เฉพาะ:** เพิ่ม CVE ID ลงใน `.trivyignore`
- **เพิ่ม DAST:** สามารถเพิ่ม OWASP ZAP scan ใน pipeline ได้ (สำหรับ staging environment)

## 🔄 การนำ CI/CD ไปใช้กับ Project อื่น (ตัวอย่างเช่น Node.js)

หากต้องการนำ CI/CD Pipeline นี้ไปประยุกต์ใช้กับโปรเจกต์อื่น ให้ทำตามขั้นตอนดังนี้:

### 1. สิ่งที่ต้อง Copy ไปยังโปรเจกต์ใหม่
นำโฟลเดอร์และไฟล์ต่อไปนี้ไปไว้ที่ Root directory ของโปรเจกต์ใหม่:
- โฟลเดอร์ `.github/` (รวมถึง `workflows/devsecops.yml`)
- ไฟล์ `Dockerfile`
- ไฟล์ `.dockerignore`
- ไฟล์ `.trivyignore` (เพื่อตั้งค่าละเว้นช่องโหว่บางตัวจาก Container Scanner)

*(**หมายเหตุ:** ไฟล์ `.bandit.yaml` ไม่จำเป็นต้องนำไป เพราะเป็นตัวสแกนหาช่องโหว่เฉพาะของโค้ดภาษา Python เพียงอย่างเดียว)*

### 2. สิ่งที่ต้องปรับแก้ในไฟล์ต่างๆ

#### 📝 แก้ไข `.github/workflows/devsecops.yml`
- **Env Variables:** แก้ค่าตัวแปรใต้  `env:` ด้านบน เช่น `PROJECT_ID`, `SERVICE_NAME`, `IMAGE`, `REPOSITORY` ให้ตรงกับระบบของโปรเจกต์ใหม่และ GCP Project ใหม่
- **Security Scans:** หากโปรเจกต์ใหม่ไม่ได้ใช้ Python จะต้องปรับเปลี่ยน Tools ในการ Scan:
  - ลบขั้นตอนที่ตรวจสอบด้วย `setup-python`, `safety` และ `bandit` ออก
  - ใส่ขั้นตอนตรวจสอบช่องโหว่สำหรับภาษาของโปรเจกต์นั้นแทน (เช่น หากใช้ Node.js ก็อาจจะเปลี่ยนไปใช้ `actions/setup-node` และสั่งรัน `npm audit`)

#### 🐳 แก้ไข `Dockerfile`
- เปลี่ยนโครงสร้างภายในจาก Base image Python ให้เป็นของโปรเจกต์นั้นแทน
- ตัวอย่างเช่น สำหรับ Node.js ให้ขึ้นต้นด้วย `FROM node:18-alpine` ทำการคัดลอกไฟล์ `package.json` มารันคำสั่ง `RUN npm install` และเปลี่ยนคำสั่งเริ่มต้นเป็น `CMD ["node", "app.js"]` เป็นต้น

#### 🚫 แก้ไข `.dockerignore`
- อัปเดตรายการไฟล์ตามความเหมาะสมกับภาษาที่ใช้งาน เช่น นำบรรทัด `.venv` และ `__pycache__` ออก แล้วใส่ `node_modules/` เพิ่มเข้าไปแทน

### 3. การจัดการสิทธิ์การเข้าถึง (GCP Credentials)

**ขั้นตอนการสร้างและดาวน์โหลดไฟล์ Key (JSON) จาก Google Cloud:**
1. เข้าสู่ระบบ Google Cloud Console และเลือกโปรเจกต์ของคุณ
2. ไปที่เมนู **IAM & Admin** > **Service Accounts**
3. คลิกที่อีเมล Service Account ที่ต้องการใช้ (เช่น `github-actions-sa@...`)
4. ไปที่แท็บ **KEYS** > คลิกปุ่ม **ADD KEY** > เลือก **Create new key**
5. เลือกประเภทไฟล์เป็น **JSON** แล้วกดปุ่ม **CREATE** (ไฟล์จะถูกดาวน์โหลดลงเครื่องอัตโนมัติ)

**ข้อควรระวังในการนำไปใช้งาน:**
- **ห้ามทำการ Copy ไฟล์รหัสผ่านอย่างเช่น `gcp-key.json` ไปพร้อมกับ Source Code และ Push ขึ้น GitHub เด็ดขาด** 
- ให้กำหนดสิทธิ์โดยเข้าไปที่ **Settings > Secrets and variables > Actions > New repository secret** ของ GitHub Repository 
- สร้าง Secret ที่มีชื่อว่า `GCP_CREDENTIALS` และคัดลอกข้อความในไฟล์ JSON service account key ที่ดาวน์โหลดมา ไปวางในช่อง Value

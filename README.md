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

นี่คือส่วนที่คุณต้อง Copy ไปและวิธีการปรับเทียบครับ:

1. โฟลเดอร์ .github/workflows/ (ไฟล์ devsecops.yml)
นี่คือหัวใจหลักของ CI/CD pipeline ที่รันบน GitHub Actions

วิธีทำ: Copy อานี้ทั้งโฟลเดอร์(.github) ไปวางไว้ที่โฟลเดอร์งาน (Root directory) ของ Project ใหม่
สิ่งที่ต้องแก้:
Env Variables: เปิดไฟล์ devsecops.yml แล้วแก้ตัวแปรช่วง env: ด้านบน เช่น PROJECT_ID, SERVICE_NAME, IMAGE, REPOSITORY ให้เป็นของ Project ใหม่
Security Scans (สำคัญมาก): Pipeline เดิมในขั้นตอนของ Security Scans (บรรทัดที่ 37-57) ถูกออกแบบมาให้รันคำสั่งเช็กโค้ดของ Python (setup-python, ติดตั้ง pip install safety bandit) หากโปรเจกต์ใหม่เป็น Node.js คุณต้องเปลี่ยนมาใช้ของ Node เช่น actions/setup-node และสั่งรัน npm audit แทน safety/bandit
2. ไฟล์ Dockerfile และ .dockerignore
ใช้สำหรับการแพ็กโปรเจกต์ให้เป็น Container เพื่อนำไป Deploy บน Google Cloud Run (ตามที่ระบุใน CI/CD)

วิธีทำ: Copy ไปใส่ในโปรเจกต์ใหม่
สิ่งที่ต้องแก้ใน Dockerfile: ของเดิมใช้ Base image เป็น python:3.13-slim คุณจะต้องเปลี่ยนไส้ในของ Dockerfile ทั้งหมดให้เป็นการ Build สำหรับ Node.js 
(เช่นเริ่มด้วย FROM node:18-alpine, ทำการ COPY package*.json ./, สั่ง RUN npm install และ CMD ["node", "app.js"])
สิ่งที่ต้องแก้ใน .dockerignore: ลบพวก .venv, __pycache__ ทิ้งไปแล้วใส่ node_modules/ ลงไปแทน
3. ไฟล์ตั้งค่า Security (เช่น .trivyignore)
วิธีทำ: สามารถ Copy ไฟล์ .trivyignore ไปใช้ได้เลย (ไฟล์นี้เอาไว้ตั้งค่าละเว้นช่องโหว่ (CVE) บางตัวจาก Container Scanner)
สิ่งที่ "ไม่ต้อง" Copy: ไฟล์ .bandit.yaml ไม่ต้อง นำไปด้วย เพราะโปรแกรม Bandit เป็นตัวสแกนหาช่องโหว่ของโค้ด Python เท่านั้น
4. การจัดการสิทธิ์การเข้าถึง (GCP Credentials)
ข้อควรระวัง: ห้าม Copy ไฟล์รหัสผ่านอย่าง gcp-key.json ไปพร้อมกับ Source Code เด็ดขาด เพราะถ้าพุชขึ้น GitHub จะทำให้ความลับรั่วไหลได้
วิธีทำ: ใน Github ของ Repository โปรเจกต์ใหม่ ให้คุณเข้าไปที่ Settings > Secrets and variables > Actions > New repository secret ตั้งชือช่องว่า GCP_CREDENTIALS แล้วนำข้อความในไฟล์ gcp-key.json ของเดิม (หรือของ Service account ใหม่ถ้าใช้ Project บน GCP แยกกัน) มาแปะไว้ที่นี่แทน (เพราะขั้นตอนที่ 3 ใน CI/CD ต้องการดึง Secret นี้ไปล็อกอิน)

Pipeline จะทำงานอัตโนมัติ และตรวจสอบช่องโหว่ทุกขั้นตอนก่อน Deploy ขึ้น GCP Cloud Run

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
- **ห้ามทำการ Copy ไฟล์รหัสผ่านอย่างเช่น `gcp-key.json` ไปพร้อมกับ Source Code และ Push ขึ้น GitHub เด็ดขาด** 
- ให้กำหนดสิทธิ์โดยเข้าไปที่ **Settings > Secrets and variables > Actions > New repository secret** ของ GitHub Repository ในโปรเจกต์ใหม่ 
- สร้าง Secret ที่มีชื่อว่า `GCP_CREDENTIALS` และคัดลอกข้อความในไฟล์ JSON service account key ไปวางในช่อง Value

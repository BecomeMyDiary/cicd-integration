# DevSecOps CI/CD Demo Project

โปรเจกต์ตัวอย่างนี้สร้างเพื่อรันกับ workflow ที่มีอยู่ใน:
- `.github/workflows/devsecops.yml`

## วิธีใช้

1. clone repo
2. ไปที่โฟลเดอร์ demo-project:
   ```bash
   cd demo-project
   ```
3. รัน local:
   ```bash
   python -m pip install -r requirements.txt
   python app.py
   ```
   เปิด `http://localhost:8080` และ `http://localhost:8080/health`

4. build docker image:
   ```bash
   docker build -t demo-devsecops-app .
   docker run -p 8080:8080 demo-devsecops-app
   ```

## การใช้งานกับ GitHub Actions

- workflow ตัวนี้จะทำงานเมื่อ push/merge ไปที่ `main`
- ถ้าต้องการทดสอบกับ repo และรู้สึกว่าพร้อมแล้ว ให้แก้ไฟล์ `.github/workflows/devsecops.yml` (ค่าตัวแปร `PROJECT_ID`, `REPOSITORY`, ฯลฯ) ให้ตรงกับ GCP ของคุณ
- commit + push แล้ว GitHub Actions จะรัน:
  1) TruffleHog secret scan
  2) Safety dependency scan
  3) Bandit SAST
  4) Docker build + Trivy image scan
  5) (ถ้าตั้ง GCP credential ถูก) deploy ไป Cloud Run

---

Developed as a minimal Python/Flask demo for DevSecOps pipeline validation.

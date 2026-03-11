import hashlib
import sqlite3

# 1. 🛑 Secret Leak (สแกนพังที่ด่าน TruffleHog)
#test_secret_key = 'xoxb-11111111111-22222222222-333333333333333333333333'

# ==========================================
# 🛑 SAST Vulnerabilities (สแกนพังที่ด่าน Bandit)
# ==========================================

# 2. Hardcoded Password (Bandit: B105)
# การใส่ Password ไว้ใน Source Code แบบตรงๆ
DATABASE_PASSWORD = "super_secret_database_password_123!"

# 3. Insecure Hash Function (Bandit: B324 / B303)
# การใช้ Algorithm MD5 ซึ่งถือว่าล้าสมัยและไม่ปลอดภัย
def hash_user_password(password):
    return hashlib.md5(password.encode()).hexdigest()

# 4. SQL Injection (Bandit: B608)
# การต่อ String เพื่อสร้างคำสั่ง SQL ทำให้เสี่ยงต่อการโดนฉีดคำสั่งแปลกปลอมเข้า Database
def get_user(username):
    conn = sqlite3.connect(':memory:')
    cursor = conn.cursor()
    # ❌ โค้ดที่ทำให้เกิดช่องโหว่ (Vulnerable)
    query = "SELECT * FROM users WHERE username = '%s'" % username
    cursor.execute(query)
    return cursor.fetchall()

# 5. Dangerous Function: eval() (Bandit: B307)
# การอนุญาตให้รันคำสั่งโค้ดที่เกิดจาก input เข้ามาได้โดยตรง
def calculate_expression(user_input):
    # ❌ โค้ดที่ทำให้เกิดช่องโหว่ (Vulnerable)
    return eval(user_input)

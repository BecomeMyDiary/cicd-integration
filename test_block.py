# test_block.py

# ==========================================
# 🛑 simulated Secret Leak (สแกนพังที่ด่าน TruffleHog)
# ==========================================

# 1. Fake AWS Access Key (TruffleHog: AWS)
# TruffleHog will detect the format of this string and flag it as a potential AWS Access Key.
FAKE_AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
FAKE_AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

def connect_to_aws():
    print(f"Connecting to AWS with key: {FAKE_AWS_ACCESS_KEY_ID}")

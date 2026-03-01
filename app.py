"""
DevSecOps Demo Web Application
A simple Flask web server to demonstrate CI/CD pipeline with security scanning.
"""
import os
from flask import Flask, render_template

app = Flask(__name__, template_folder="templates", static_folder="static")


@app.route("/")
def index():
    """Render the main landing page."""
    return render_template("index.html")


@app.route("/health")
def health():
    """Health check endpoint for Cloud Run."""
    return {"status": "healthy", "service": "devsecops-demo"}, 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port, debug=False)

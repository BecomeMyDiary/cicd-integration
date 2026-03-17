from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    return 'Hello, world! 👋'

@app.route('/hello')
def hello():
    return {
        'status': 'ok',
        'service': 'devsecops-demo',
        'message': 'Hello, world! This is the demo app for DevSecOps CI/CD pipeline.'
    }

@app.route('/health')
def health():
    return {'status': 'healthy'}, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080) # nosec

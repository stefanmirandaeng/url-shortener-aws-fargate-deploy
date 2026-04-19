from flask import Flask, redirect, request, jsonify
import hashlib, os

app = Flask(__name__)
store = {}

@app.route('/shorten', methods=['POST'])
def shorten():
    url = request.json.get('url')
    key = hashlib.md5(url.encode()).hexdigest()[:6]
    store[key] = url
    return jsonify({'short': f"/{key}"})

@app.route('/<key>')
def resolve(key):
    url = store.get(key)
    if not url:
        return 'Not found', 404
    return redirect(url)

@app.route('/health')
def health():
    return 'ok', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
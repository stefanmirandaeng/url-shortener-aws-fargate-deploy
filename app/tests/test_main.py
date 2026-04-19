import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from main import app

def test_health():
    client = app.test_client()
    res = client.get('/health')
    assert res.status_code == 200

def test_shorten_and_resolve():
    client = app.test_client()
    res = client.post('/shorten', json={'url': 'https://example.com'})
    assert res.status_code == 200
    key = res.get_json()['short'].lstrip('/')
    res = client.get(f'/{key}')
    assert res.status_code == 302

def test_resolve_not_found():
    client = app.test_client()
    res = client.get('/doesnotexist')
    assert res.status_code == 404

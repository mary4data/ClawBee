import json, os
f = '/data/.clawdbot/openclaw.json'
c = json.load(open(f))
c['models'] = {
    'featherless': {
        'provider': 'openai',
        'baseURL': 'https://api.featherless.ai/v1',
        'apiKey': os.environ['FEATHERLESS_API_KEY'],
        'model': os.environ.get('FEATHERLESS_MODEL', 'meta-llama/Meta-Llama-3.1-70B-Instruct'),
        'label': 'Featherless AI'
    }
}
json.dump(c, open(f, 'w'), indent=2)
print('Model config updated. Redeploy to apply.')

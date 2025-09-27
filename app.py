import requests

def gemma3_response(user_prompt, summary_type):
    url = "http://localhost:11434/api/chat"
    
    payload = {
        "model": "gemma3:270m",
        "messages": [
            {
                "role": "system",
                "content": f"You are a text summarizer/modifier. Rewrite the input in a formal and {summary_type} style."
            },
            {
                "role": "user",
                "content": user_prompt
            }
        ],
        "stream": False
    }
    
    response = requests.post(url, json=payload)
    # return response.text
    return response.json()['message']['content']

# print(gemma3_response('adsv hi howss arse yo?', 'email'))

from flask import Flask
from flask import request
app = Flask(__name__)

@app.route('/')
def index():
    return """
    <form action='/' method='POST'>
        Text: <textarea name='user_prompt'></textarea> <br>
        Style: <input name='style' type='text'> <br>
        <button type='submit'>Ask</button>
    </form>
    """

@app.route('/', methods=['POST'])
def ask():
    user_prompt = request.form.get('user_prompt')
    style = request.form.get('style')
    ai_answer = gemma3_response(user_prompt, style)
    return f"<textarea>{ai_answer}</textarea>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
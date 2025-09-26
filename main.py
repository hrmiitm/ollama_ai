from pydantic_ai import Agent
from pydantic_ai.models.openai import OpenAIChatModel
from pydantic_ai.providers.ollama import OllamaProvider

ollama_model = OpenAIChatModel(
    model_name='gemma3:270m',
    provider=OllamaProvider(base_url='http://localhost:11434/v1'))

agent = Agent(ollama_model)

import uvicorn
from fastapi import FastAPI, Query
from fastapi.responses import JSONResponse

app = FastAPI(
    title="Pydantic AI with Ollama",
    description="FastAPI app using Pydantic-AI with local Ollama gemma3:270m model",
    version="1.0.0")

@app.get('/')
def index(ask: str = Query(..., description="User prompt")):
    try:
        result = agent.run_sync(ask)
        return {'ai_answer': result.output}
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={'error': f'Error processing request: {str(e)}'})

@app.get('/health')
def health_check():
    return {'status': 'healthy', 'model': 'gemma3:270m'}

if __name__ == "__main__":
    # This will be called by the startup script
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=7860)

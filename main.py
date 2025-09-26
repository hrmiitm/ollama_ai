from pydantic_ai import Agent
from pydantic_ai.models.openai import OpenAIChatModel
from pydantic_ai.providers.ollama import OllamaProvider


ollama_model = OpenAIChatModel(
    model_name='gemma3:270m',
    provider=OllamaProvider(base_url='http://localhost:11434/v1'),
)
agent = Agent(ollama_model)

import uvicorn
from fastapi import FastAPI, Query
app = FastAPI()

@app.get('/')
def index(ask: str = Query(..., description="User prompt")):
    result = agent.run_sync(ask)
    return {'ai_answer': result.output}

if __name__ == "__main__":
    # Run the server when script is executed directly
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=8000
    )
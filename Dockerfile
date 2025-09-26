# Use Alpine Ollama as base image
FROM docker.io/alpine/ollama:0.12.0

# Switch to root to install packages
USER root

# Install Python, pip, and other dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    curl \
    bash

# Create app directory
WORKDIR /app

# Copy the main.py file
COPY main.py .

# Install Python dependencies
RUN pip3 install --no-cache-dir \
    fastapi \
    uvicorn[standard] \
    pydantic-ai \
    httpx

# Start Ollama, pull the model during build time, then stop
RUN ollama serve & \
    sleep 10 && \
    echo "Pulling gemma3:270m model during build..." && \
    ollama pull gemma3:270m && \
    pkill ollama

# Create a startup script that starts both services
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Ollama in the background' >> /app/start.sh && \
    echo 'echo "Starting Ollama server..."' >> /app/start.sh && \
    echo 'ollama serve &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Wait for Ollama to be ready' >> /app/start.sh && \
    echo 'echo "Waiting for Ollama to start..."' >> /app/start.sh && \
    echo 'while ! curl -s http://localhost:11434/api/version > /dev/null; do' >> /app/start.sh && \
    echo '    sleep 1' >> /app/start.sh && \
    echo 'done' >> /app/start.sh && \
    echo 'echo "Ollama is ready!"' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start the FastAPI application' >> /app/start.sh && \
    echo 'echo "Starting FastAPI application on port 8000..."' >> /app/start.sh && \
    echo 'exec python3 main.py' >> /app/start.sh && \
    chmod +x /app/start.sh

# Only expose FastAPI port (Ollama runs internally)
EXPOSE 8000

# Set the startup script as the entrypoint
ENTRYPOINT ["/app/start.sh"]

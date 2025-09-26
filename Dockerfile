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

# Create app directory and user for HF Spaces
RUN addgroup -g 1001 user && \
    adduser -D -u 1001 -G user user && \
    mkdir -p /app && \
    chown -R user:user /app

# Set working directory
WORKDIR /app

# Copy the main.py file
COPY main.py .
COPY requirements.txt .

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Start Ollama, pull the model during build time, then stop
RUN ollama serve & \
    sleep 15 && \
    echo "Pulling gemma3:270m model during build..." && \
    ollama pull gemma3:270m && \
    pkill ollama

# Create a startup script optimized for HF Spaces
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Ollama in the background' >> /app/start.sh && \
    echo 'echo "Starting Ollama server..."' >> /app/start.sh && \
    echo 'ollama serve &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Wait for Ollama to be ready' >> /app/start.sh && \
    echo 'echo "Waiting for Ollama to start..."' >> /app/start.sh && \
    echo 'timeout=30' >> /app/start.sh && \
    echo 'counter=0' >> /app/start.sh && \
    echo 'while ! curl -s http://localhost:11434/api/version > /dev/null; do' >> /app/start.sh && \
    echo '    sleep 1' >> /app/start.sh && \
    echo '    counter=$((counter + 1))' >> /app/start.sh && \
    echo '    if [ $counter -ge $timeout ]; then' >> /app/start.sh && \
    echo '        echo "Timeout waiting for Ollama to start"' >> /app/start.sh && \
    echo '        exit 1' >> /app/start.sh && \
    echo '    fi' >> /app/start.sh && \
    echo 'done' >> /app/start.sh && \
    echo 'echo "Ollama is ready!"' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start the FastAPI application on HF Spaces port' >> /app/start.sh && \
    echo 'echo "Starting FastAPI application on port 7860..."' >> /app/start.sh && \
    echo 'exec python3 -c "' >> /app/start.sh && \
    echo 'import uvicorn' >> /app/start.sh && \
    echo 'from main import app' >> /app/start.sh && \
    echo 'uvicorn.run(app, host=\"0.0.0.0\", port=7860)' >> /app/start.sh && \
    echo '"' >> /app/start.sh && \
    chmod +x /app/start.sh

# Change ownership to user
RUN chown -R user:user /app

# Switch to user for security
USER user

# Set environment variables for HF Spaces
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    PYTHONUNBUFFERED=1

# Expose HF Spaces port (required)
EXPOSE 7860

# Set the startup script as the entrypoint
ENTRYPOINT ["/app/start.sh"]

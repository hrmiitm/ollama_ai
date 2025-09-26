# Use Alpine Ollama as base image
FROM docker.io/alpine/ollama:0.12.0

# Switch to root to install packages and setup directories
USER root

# Install Python, pip, and other dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    curl \
    bash \
    shadow

# Create user with proper home directory and permissions
RUN addgroup -g 1001 user && \
    adduser -D -u 1001 -G user user -h /home/user && \
    mkdir -p /home/user/.ollama && \
    mkdir -p /app && \
    chown -R user:user /home/user && \
    chown -R user:user /app

# Set working directory
WORKDIR /app

# Copy files
COPY main.py .
COPY requirements.txt .

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Pre-pull the model as root (to avoid permission issues)
RUN ollama serve & \
    sleep 15 && \
    echo "Pulling gemma3:270m model during build..." && \
    ollama pull gemma3:270m && \
    pkill ollama && \
    sleep 2

# Copy the Ollama models to user's directory with correct permissions
RUN if [ -d "/root/.ollama" ]; then \
        cp -r /root/.ollama/* /home/user/.ollama/ 2>/dev/null || true && \
        chown -R user:user /home/user/.ollama; \
    fi

# Create startup script with proper environment
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Set Ollama home directory' >> /app/start.sh && \
    echo 'export OLLAMA_HOME=/home/user/.ollama' >> /app/start.sh && \
    echo 'export HOME=/home/user' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Ensure directory exists with correct permissions' >> /app/start.sh && \
    echo 'mkdir -p /home/user/.ollama' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Ollama in the background' >> /app/start.sh && \
    echo 'echo "Starting Ollama server..."' >> /app/start.sh && \
    echo 'ollama serve &' >> /app/start.sh && \
    echo 'OLLAMA_PID=$!' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Wait for Ollama to be ready' >> /app/start.sh && \
    echo 'echo "Waiting for Ollama to start..."' >> /app/start.sh && \
    echo 'timeout=60' >> /app/start.sh && \
    echo 'counter=0' >> /app/start.sh && \
    echo 'while ! curl -s http://localhost:11434/api/version > /dev/null; do' >> /app/start.sh && \
    echo '    if [ $counter -ge $timeout ]; then' >> /app/start.sh && \
    echo '        echo "Timeout waiting for Ollama to start"' >> /app/start.sh && \
    echo '        kill $OLLAMA_PID 2>/dev/null || true' >> /app/start.sh && \
    echo '        exit 1' >> /app/start.sh && \
    echo '    fi' >> /app/start.sh && \
    echo '    sleep 1' >> /app/start.sh && \
    echo '    counter=$((counter + 1))' >> /app/start.sh && \
    echo 'done' >> /app/start.sh && \
    echo 'echo "Ollama is ready!"' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Verify model is available' >> /app/start.sh && \
    echo 'ollama list | grep -q "gemma3:270m" || echo "Warning: gemma3:270m model not found"' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start FastAPI application' >> /app/start.sh && \
    echo 'echo "Starting FastAPI application on port 7860..."' >> /app/start.sh && \
    echo 'exec python3 -c "' >> /app/start.sh && \
    echo 'import uvicorn' >> /app/start.sh && \
    echo 'from main import app' >> /app/start.sh && \
    echo 'uvicorn.run(app, host=\"0.0.0.0\", port=7860)' >> /app/start.sh && \
    echo '"' >> /app/start.sh && \
    chmod +x /app/start.sh

# Change ownership of all files to user
RUN chown -R user:user /app

# Switch to user for security (required by HF Spaces)
USER user

# Set environment variables for HF Spaces and Ollama
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    OLLAMA_HOME=/home/user/.ollama \
    OLLAMA_MODELS=/home/user/.ollama/models

# Expose HF Spaces port
EXPOSE 7860

# Set the startup script as the entrypoint
ENTRYPOINT ["/app/start.sh"]

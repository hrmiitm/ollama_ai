# Use Ollama Alpine base image
FROM docker.io/alpine/ollama:0.12.0

# Install Python and dependencies
RUN apk add --no-cache python3 py3-pip curl bash

# Create a non-root user and setup directories with proper permissions
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser && \
    mkdir -p /home/appuser/.ollama && \
    chown -R appuser:appuser /home/appuser

# Set work directory
WORKDIR /app

# Copy files
COPY main.py requirements.txt start.sh ./

# Install Python packages
RUN pip3 install --no-cache-dir -r requirements.txt

# Pre-pull model as root (using default location, then copy to user)
RUN ollama serve & sleep 15 && ollama pull gemma3:270m && pkill ollama && \
    cp -r /root/.ollama/* /home/appuser/.ollama/ && \
    chown -R appuser:appuser /home/appuser/.ollama

# Make start script executable
RUN chmod +x start.sh

# Switch to non-root user
USER appuser

# Set environment variables for Ollama to use user home directory
ENV HOME=/home/appuser \
    OLLAMA_HOME=/home/appuser/.ollama \
    OLLAMA_MODELS=/home/appuser/.ollama/models

# Expose HF Spaces port
EXPOSE 7860

# Override entrypoint and run commands directly
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["./start.sh"]

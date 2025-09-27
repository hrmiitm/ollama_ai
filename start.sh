#!/bin/bash

echo "🚀 Starting FormalAI services..."

# Start Ollama server in background using full path
echo "📡 Starting Ollama server..."
/usr/bin/ollama serve &

# Wait for Ollama to be ready
echo "⏳ Waiting for Ollama to start..."
sleep 8

# Health check for Ollama
while ! curl -f http://localhost:11434/api/tags > /dev/null 2>&1; do
    echo "⏳ Waiting for Ollama API..."
    sleep 3
done

echo "✅ Ollama is ready!"
echo "✅ Model gemma3:270m is pre-installed!"

# List available models for verification
echo "📋 Available models:"
/usr/bin/ollama list

# Start Flask application
echo "🌐 Starting Flask application on port 5000..."
python app.py

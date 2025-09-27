#!/bin/bash

echo "🔄 Installing gemma3:270m model during build..."

# Start Ollama in background using full path
/usr/bin/ollama serve &
OLLAMA_PID=$!

# Wait longer for Alpine-based Ollama to start
sleep 15

# Check if Ollama is ready with timeout
TIMEOUT=60
ELAPSED=0
while ! curl -f http://localhost:11434/api/tags > /dev/null 2>&1; do
    echo "Waiting for Ollama to be ready... ($ELAPSED/$TIMEOUT seconds)"
    sleep 3
    ELAPSED=$((ELAPSED + 3))
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "❌ Timeout waiting for Ollama to start!"
        kill $OLLAMA_PID 2>/dev/null || true
        exit 1
    fi
done

echo "✅ Ollama is ready!"

# Pull the model using full path
echo "📥 Pulling gemma3:270m model..."
if /usr/bin/ollama pull gemma3:270m; then
    echo "✅ Model gemma3:270m downloaded successfully!"
else
    echo "❌ Failed to download model!"
    kill $OLLAMA_PID 2>/dev/null || true
    exit 1
fi

# Verify model was installed
if /usr/bin/ollama list | grep -q "gemma3:270m"; then
    echo "✅ Model gemma3:270m verified in model list!"
else
    echo "❌ Model not found in list!"
    kill $OLLAMA_PID 2>/dev/null || true
    exit 1
fi

# Stop Ollama gracefully
echo "🛑 Stopping Ollama service..."
kill $OLLAMA_PID
wait $OLLAMA_PID 2>/dev/null || true

echo "✅ Model installation complete!"

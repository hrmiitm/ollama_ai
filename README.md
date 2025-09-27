---
title: FormalAI Text Formatter
emoji: 🤖
colorFrom: blue
colorTo: purple
sdk: podman
pinned: false
license: mit
app_port: 5000
---

# FormalAI Text Formatter

Transform your casual text into formal, professional writing using AI!

## Features

- 📝 **Text Formatting**: Convert casual text to formal style
- ✨ **Multiple Styles**: Email, report, academic, business formats
- 🤖 **AI-Powered**: Uses Gemma 3 270M model via Ollama
- 🚀 **One-Click Deploy**: Ready for Hugging Face Spaces

## How to Use

1. Enter your text in the textarea
2. Specify the desired writing style (email, report, etc.)
3. Click "Format Text" to get your professionally formatted text

## Local Development

```
# Build the image
podman build -t formaliai .

# Run It
podman run -d --name formaliai -p 5000:5000 formaliai
```

## Technology Stack

- **Frontend**: HTML, Flask
- **Backend**: Python Flask
- **AI Model**: Gemma 3 270M (via Ollama)
- **Deployment**: podman container

## API Endpoints

- `GET /` - Main interface
- `POST /` - Process text formatting

---

*Built with ❤️ using Ollama and Flask*
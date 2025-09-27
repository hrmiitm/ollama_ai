FROM docker.io/alpine/ollama:0.12.0

# Set working directory
WORKDIR /app

# Install Python and system dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    curl \
    bash

# Create symbolic link for python command
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy model installation script
COPY install_model.sh .
RUN chmod +x install_model.sh

# Install model during build time
RUN ./install_model.sh

# Copy application files
COPY app.py .
COPY start.sh .

# Make startup script executable
RUN chmod +x start.sh

# Expose only Flask port
EXPOSE 5000

# Override the original entrypoint completely
ENTRYPOINT ["./start.sh"]

# Use an official Python image that is supported by Cloud Functions Gen2
FROM python:3.10-slim
# Or python:3.9-slim, python:3.11-slim etc. Match your Cloud Function runtime if possible.

# Install Graphviz and other system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY . .

# Define the command to run the application (Cloud Functions will use the entry point)
# This CMD is more for testing the container directly if needed.
# For Cloud Functions, the entry point specified during deployment is key.
# ENV PORT 8080 # Standard port for Cloud Functions (though it might select one)
# CMD exec functions-framework --target=main_http_entrypoint --port=${PORT}
# For simpler container testing without functions-framework, you could use:
# CMD ["python", "gcp_real_estate_diagram.py"]
# However, the functions-framework is closer to how Gen2 functions run.
# If using Cloud Run directly, you'd use Flask/FastAPI to start a server.
# For Cloud Functions, the container just needs the code and entry point.
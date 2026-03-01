# Use an official Python light-weight runtime as a parent image
FROM python:3.10-slim

# Set environment variables for better Python execution
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install dependencies securely without cache
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose a port (Cloud Run injects PORT env var, default 8080)
ENV PORT=8080
EXPOSE 8080

# Run the application with gunicorn (production server)
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]

# Dockerfile
# Use an official Python runtime as a parent image
FROM python:3.12-slim-bookworm

# Set work directory
WORKDIR /app

# Install uv using the official distroless image.
# Pinning to a specific version (e.g., :0.6.11) is recommended for reproducibility.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Copy project definition (pyproject.toml) and lock file (if available)
# Assumes pyproject.toml exists in your project root (shellserver).
# If you generate and use a lock file (uv.lock), uncomment the second COPY line for reproducible builds.
COPY pyproject.toml ./
COPY uv.lock ./

# Copy the application code into the container
COPY server.py .

# Install dependencies using uv with --system flag
RUN uv pip install --system --requirement pyproject.toml

# Expose the port your app runs on
EXPOSE 8080

# Define the command to run the application using 'uv run'
CMD ["uv", "run", "server.py"]
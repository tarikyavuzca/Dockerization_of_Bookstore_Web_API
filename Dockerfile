# Use the Python Alpine image as the base image
FROM python:3.9-alpine

# Copy the rest of the application code to the working directory
COPY . .

# Set the working directory inside the container
WORKDIR /app

# Install the Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Setting Port
EXPOSE 80

# Set the entry point for the container
CMD python ./bookstore-api.py

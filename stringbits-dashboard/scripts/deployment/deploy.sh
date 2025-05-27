#!/bin/bash

set -e

echo "🚀 Starting StringBits Dashboard deployment..."

# Navigate to docker directory
cd "$(dirname "$0")/../../docker"

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found. Are you in the right directory?"
    exit 1
fi

# Set environment variables
export JWT_SECRET=${JWT_SECRET:-$(openssl rand -base64 32)}

echo "📦 Building Docker images..."
docker compose build --no-cache

echo "🔄 Stopping existing services..."
docker compose down

echo "🚀 Starting new services..."
docker compose up -d

echo "⏳ Waiting for services to be healthy..."
sleep 30

# Health checks
echo "🔍 Checking service health..."
for service in dashboard-backend dashboard-frontend; do
    if docker ps | grep -q "$service"; then
        echo "✅ $service is running"
    else
        echo "❌ $service failed to start"
        docker logs $service
        exit 1
    fi
done

echo "🎉 Deployment complete!"
echo "📊 Dashboard Frontend: http://100.112.235.46:8090"
echo "🔧 Dashboard API: http://100.112.235.46:3001"
echo ""
echo "📝 API Endpoints:"
echo "  - Overview: http://100.112.235.46:3001/api/overview"
echo "  - Services: http://100.112.235.46:3001/api/services"
echo "  - Health: http://100.112.235.46:3001/api/health"

# Show status
docker compose ps
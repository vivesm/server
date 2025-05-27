const axios = require('axios');
const Docker = require('dockerode');

class ServiceMonitor {
  constructor() {
    this.docker = new Docker();
    this.timeout = 10000; // 10 second timeout
    this.services = this.getServiceDefinitions();
  }

  getServiceDefinitions() {
    return [
      { 
        name: 'Portainer', 
        containerName: 'portainer',
        healthEndpoint: 'https://100.112.235.46:9443/api/status',
        internalCheck: true,
        ignoreSSL: true
      },
      { 
        name: 'n8n', 
        containerName: 'n8n',
        healthEndpoint: 'https://n8n.stringbits.com/healthz',
        ignoreSSL: true
      },
      { 
        name: 'Gollum Wiki', 
        containerName: 'gollum',
        healthEndpoint: 'http://100.112.235.46:4567',
        internalCheck: true
      },
      { 
        name: 'Dashboard', 
        containerName: 'stringbits-dashboard-backend',
        healthEndpoint: null // Self-monitoring
      },
      { 
        name: 'Caddy', 
        containerName: 'caddy',
        healthEndpoint: null 
      },
      {
        name: 'Watchtower',
        containerName: 'watchtower',
        healthEndpoint: null
      }
    ];
  }

  async checkServiceStatus(service) {
    try {
      // First check if container is running
      const containerStatus = await this.checkContainerStatus(service.containerName);
      
      if (containerStatus !== 'running') {
        return {
          name: service.name,
          status: 'stopped',
          reason: 'Container not running',
          containerStatus: containerStatus,
          lastChecked: new Date()
        };
      }

      // Then check HTTP endpoint if available
      if (service.healthEndpoint) {
        const startTime = Date.now();
        
        // Configure axios for self-signed certificates
        const axiosConfig = {
          timeout: this.timeout,
          validateStatus: (status) => status < 500
        };
        
        if (service.ignoreSSL) {
          const https = require('https');
          axiosConfig.httpsAgent = new https.Agent({
            rejectUnauthorized: false
          });
        }
        
        try {
          const response = await axios.get(service.healthEndpoint, axiosConfig);
          const responseTime = Date.now() - startTime;
          
          return {
            name: service.name,
            status: response.status === 200 ? 'healthy' : 'degraded',
            responseTime: responseTime,
            httpStatus: response.status,
            containerStatus: 'running',
            lastChecked: new Date()
          };
        } catch (httpError) {
          // If HTTP check fails but container is running
          return {
            name: service.name,
            status: 'degraded',
            reason: `Health check failed: ${httpError.message}`,
            containerStatus: 'running',
            lastChecked: new Date()
          };
        }
      }

      // If no health endpoint, container running = service healthy
      return {
        name: service.name,
        status: 'healthy',
        reason: 'Container running (no health endpoint)',
        containerStatus: 'running',
        lastChecked: new Date()
      };

    } catch (error) {
      return {
        name: service.name,
        status: 'error',
        error: error.message,
        lastChecked: new Date()
      };
    }
  }

  async checkContainerStatus(containerName) {
    try {
      const containers = await this.docker.listContainers({ all: true });
      const container = containers.find(c => 
        c.Names.some(name => name.includes(containerName))
      );
      
      if (!container) {
        return 'not-found';
      }
      
      return container.State.toLowerCase();
    } catch (error) {
      console.error(`Error checking container ${containerName}:`, error.message);
      return 'error';
    }
  }

  async getContainerStats(containerName) {
    try {
      const containers = await this.docker.listContainers();
      const containerInfo = containers.find(c => 
        c.Names.some(name => name.includes(containerName))
      );
      
      if (!containerInfo) {
        return null;
      }

      const container = this.docker.getContainer(containerInfo.Id);
      const stats = await container.stats({ stream: false });
      
      // Calculate CPU usage
      const cpuDelta = stats.cpu_stats.cpu_usage.total_usage - 
                       stats.precpu_stats.cpu_usage.total_usage;
      const systemDelta = stats.cpu_stats.system_cpu_usage - 
                          stats.precpu_stats.system_cpu_usage;
      const cpuPercent = (cpuDelta / systemDelta) * 100 * stats.cpu_stats.online_cpus;
      
      // Calculate memory usage
      const memUsage = stats.memory_stats.usage;
      const memLimit = stats.memory_stats.limit;
      const memPercent = (memUsage / memLimit) * 100;
      
      return {
        cpu: cpuPercent.toFixed(2),
        memory: {
          used: (memUsage / 1024 / 1024).toFixed(2), // MB
          limit: (memLimit / 1024 / 1024).toFixed(2), // MB
          percent: memPercent.toFixed(2)
        }
      };
    } catch (error) {
      console.error(`Error getting stats for ${containerName}:`, error.message);
      return null;
    }
  }

  async monitorAllServices() {
    const results = await Promise.allSettled(
      this.services.map(async service => {
        const status = await this.checkServiceStatus(service);
        
        // Add container stats if service is running
        if (status.containerStatus === 'running') {
          status.stats = await this.getContainerStats(service.containerName);
        }
        
        return status;
      })
    );

    return results.map((result, index) => ({
      service: this.services[index].name,
      ...(result.status === 'fulfilled' ? result.value : { 
        status: 'error', 
        error: result.reason?.message || 'Unknown error' 
      })
    }));
  }

  async getSystemHealth() {
    const services = await this.monitorAllServices();
    const healthyCount = services.filter(s => s.status === 'healthy').length;
    const totalCount = services.length;
    
    return {
      overall: healthyCount === totalCount ? 'healthy' : 
               healthyCount > totalCount / 2 ? 'degraded' : 'critical',
      healthy: healthyCount,
      total: totalCount,
      percentage: Math.round((healthyCount / totalCount) * 100),
      services: services,
      timestamp: new Date()
    };
  }
}

module.exports = ServiceMonitor;
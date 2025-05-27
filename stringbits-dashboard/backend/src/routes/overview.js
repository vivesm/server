const express = require('express');
const router = express.Router();
const ServiceMonitor = require('../services/ServiceMonitor');
const os = require('os');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);
const monitor = new ServiceMonitor();

// Get system overview
router.get('/', async (req, res) => {
  try {
    // Get service health
    const systemHealth = await monitor.getSystemHealth();
    
    // Get system info
    const systemInfo = {
      hostname: os.hostname(),
      platform: os.platform(),
      arch: os.arch(),
      uptime: os.uptime(),
      loadAverage: os.loadavg(),
      memory: {
        total: (os.totalmem() / 1024 / 1024 / 1024).toFixed(2), // GB
        free: (os.freemem() / 1024 / 1024 / 1024).toFixed(2), // GB
        used: ((os.totalmem() - os.freemem()) / 1024 / 1024 / 1024).toFixed(2), // GB
        percentage: Math.round(((os.totalmem() - os.freemem()) / os.totalmem()) * 100)
      }
    };
    
    // Get disk usage
    let diskUsage = {};
    try {
      const { stdout } = await execAsync("df -h / | awk 'NR==2 {print $2,$3,$4,$5}'");
      const [total, used, available, percentage] = stdout.trim().split(' ');
      diskUsage = { total, used, available, percentage };
    } catch (error) {
      console.error('Error getting disk usage:', error);
    }
    
    // Get Docker info
    let dockerInfo = {};
    try {
      const { stdout: versionOut } = await execAsync('docker --version');
      const { stdout: infoOut } = await execAsync('docker info --format "Containers: {{.Containers}}, Images: {{.Images}}"');
      
      dockerInfo = {
        version: versionOut.trim(),
        ...Object.fromEntries(infoOut.trim().split(', ').map(item => {
          const [key, value] = item.split(': ');
          return [key.toLowerCase(), parseInt(value) || value];
        }))
      };
    } catch (error) {
      console.error('Error getting Docker info:', error);
    }
    
    // Get Tailscale status
    let tailscaleStatus = null;
    try {
      const { stdout } = await execAsync('tailscale ip -4 2>/dev/null');
      tailscaleStatus = {
        connected: true,
        ip: stdout.trim()
      };
    } catch (error) {
      tailscaleStatus = {
        connected: false,
        error: 'Tailscale not available'
      };
    }
    
    res.json({
      systemHealth,
      systemInfo,
      diskUsage,
      dockerInfo,
      tailscaleStatus,
      timestamp: new Date()
    });
  } catch (error) {
    console.error('Overview error:', error);
    res.status(500).json({ error: 'Failed to fetch overview data' });
  }
});

// Get quick stats
router.get('/stats', async (req, res) => {
  try {
    const services = await monitor.monitorAllServices();
    const healthyServices = services.filter(s => s.status === 'healthy').length;
    
    res.json({
      services: {
        total: services.length,
        healthy: healthyServices,
        unhealthy: services.length - healthyServices
      },
      system: {
        cpuUsage: os.loadavg()[0],
        memoryUsage: Math.round(((os.totalmem() - os.freemem()) / os.totalmem()) * 100),
        uptime: Math.floor(os.uptime() / 3600) // hours
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

module.exports = router;
const express = require('express');
const router = express.Router();
const ServiceMonitor = require('../services/ServiceMonitor');

const monitor = new ServiceMonitor();

// Get all services status
router.get('/', async (req, res) => {
  try {
    const services = await monitor.monitorAllServices();
    res.json({
      services,
      summary: {
        total: services.length,
        healthy: services.filter(s => s.status === 'healthy').length,
        degraded: services.filter(s => s.status === 'degraded').length,
        stopped: services.filter(s => s.status === 'stopped').length,
        error: services.filter(s => s.status === 'error').length
      },
      timestamp: new Date()
    });
  } catch (error) {
    console.error('Services error:', error);
    res.status(500).json({ error: 'Failed to fetch services' });
  }
});

// Get specific service details
router.get('/:serviceName', async (req, res) => {
  try {
    const { serviceName } = req.params;
    const services = monitor.services;
    const service = services.find(s => 
      s.name.toLowerCase() === serviceName.toLowerCase()
    );
    
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }
    
    const status = await monitor.checkServiceStatus(service);
    
    // Add additional details
    if (status.containerStatus === 'running') {
      status.stats = await monitor.getContainerStats(service.containerName);
    }
    
    res.json(status);
  } catch (error) {
    console.error('Service detail error:', error);
    res.status(500).json({ error: 'Failed to fetch service details' });
  }
});

// Restart a service
router.post('/:serviceName/restart', async (req, res) => {
  try {
    const { serviceName } = req.params;
    const docker = monitor.docker;
    
    // Find container
    const containers = await docker.listContainers({ all: true });
    const container = containers.find(c => 
      c.Names.some(name => name.toLowerCase().includes(serviceName.toLowerCase()))
    );
    
    if (!container) {
      return res.status(404).json({ error: 'Service container not found' });
    }
    
    // Restart container
    const containerObj = docker.getContainer(container.Id);
    await containerObj.restart();
    
    res.json({ 
      message: `Service ${serviceName} restart initiated`,
      containerId: container.Id
    });
  } catch (error) {
    console.error('Service restart error:', error);
    res.status(500).json({ error: 'Failed to restart service' });
  }
});

// Get service logs
router.get('/:serviceName/logs', async (req, res) => {
  try {
    const { serviceName } = req.params;
    const { lines = 100 } = req.query;
    const docker = monitor.docker;
    
    // Find container
    const containers = await docker.listContainers({ all: true });
    const container = containers.find(c => 
      c.Names.some(name => name.toLowerCase().includes(serviceName.toLowerCase()))
    );
    
    if (!container) {
      return res.status(404).json({ error: 'Service container not found' });
    }
    
    // Get logs
    const containerObj = docker.getContainer(container.Id);
    const stream = await containerObj.logs({
      stdout: true,
      stderr: true,
      tail: parseInt(lines),
      timestamps: true
    });
    
    // Convert buffer to string
    const logs = stream.toString('utf8');
    
    res.json({ 
      service: serviceName,
      logs: logs.split('\n').filter(line => line.trim() !== ''),
      lines: parseInt(lines)
    });
  } catch (error) {
    console.error('Service logs error:', error);
    res.status(500).json({ error: 'Failed to fetch service logs' });
  }
});

module.exports = router;
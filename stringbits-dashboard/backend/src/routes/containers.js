const express = require('express');
const router = express.Router();
const Docker = require('dockerode');

const docker = new Docker();

// Get all containers
router.get('/', async (req, res) => {
  try {
    const containers = await docker.listContainers({ all: true });
    
    const containerInfo = containers.map(container => ({
      id: container.Id.substring(0, 12),
      name: container.Names[0].replace('/', ''),
      image: container.Image,
      state: container.State,
      status: container.Status,
      created: new Date(container.Created * 1000),
      ports: container.Ports.map(p => ({
        private: p.PrivatePort,
        public: p.PublicPort,
        type: p.Type
      })),
      labels: container.Labels,
      mounts: container.Mounts ? container.Mounts.length : 0
    }));
    
    res.json({
      containers: containerInfo,
      summary: {
        total: containerInfo.length,
        running: containerInfo.filter(c => c.state === 'running').length,
        stopped: containerInfo.filter(c => c.state !== 'running').length
      },
      timestamp: new Date()
    });
  } catch (error) {
    console.error('Containers error:', error);
    res.status(500).json({ error: 'Failed to fetch containers' });
  }
});

// Get specific container details
router.get('/:containerId', async (req, res) => {
  try {
    const { containerId } = req.params;
    const container = docker.getContainer(containerId);
    const info = await container.inspect();
    
    res.json({
      id: info.Id,
      name: info.Name.replace('/', ''),
      created: info.Created,
      state: info.State,
      config: {
        image: info.Config.Image,
        cmd: info.Config.Cmd,
        env: info.Config.Env ? info.Config.Env.filter(e => !e.includes('PASSWORD')) : [],
        labels: info.Config.Labels,
        exposedPorts: info.Config.ExposedPorts
      },
      networkSettings: {
        networks: Object.keys(info.NetworkSettings.Networks),
        ports: info.NetworkSettings.Ports,
        ipAddress: info.NetworkSettings.IPAddress
      },
      mounts: info.Mounts,
      hostConfig: {
        restartPolicy: info.HostConfig.RestartPolicy,
        portBindings: info.HostConfig.PortBindings,
        binds: info.HostConfig.Binds,
        memory: info.HostConfig.Memory,
        cpuShares: info.HostConfig.CpuShares
      }
    });
  } catch (error) {
    console.error('Container detail error:', error);
    res.status(500).json({ error: 'Failed to fetch container details' });
  }
});

// Start a container
router.post('/:containerId/start', async (req, res) => {
  try {
    const { containerId } = req.params;
    const container = docker.getContainer(containerId);
    await container.start();
    
    res.json({ 
      message: 'Container started successfully',
      containerId: containerId
    });
  } catch (error) {
    console.error('Container start error:', error);
    res.status(500).json({ error: 'Failed to start container' });
  }
});

// Stop a container
router.post('/:containerId/stop', async (req, res) => {
  try {
    const { containerId } = req.params;
    const container = docker.getContainer(containerId);
    await container.stop();
    
    res.json({ 
      message: 'Container stopped successfully',
      containerId: containerId
    });
  } catch (error) {
    console.error('Container stop error:', error);
    res.status(500).json({ error: 'Failed to stop container' });
  }
});

// Restart a container
router.post('/:containerId/restart', async (req, res) => {
  try {
    const { containerId } = req.params;
    const container = docker.getContainer(containerId);
    await container.restart();
    
    res.json({ 
      message: 'Container restarted successfully',
      containerId: containerId
    });
  } catch (error) {
    console.error('Container restart error:', error);
    res.status(500).json({ error: 'Failed to restart container' });
  }
});

// Get container logs
router.get('/:containerId/logs', async (req, res) => {
  try {
    const { containerId } = req.params;
    const { lines = 100 } = req.query;
    const container = docker.getContainer(containerId);
    
    const stream = await container.logs({
      stdout: true,
      stderr: true,
      tail: parseInt(lines),
      timestamps: true
    });
    
    const logs = stream.toString('utf8').split('\n').filter(line => line.trim() !== '');
    
    res.json({ 
      containerId: containerId,
      logs: logs,
      lines: parseInt(lines)
    });
  } catch (error) {
    console.error('Container logs error:', error);
    res.status(500).json({ error: 'Failed to fetch container logs' });
  }
});

// Get container stats
router.get('/:containerId/stats', async (req, res) => {
  try {
    const { containerId } = req.params;
    const container = docker.getContainer(containerId);
    const stats = await container.stats({ stream: false });
    
    // Calculate CPU usage
    const cpuDelta = stats.cpu_stats.cpu_usage.total_usage - stats.precpu_stats.cpu_usage.total_usage;
    const systemDelta = stats.cpu_stats.system_cpu_usage - stats.precpu_stats.system_cpu_usage;
    const cpuPercent = (cpuDelta / systemDelta) * 100 * stats.cpu_stats.online_cpus;
    
    // Calculate memory usage
    const memUsage = stats.memory_stats.usage;
    const memLimit = stats.memory_stats.limit;
    const memPercent = (memUsage / memLimit) * 100;
    
    res.json({
      containerId: containerId,
      cpu: {
        percent: cpuPercent.toFixed(2),
        cores: stats.cpu_stats.online_cpus
      },
      memory: {
        usage: (memUsage / 1024 / 1024).toFixed(2), // MB
        limit: (memLimit / 1024 / 1024).toFixed(2), // MB
        percent: memPercent.toFixed(2)
      },
      network: stats.networks,
      blockIO: stats.blkio_stats,
      pids: stats.pids_stats
    });
  } catch (error) {
    console.error('Container stats error:', error);
    res.status(500).json({ error: 'Failed to fetch container stats' });
  }
});

module.exports = router;
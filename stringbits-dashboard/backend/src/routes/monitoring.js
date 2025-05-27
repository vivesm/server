const express = require('express');
const router = express.Router();
const ServiceMonitor = require('../services/ServiceMonitor');
const os = require('os');
const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs').promises;

const execAsync = promisify(exec);
const monitor = new ServiceMonitor();

// Store historical data in memory (in production, use a database)
const historyData = {
  cpu: [],
  memory: [],
  services: []
};

// Get current system metrics
router.get('/metrics', async (req, res) => {
  try {
    const currentTime = new Date();
    
    // CPU metrics
    const cpuUsage = os.loadavg();
    const cpuCount = os.cpus().length;
    
    // Memory metrics
    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    const usedMem = totalMem - freeMem;
    
    // Disk metrics
    let diskMetrics = {};
    try {
      const { stdout } = await execAsync("df -B1 / | awk 'NR==2 {print $2,$3,$4,$5}'");
      const [total, used, available, percentage] = stdout.trim().split(' ');
      diskMetrics = {
        total: parseInt(total),
        used: parseInt(used),
        available: parseInt(available),
        percentage: parseInt(percentage)
      };
    } catch (error) {
      console.error('Disk metrics error:', error);
    }
    
    // Network metrics
    let networkMetrics = {};
    try {
      const { stdout } = await execAsync("cat /proc/net/dev | grep -E 'eth0|ens' | head -1");
      const parts = stdout.trim().split(/\s+/);
      if (parts.length > 10) {
        networkMetrics = {
          interface: parts[0].replace(':', ''),
          rx_bytes: parseInt(parts[1]),
          rx_packets: parseInt(parts[2]),
          tx_bytes: parseInt(parts[9]),
          tx_packets: parseInt(parts[10])
        };
      }
    } catch (error) {
      console.error('Network metrics error:', error);
    }
    
    const metrics = {
      timestamp: currentTime,
      cpu: {
        usage: {
          '1min': cpuUsage[0],
          '5min': cpuUsage[1],
          '15min': cpuUsage[2]
        },
        cores: cpuCount,
        percentage: ((cpuUsage[0] / cpuCount) * 100).toFixed(2)
      },
      memory: {
        total: totalMem,
        used: usedMem,
        free: freeMem,
        percentage: ((usedMem / totalMem) * 100).toFixed(2)
      },
      disk: diskMetrics,
      network: networkMetrics,
      uptime: os.uptime()
    };
    
    // Store in history (keep last 100 data points)
    historyData.cpu.push({
      timestamp: currentTime,
      value: parseFloat(metrics.cpu.percentage)
    });
    historyData.memory.push({
      timestamp: currentTime,
      value: parseFloat(metrics.memory.percentage)
    });
    
    // Trim history
    if (historyData.cpu.length > 100) historyData.cpu.shift();
    if (historyData.memory.length > 100) historyData.memory.shift();
    
    res.json(metrics);
  } catch (error) {
    console.error('Metrics error:', error);
    res.status(500).json({ error: 'Failed to fetch metrics' });
  }
});

// Get historical metrics
router.get('/history', async (req, res) => {
  try {
    const { period = '1h' } = req.query;
    const now = new Date();
    let startTime = new Date();
    
    // Calculate start time based on period
    switch (period) {
      case '15m':
        startTime = new Date(now - 15 * 60 * 1000);
        break;
      case '1h':
        startTime = new Date(now - 60 * 60 * 1000);
        break;
      case '6h':
        startTime = new Date(now - 6 * 60 * 60 * 1000);
        break;
      case '24h':
        startTime = new Date(now - 24 * 60 * 60 * 1000);
        break;
      default:
        startTime = new Date(now - 60 * 60 * 1000);
    }
    
    // Filter history data
    const filteredCpu = historyData.cpu.filter(d => d.timestamp >= startTime);
    const filteredMemory = historyData.memory.filter(d => d.timestamp >= startTime);
    const filteredServices = historyData.services.filter(d => d.timestamp >= startTime);
    
    res.json({
      period,
      startTime,
      endTime: now,
      data: {
        cpu: filteredCpu,
        memory: filteredMemory,
        services: filteredServices
      }
    });
  } catch (error) {
    console.error('History error:', error);
    res.status(500).json({ error: 'Failed to fetch history' });
  }
});

// Get alerts and thresholds
router.get('/alerts', async (req, res) => {
  try {
    const alerts = [];
    const metrics = {
      cpu: ((os.loadavg()[0] / os.cpus().length) * 100),
      memory: ((os.totalmem() - os.freemem()) / os.totalmem() * 100),
      disk: 0
    };
    
    // Get disk usage
    try {
      const { stdout } = await execAsync("df -h / | awk 'NR==2 {print $5}' | sed 's/%//'");
      metrics.disk = parseInt(stdout.trim());
    } catch (error) {
      console.error('Disk check error:', error);
    }
    
    // Check service health
    const systemHealth = await monitor.getSystemHealth();
    
    // Define thresholds
    const thresholds = {
      cpu: { warning: 70, critical: 90 },
      memory: { warning: 80, critical: 95 },
      disk: { warning: 80, critical: 90 },
      services: { warning: 1, critical: 3 } // Number of unhealthy services
    };
    
    // Check CPU
    if (metrics.cpu > thresholds.cpu.critical) {
      alerts.push({
        type: 'cpu',
        level: 'critical',
        message: `CPU usage is critically high: ${metrics.cpu.toFixed(2)}%`,
        value: metrics.cpu,
        threshold: thresholds.cpu.critical
      });
    } else if (metrics.cpu > thresholds.cpu.warning) {
      alerts.push({
        type: 'cpu',
        level: 'warning',
        message: `CPU usage is high: ${metrics.cpu.toFixed(2)}%`,
        value: metrics.cpu,
        threshold: thresholds.cpu.warning
      });
    }
    
    // Check Memory
    if (metrics.memory > thresholds.memory.critical) {
      alerts.push({
        type: 'memory',
        level: 'critical',
        message: `Memory usage is critically high: ${metrics.memory.toFixed(2)}%`,
        value: metrics.memory,
        threshold: thresholds.memory.critical
      });
    } else if (metrics.memory > thresholds.memory.warning) {
      alerts.push({
        type: 'memory',
        level: 'warning',
        message: `Memory usage is high: ${metrics.memory.toFixed(2)}%`,
        value: metrics.memory,
        threshold: thresholds.memory.warning
      });
    }
    
    // Check Disk
    if (metrics.disk > thresholds.disk.critical) {
      alerts.push({
        type: 'disk',
        level: 'critical',
        message: `Disk usage is critically high: ${metrics.disk}%`,
        value: metrics.disk,
        threshold: thresholds.disk.critical
      });
    } else if (metrics.disk > thresholds.disk.warning) {
      alerts.push({
        type: 'disk',
        level: 'warning',
        message: `Disk usage is high: ${metrics.disk}%`,
        value: metrics.disk,
        threshold: thresholds.disk.warning
      });
    }
    
    // Check Services
    const unhealthyCount = systemHealth.total - systemHealth.healthy;
    if (unhealthyCount >= thresholds.services.critical) {
      alerts.push({
        type: 'services',
        level: 'critical',
        message: `${unhealthyCount} services are unhealthy`,
        value: unhealthyCount,
        threshold: thresholds.services.critical,
        services: systemHealth.services.filter(s => s.status !== 'healthy')
      });
    } else if (unhealthyCount >= thresholds.services.warning) {
      alerts.push({
        type: 'services',
        level: 'warning',
        message: `${unhealthyCount} service(s) are unhealthy`,
        value: unhealthyCount,
        threshold: thresholds.services.warning,
        services: systemHealth.services.filter(s => s.status !== 'healthy')
      });
    }
    
    res.json({
      alerts,
      thresholds,
      metrics,
      timestamp: new Date()
    });
  } catch (error) {
    console.error('Alerts error:', error);
    res.status(500).json({ error: 'Failed to fetch alerts' });
  }
});

// Get logs from various sources
router.get('/logs', async (req, res) => {
  try {
    const { source = 'system', lines = 50 } = req.query;
    let logs = [];
    
    switch (source) {
      case 'system':
        try {
          const { stdout } = await execAsync(`journalctl -n ${lines} --no-pager`);
          logs = stdout.trim().split('\n');
        } catch (error) {
          logs = ['Error reading system logs'];
        }
        break;
        
      case 'docker':
        try {
          const { stdout } = await execAsync(`docker events --since 1h --until now | tail -${lines}`);
          logs = stdout.trim().split('\n').filter(line => line);
        } catch (error) {
          logs = ['Error reading Docker logs'];
        }
        break;
        
      case 'monitoring':
        try {
          const logPath = '/home/shared/docker/logs/validation.log';
          const content = await fs.readFile(logPath, 'utf8');
          logs = content.trim().split('\n').slice(-lines);
        } catch (error) {
          logs = ['Monitoring log file not found'];
        }
        break;
        
      default:
        logs = ['Unknown log source'];
    }
    
    res.json({
      source,
      logs,
      lines: logs.length,
      timestamp: new Date()
    });
  } catch (error) {
    console.error('Logs error:', error);
    res.status(500).json({ error: 'Failed to fetch logs' });
  }
});

module.exports = router;
const express = require('express');
const router = express.Router();
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

// Define allowed commands for security
const ALLOWED_COMMANDS = [
  'docker ps',
  'docker stats',
  'docker images',
  'docker network ls',
  'docker volume ls',
  'df',
  'free',
  'uptime',
  'ps aux',
  'netstat',
  'ss',
  'ip addr',
  'tailscale status',
  'systemctl status',
  'journalctl',
  'ls',
  'cat',
  'grep',
  'find',
  'which',
  'whoami',
  'date',
  'hostname'
];

// Check if command is allowed
function isCommandAllowed(command) {
  // Remove flags and arguments for checking
  const baseCommand = command.split(' ')[0];
  
  // Check if it's in the allowed list
  return ALLOWED_COMMANDS.some(allowed => 
    command.startsWith(allowed) || baseCommand === allowed
  );
}

// Execute command endpoint
router.post('/execute', async (req, res) => {
  try {
    const { command } = req.body;
    
    if (!command) {
      return res.status(400).json({ error: 'Command is required' });
    }
    
    // Security check
    if (!isCommandAllowed(command)) {
      return res.status(403).json({ 
        error: 'Command not allowed',
        message: 'This command is restricted for security reasons'
      });
    }
    
    // Add safety flags to certain commands
    let safeCommand = command;
    if (command.startsWith('docker stats') && !command.includes('--no-stream')) {
      safeCommand = command.replace('docker stats', 'docker stats --no-stream');
    }
    if (command.startsWith('journalctl') && !command.includes('-n')) {
      safeCommand += ' -n 100 --no-pager';
    }
    
    // Execute command with timeout
    const { stdout, stderr } = await execAsync(safeCommand, {
      timeout: 30000, // 30 second timeout
      maxBuffer: 1024 * 1024 * 2 // 2MB max output
    });
    
    res.json({
      command: safeCommand,
      output: stdout || stderr,
      timestamp: new Date(),
      success: !stderr || stderr.length === 0
    });
    
  } catch (error) {
    console.error('Command execution error:', error);
    
    if (error.killed) {
      return res.status(408).json({ 
        error: 'Command timeout',
        message: 'Command took too long to execute'
      });
    }
    
    res.status(500).json({ 
      error: 'Command execution failed',
      message: error.message,
      output: error.stdout || error.stderr || ''
    });
  }
});

// Get command history
router.get('/history', async (req, res) => {
  // In a real implementation, this would fetch from a database
  res.json({
    history: [],
    message: 'Command history not yet implemented'
  });
});

// Get allowed commands list
router.get('/allowed', async (req, res) => {
  res.json({
    commands: ALLOWED_COMMANDS,
    categories: {
      docker: ALLOWED_COMMANDS.filter(cmd => cmd.startsWith('docker')),
      system: ['df', 'free', 'uptime', 'ps aux', 'hostname', 'date', 'whoami'],
      network: ['netstat', 'ss', 'ip addr', 'tailscale status'],
      files: ['ls', 'cat', 'grep', 'find', 'which'],
      logs: ['journalctl', 'systemctl status']
    }
  });
});

// Claude Code integration info
router.get('/info', async (req, res) => {
  res.json({
    name: 'StringBits Dashboard Claude Integration',
    version: '1.0.0',
    features: [
      'Execute safe system commands',
      'Docker container management',
      'System monitoring',
      'Log viewing',
      'Network diagnostics'
    ],
    security: 'Commands are restricted to a whitelist for safety'
  });
});

module.exports = router;
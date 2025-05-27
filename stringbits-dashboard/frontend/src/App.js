import React, { useState, useEffect } from 'react';

function App() {
  const [services, setServices] = useState([]);
  const [overview, setOverview] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [darkMode, setDarkMode] = useState(
    localStorage.getItem('darkMode') === 'true'
  );
  const [activeTab, setActiveTab] = useState('overview');

  const API_URL = process.env.REACT_APP_API_URL || 'http://100.112.235.46:3001';

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 30000); // Refresh every 30 seconds
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    localStorage.setItem('darkMode', darkMode);
    document.body.style.backgroundColor = darkMode ? '#1a1a1a' : '#f5f5f5';
  }, [darkMode]);

  const fetchData = async () => {
    try {
      // Fetch services
      const servicesRes = await fetch(`${API_URL}/api/services`);
      if (!servicesRes.ok) throw new Error('Failed to fetch services');
      const servicesData = await servicesRes.json();
      setServices(servicesData.services || []);

      // Fetch overview
      const overviewRes = await fetch(`${API_URL}/api/overview`);
      if (!overviewRes.ok) throw new Error('Failed to fetch overview');
      const overviewData = await overviewRes.json();
      setOverview(overviewData);

      setLoading(false);
    } catch (err) {
      setError(err.message);
      setLoading(false);
    }
  };

  const executeCommand = async (command) => {
    try {
      const response = await fetch(`${API_URL}/api/claude/execute`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ command })
      });
      const result = await response.json();
      return result;
    } catch (err) {
      console.error('Command execution error:', err);
      return { error: err.message };
    }
  };

  if (loading) return <div style={styles.container(darkMode)}>Loading...</div>;
  if (error) return <div style={styles.container(darkMode)}>Error: {error}</div>;

  return (
    <div style={styles.container(darkMode)}>
      <div style={styles.header(darkMode)}>
        <h1 style={styles.title}>StringBits Dashboard</h1>
        <div style={styles.controls}>
          <button 
            onClick={() => setDarkMode(!darkMode)}
            style={styles.modeToggle(darkMode)}
          >
            {darkMode ? '☀️' : '🌙'}
          </button>
        </div>
      </div>

      <div style={styles.tabs}>
        {['overview', 'containers', 'monitoring', 'todos', 'claude'].map(tab => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            style={styles.tab(activeTab === tab, darkMode)}
          >
            {tab.charAt(0).toUpperCase() + tab.slice(1)}
          </button>
        ))}
      </div>

      {activeTab === 'overview' && (
        <>
          <div style={styles.section}>
            <h2>System Overview</h2>
            {overview && (
              <div style={styles.grid}>
                <div style={styles.card(darkMode)}>
                  <h3>System Health</h3>
                  <p>Status: <span style={{color: overview.systemHealth?.overall === 'healthy' ? '#4CAF50' : '#FF9800'}}>
                    {overview.systemHealth?.overall || 'Unknown'}
                  </span></p>
                  <p>Services: {overview.systemHealth?.healthy || 0}/{overview.systemHealth?.total || 0}</p>
                </div>
                <div style={styles.card(darkMode)}>
                  <h3>Memory</h3>
                  <p>Used: {overview.systemInfo?.memory?.used || 0} GB</p>
                  <p>Total: {overview.systemInfo?.memory?.total || 0} GB</p>
                  <p>Usage: {overview.systemInfo?.memory?.percentage || 0}%</p>
                </div>
                <div style={styles.card(darkMode)}>
                  <h3>Disk</h3>
                  <p>Used: {overview.diskUsage?.used || 'N/A'}</p>
                  <p>Total: {overview.diskUsage?.total || 'N/A'}</p>
                  <p>Usage: {overview.diskUsage?.percentage || 'N/A'}</p>
                </div>
                <div style={styles.card(darkMode)}>
                  <h3>Tailscale</h3>
                  <p>Status: {overview.tailscaleStatus?.connected ? 'Connected' : 'Disconnected'}</p>
                  <p>IP: {overview.tailscaleStatus?.ip || 'N/A'}</p>
                </div>
              </div>
            )}
          </div>

          <div style={styles.section}>
            <h2>Services Status</h2>
            <div style={styles.serviceGrid}>
              {services.map((service, index) => (
                <div key={index} style={{
                  ...styles.serviceCard(darkMode),
                  borderColor: service.status === 'healthy' ? '#4CAF50' : 
                              service.status === 'degraded' ? '#FF9800' : '#F44336'
                }}>
                  <h3>{service.service}</h3>
                  <p>Status: <span style={{
                    color: service.status === 'healthy' ? '#4CAF50' : 
                           service.status === 'degraded' ? '#FF9800' : '#F44336'
                  }}>{service.status}</span></p>
                  <p>Container: {service.containerStatus || 'Unknown'}</p>
                  {service.responseTime && <p>Response: {service.responseTime}ms</p>}
                  {service.stats && (
                    <div>
                      <p>CPU: {service.stats.cpu}%</p>
                      <p>Memory: {service.stats.memory?.percent}%</p>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </>
      )}

      {activeTab === 'claude' && (
        <div style={styles.section}>
          <h2>Claude Code Commands</h2>
          <div style={styles.card(darkMode)}>
            <h3>Quick Commands</h3>
            <div style={styles.commandGrid}>
              <button 
                style={styles.commandButton(darkMode)}
                onClick={() => executeCommand('docker ps')}
              >
                List Containers
              </button>
              <button 
                style={styles.commandButton(darkMode)}
                onClick={() => executeCommand('docker stats --no-stream')}
              >
                Container Stats
              </button>
              <button 
                style={styles.commandButton(darkMode)}
                onClick={() => executeCommand('df -h')}
              >
                Disk Usage
              </button>
              <button 
                style={styles.commandButton(darkMode)}
                onClick={() => executeCommand('free -h')}
              >
                Memory Usage
              </button>
            </div>
            <div style={styles.customCommand}>
              <input 
                type="text" 
                placeholder="Enter custom command..."
                style={styles.input(darkMode)}
                onKeyPress={(e) => {
                  if (e.key === 'Enter') {
                    executeCommand(e.target.value);
                    e.target.value = '';
                  }
                }}
              />
            </div>
          </div>
        </div>
      )}

      {activeTab === 'containers' && (
        <div style={styles.section}>
          <h2>Containers - Coming Soon</h2>
        </div>
      )}

      {activeTab === 'monitoring' && (
        <div style={styles.section}>
          <h2>Monitoring - Coming Soon</h2>
        </div>
      )}

      {activeTab === 'todos' && (
        <div style={styles.section}>
          <h2>Todos - Coming Soon</h2>
        </div>
      )}
    </div>
  );
}

const styles = {
  container: (darkMode) => ({
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    padding: '20px',
    maxWidth: '1400px',
    margin: '0 auto',
    backgroundColor: darkMode ? '#1a1a1a' : '#f5f5f5',
    color: darkMode ? '#e0e0e0' : '#333',
    minHeight: '100vh',
    transition: 'background-color 0.3s ease'
  }),
  header: (darkMode) => ({
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '30px',
    borderBottom: `2px solid ${darkMode ? '#333' : '#ddd'}`,
    paddingBottom: '20px'
  }),
  title: {
    textAlign: 'center',
    margin: 0
  },
  controls: {
    display: 'flex',
    gap: '10px'
  },
  modeToggle: (darkMode) => ({
    background: darkMode ? '#333' : '#fff',
    border: `2px solid ${darkMode ? '#555' : '#ddd'}`,
    borderRadius: '8px',
    padding: '8px 12px',
    fontSize: '20px',
    cursor: 'pointer',
    transition: 'all 0.3s ease'
  }),
  tabs: {
    display: 'flex',
    gap: '10px',
    marginBottom: '30px',
    borderBottom: '2px solid #ddd',
    paddingBottom: '10px'
  },
  tab: (active, darkMode) => ({
    padding: '10px 20px',
    border: 'none',
    background: active ? (darkMode ? '#333' : '#fff') : 'transparent',
    color: darkMode ? '#e0e0e0' : '#333',
    borderRadius: '8px 8px 0 0',
    cursor: 'pointer',
    fontWeight: active ? 'bold' : 'normal',
    transition: 'all 0.3s ease'
  }),
  section: {
    marginBottom: '40px'
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
    gap: '20px',
    marginTop: '20px'
  },
  card: (darkMode) => ({
    backgroundColor: darkMode ? '#2a2a2a' : 'white',
    padding: '20px',
    borderRadius: '8px',
    boxShadow: darkMode ? '0 2px 4px rgba(255,255,255,0.1)' : '0 2px 4px rgba(0,0,0,0.1)',
    transition: 'all 0.3s ease'
  }),
  serviceGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
    gap: '20px',
    marginTop: '20px'
  },
  serviceCard: (darkMode) => ({
    backgroundColor: darkMode ? '#2a2a2a' : 'white',
    padding: '20px',
    borderRadius: '8px',
    border: '2px solid',
    boxShadow: darkMode ? '0 2px 4px rgba(255,255,255,0.1)' : '0 2px 4px rgba(0,0,0,0.1)',
    transition: 'all 0.3s ease'
  }),
  commandGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
    gap: '10px',
    marginTop: '20px'
  },
  commandButton: (darkMode) => ({
    padding: '12px 20px',
    border: `1px solid ${darkMode ? '#555' : '#ddd'}`,
    background: darkMode ? '#333' : '#fff',
    color: darkMode ? '#e0e0e0' : '#333',
    borderRadius: '6px',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    ':hover': {
      background: darkMode ? '#444' : '#f0f0f0'
    }
  }),
  customCommand: {
    marginTop: '20px'
  },
  input: (darkMode) => ({
    width: '100%',
    padding: '12px',
    border: `1px solid ${darkMode ? '#555' : '#ddd'}`,
    background: darkMode ? '#333' : '#fff',
    color: darkMode ? '#e0e0e0' : '#333',
    borderRadius: '6px',
    fontSize: '16px'
  })
};

export default App;
import React, { useState, useEffect } from 'react';

function App() {
  const [services, setServices] = useState([]);
  const [overview, setOverview] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const API_URL = process.env.REACT_APP_API_URL || 'http://100.112.235.46:3001';

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 30000); // Refresh every 30 seconds
    return () => clearInterval(interval);
  }, []);

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

  if (loading) return <div style={styles.container}>Loading...</div>;
  if (error) return <div style={styles.container}>Error: {error}</div>;

  return (
    <div style={styles.container}>
      <h1 style={styles.title}>StringBits Dashboard</h1>
      
      <div style={styles.section}>
        <h2>System Overview</h2>
        {overview && (
          <div style={styles.grid}>
            <div style={styles.card}>
              <h3>System Health</h3>
              <p>Status: {overview.systemHealth?.overall || 'Unknown'}</p>
              <p>Services: {overview.systemHealth?.healthy || 0}/{overview.systemHealth?.total || 0}</p>
            </div>
            <div style={styles.card}>
              <h3>Memory</h3>
              <p>Used: {overview.systemInfo?.memory?.used || 0} GB</p>
              <p>Total: {overview.systemInfo?.memory?.total || 0} GB</p>
              <p>Usage: {overview.systemInfo?.memory?.percentage || 0}%</p>
            </div>
            <div style={styles.card}>
              <h3>Disk</h3>
              <p>Used: {overview.diskUsage?.used || 'N/A'}</p>
              <p>Total: {overview.diskUsage?.total || 'N/A'}</p>
              <p>Usage: {overview.diskUsage?.percentage || 'N/A'}</p>
            </div>
            <div style={styles.card}>
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
              ...styles.serviceCard,
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
    </div>
  );
}

const styles = {
  container: {
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    padding: '20px',
    maxWidth: '1200px',
    margin: '0 auto',
    backgroundColor: '#f5f5f5',
    minHeight: '100vh'
  },
  title: {
    textAlign: 'center',
    color: '#333',
    marginBottom: '30px'
  },
  section: {
    marginBottom: '40px'
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
    gap: '20px',
    marginTop: '20px'
  },
  card: {
    backgroundColor: 'white',
    padding: '20px',
    borderRadius: '8px',
    boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
  },
  serviceGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
    gap: '20px',
    marginTop: '20px'
  },
  serviceCard: {
    backgroundColor: 'white',
    padding: '20px',
    borderRadius: '8px',
    border: '2px solid',
    boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
  }
};

export default App;
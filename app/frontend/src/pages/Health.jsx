import { useState, useEffect } from 'react'
import api from '../api/client'

function Health() {
  const [health, setHealth] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [lastChecked, setLastChecked] = useState(null)

  const checkHealth = async () => {
    try {
      setLoading(true)
      const response = await api.get('/health')
      setHealth(response.data)
      setError(null)
      setLastChecked(new Date())
    } catch (err) {
      setError('API is not responding')
      setHealth(null)
      setLastChecked(new Date())
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    checkHealth()
  }, [])

  const getStatusClass = () => {
    if (error) return 'status-error'
    if (!health) return 'status-unknown'
    return health.status === 'healthy' ? 'status-healthy' : 'status-unhealthy'
  }

  return (
    <div className="health-page">
      <h1>API Health Status</h1>
      <div className={`health-card ${getStatusClass()}`}>
        <div className="health-status">
          {loading ? (
            <>
              <div className="loading-spinner small"></div>
              <span>Checking...</span>
            </>
          ) : error ? (
            <>
              <span className="status-icon error">&times;</span>
              <span>API Unavailable</span>
            </>
          ) : health?.status === 'healthy' ? (
            <>
              <span className="status-icon success">&#10003;</span>
              <span>API Healthy</span>
            </>
          ) : (
            <>
              <span className="status-icon warning">!</span>
              <span>API Degraded</span>
            </>
          )}
        </div>
        {health && (
          <div className="health-details">
            <p><strong>Status:</strong> {health.status}</p>
            {health.message && <p><strong>Message:</strong> {health.message}</p>}
            {health.uptime && <p><strong>Uptime:</strong> {health.uptime}</p>}
            {health.timestamp && (
              <p><strong>Timestamp:</strong> {new Date(health.timestamp).toLocaleString()}</p>
            )}
          </div>
        )}
        {error && (
          <p className="error-detail">{error}</p>
        )}
        {lastChecked && (
          <p className="last-checked">Last checked: {lastChecked.toLocaleTimeString()}</p>
        )}
      </div>
      <button
        className="btn btn-primary"
        onClick={checkHealth}
        disabled={loading}
      >
        {loading ? 'Checking...' : 'Check Again'}
      </button>
    </div>
  )
}

export default Health

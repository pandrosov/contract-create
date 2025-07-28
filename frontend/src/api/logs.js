import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || '';

export async function getLogs() {
  try {
    const res = await axios.get(`${API_URL}/logs`, {
      withCredentials: true,
    });
    return res.data || [];
  } catch (error) {
    console.error('Error fetching logs:', error);
    throw error;
  }
} 
import requests
import unittest
import os
import time

class IntegTest(unittest.TestCase):
    
    def setUp(self):
        self.api_url = os.getenv('API_URL', 'http://localhost:8080')
        self.timeout = 30
    
    def test_health(self):
        """Test health endpoint"""
        response = requests.get(f"{self.api_url}/health", timeout=self.timeout)
        self.assertEqual(response.status_code, 200)
    
    def test_post_vote(self):
        """Test vote posting"""
        headers = {
            'Content-Type': 'application/x-www-form-urlencoded',
        }
        response = requests.post(
            f"{self.api_url}/api/vote", 
            headers=headers, 
            data="vote=a",
            timeout=self.timeout
        )
        self.assertEqual(response.status_code, 200)
        # Verify response contains expected fields
        data = response.json()
        self.assertIn('voter_id', data)
        self.assertIn('vote', data)
    
    def test_get_votes(self):
        """Test retrieving votes"""
        response = requests.get(f"{self.api_url}/api/vote", timeout=self.timeout)
        self.assertEqual(response.status_code, 200)

if __name__ == '__main__':
    # Wait for service to be ready
    time.sleep(10)
    unittest.main()
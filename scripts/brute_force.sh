#!/bin/bash
# Brute Force Simulation
# Tries to login 10 times with wrong credentials
echo "Starting Brute Force Simulation..."
for i in {1..10}; do
   curl -s -X POST http://localhost:80/login \
     -H "Content-Type: application/json" \
     -d '{"username":"admin","password":"wrongpassword"}' \
     -o /dev/null -w "Attempt $i: %{http_code}\n"
   sleep 1
done
echo "Simulation Complete."

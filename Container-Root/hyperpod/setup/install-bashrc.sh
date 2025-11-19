#!/bin/bash

echo "/welcome.sh" >> /root/.bashrc

echo "alias q=quota.sh" >> /root/.bashrc
echo "if [ -f /root/env_vars ]; then source /root/env_vars; fi" >> /root/.bashrc


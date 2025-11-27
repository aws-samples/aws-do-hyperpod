#!/bin/bash

echo "/welcome.sh" >> ${HOME}/.bashrc

echo "alias q=quota.sh" >> ${HOME}/.bashrc
echo "if [ -f ${HOME}/env_vars ]; then source ${HOME}/env_vars; fi" >> ${HOME}/.bashrc


#!/bin/bash
set -xe

###############################################################################
# Qlik-Kubernetes-Deployment
###############################################################################
#
# @author      Matthias Greiner
# @contact     Matthias.Greiner@q-nnect.com
# @link        https://q-nnect.com
# @copyright   Copyright (c) 2008-2020 Q-nnect AG <service@q-nnect.com>
# @license         https://q-nnect.com
#

# Prepare "empty" machine by installing docker, kubernetes, etc.
bash deploy_requirements.sh

# Prepare existing kubernetes installation by deploying required services
bash deploy_kubernetes_environment.sh

# Deploy qliksense
bash deploy_qliksense.sh

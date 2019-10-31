FROM mcr.microsoft.com/powershell

# Set variables
ENV ANSIBLE_VERSION 2.8
ENV PACKER_VERSION 1.4.4
ENV PACKER_VSPHERE_PLUGIN_VERSION 2.2
ENV PACKER_WU_PROVISIONER_VERSION 0.7.1

# Ubuntu update and tools install
RUN echo "===> Updating Ubuntu and adding requried packages..." && \
    apt-get update && \
    apt-get install wget unzip python3 software-properties-common python3-pip jq ssh git vim sudo -y curl

# Install node.js
RUN echo "===> Installing node.js" && \
    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - && \
    apt-get install nodejs -y

# Link Python to version 3
RUN echo "==> Link /usr/bin/python to version 3" && \
    unlink /usr/bin/python && \
    ln /usr/bin/python3 /usr/bin/python

# Powershell modules install
RUN echo "===> Installing powershell modules..." && \
    pwsh -c 'Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted' && \
    pwsh -c 'install-module VMware.PowerCLI -force -confirm:$false' && \
    pwsh -c 'Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore -confirm:$false'

# Install Ansible
RUN echo "===> Installing Ansible..." && \
    pip3 install "ansible>=${ANSIBLE_VERSION}" && \
    pip3 install "pywinrm"

# Install Packer and the vsphere-iso builder plugin
RUN echo "===> Installing Packer and the vsphere-iso builder plugin..." && \
   wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
   unzip packer_${PACKER_VERSION}_linux_amd64.zip -d /usr/local/bin && \
   chmod +x /usr/local/bin/packer && \
   wget https://github.com/jetbrains-infra/packer-builder-vsphere/releases/download/v${PACKER_VSPHERE_PLUGIN_VERSION}/packer-builder-vsphere-iso.linux -P /usr/local/bin && \
   chmod +x /usr/local/bin/packer-builder-vsphere-iso.linux

# Install Windows update Packer provisioner
RUN echo "===> Installing Packer Windows Update provisioner..." && \
   wget https://github.com/rgl/packer-provisioner-windows-update/releases/download/v${PACKER_WU_PROVISIONER_VERSION}/packer-provisioner-windows-update-linux.tgz && \
   tar xf packer-provisioner-windows-update-linux.tgz -C /usr/local/bin && \
   chmod +x /usr/local/bin/packer-provisioner-windows-update


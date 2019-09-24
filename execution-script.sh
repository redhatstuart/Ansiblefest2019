############################## Create Demo VM To Be Ansible Host

az group create -l eastus -n ansibleatl
az vm create -g ansibleatl -n ansibleatl --public-ip-address-dns-name ansibleatl --image OpenLogic:CentOS-LVM:7-LVM:7.6.20190130 --ssh-key-value ~/.ssh/id_rsa.pub --accelerated-networking true --size Standard_D2_v2 --admin-username ansibleatl

############################## NSG rule for alternate SSH port

az network nsg rule create -g ansibleatl --nsg-name ansibleatlNSG --name allow-ssh2112 --description "Allow SSH Port 2112" --access Allow --protocol Tcp --direction Inbound --priority 110 --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "*" --destination-port-range "2112"

############################## Provision Demo VM

ssh ansibleatl@YOUR.IP.ADDRESS.OF.AZURE.VM

sudo yum -y install epel-release deltarpm
sudo yum -y install policycoreutils-python libsemanage-devel gcc gcc-c++ kernel-devel python-devel libxslt-devel libffi-devel openssl-devel python2-pip iptables-services git docker podman kubernetes-client
sudo sed -i "s/dport 22/dport 2112/g" /etc/sysconfig/iptables
sudo semanage port -a -t ssh_port_t -p tcp 2112
sudo sed -i "s/#Port 22/Port 2112/g" /etc/ssh/sshd_config
echo "sleep 50" | sudo tee -a /etc/rc.local
echo "chmod 666 /var/run/docker.sock" | sudo tee -a /etc/rc.local
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl restart sshd
sudo systemctl stop firewalld 
sudo systemctl disable firewalld
sudo systemctl mask firewalld
sudo systemctl enable iptables
sudo systemctl start iptables
sudo chmod 755 /etc/rc.local
sudo systemctl enable rc-local
sudo systemctl start rc-local
sudo wget -P /root https://wolverine.itscloudy.af/config/tuneazure.sh
sudo chmod 755 /root/tuneazure.sh                      
sudo /root/tuneazure.sh
sudo wget -P /root https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz
sudo find /root -maxdepth 1 -name '*.tar.gz' -exec sudo tar -xvzf '{}' -C /usr/bin --strip=1 \;

############################## Full Update

sudo yum -y update

############################## Create SP for Ansible

az account list
az ad sp create-for-rbac --name="Ansiblefest2019-Azure" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID_FROM_PREVIOUS_COMMAND"

sudo pip install --upgrade pip
sudo pip install ansible==2.8.5
sudo pip install ansible[azure]
sudo pip install docker
sudo pip install --ignore-installed kubernetes
sudo pip install openshift

sudo mkdir /etc/ansible
echo "[defaults]" | sudo tee -a /etc/ansible/ansible.cfg
echo "system_warnings = False" | sudo tee -a /etc/ansible/ansible.cfg
echo "deprecation_warnings = False" | sudo tee -a /etc/ansible/ansible.cfg
echo "command_warnings = False" | sudo tee -a /etc/ansible/ansible.cfg

############################## Provision Ansible account

git clone https://github.com/stuartatmicrosoft/Ansiblefest2019
ssh-keygen -t rsa -q -P "" -f $HOME/.ssh/id_rsa
echo "export AZURE_CLIENT_ID=" >> $HOME/.bashrc
echo "export AZURE_SECRET=" >> $HOME/.bashrc
echo "export AZURE_SUBSCRIPTION_ID=" >> $HOME/.bashrc
echo "export AZURE_TENANT=" >> $HOME/.bashrc

############################## Create SP for Ansible using AZ CLI

az account list
az ad sp create-for-rbac --name="Ansiblefest2019-Azure" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID_FROM_PREVIOUS_COMMAND"

############################## Populate Credentials File

vi $HOME/.bashrc

############################## Reboot host if you wish

sudo reboot

############################# START PRESENTATION

ssh -p 2112 ansibleatl@YOUR.IP.ADDRESS.OF.AZURE.VM

cd $HOME/Ansiblefest2019

# ~5sec
time ansible-playbook 00-prereqisites.yml

# ~1min
time ansible-playbook 01-build-and-push-to-dockerhub.yml

# ~10sec
time ansible-playbook 02-build-acr-image.yml

# Wait for initial build task in ACR to succeed

# ~40sec
time ansible-playbook 03-create-container-instance.yml
# Make a commit to github to force another update from webhook

# ~9 min
time ansible-playbook 04-aks-create.yml

# ~8 min
time ansible-playbook 05-cosmosdb-deploy.yml

# ~5 sec
time ansible-playbook 06-aks-deploy.yml
# watch kubectl get service

# ~5 sec
time ansible-playbook 07-create-aro.yml
# watch az openshift list

sed -i "s/REPLACE/`grep docker_username vars.yml | awk '{ print $2 }'`/g" deployment-aro.yml
oc login https://openshift.ABC.azmosa.io --token=ABC
oc new-project ansiblefest2019
# Insert Token into vars.yml

# ~5sec
time ansible-playbook 08-aro-deploy.yml
watch oc get svc

############################### RESET
az group delete -n ansibleatl -y
az group delete -n ansiblefestrg -y
az ad sp delete --id http://Ansiblefest2019-Azure
sed -i "/ansibleatl/d" ~/.ssh/known_hosts

# ******************************************************************************************************
# ******** THIS WILL DELETE ALL OF YOUR ARO CLUSTERS IN YOUR ACCOUNT - YOU PROBABLY DONT WANT TO DO THIS
# ******************************************************************************************************

sleep 10
for i in `az openshift list -o json |jq -r '.[].name'`; do az group delete -n $i -y; done


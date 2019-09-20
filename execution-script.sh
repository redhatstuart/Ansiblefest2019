############################## Create Demo VM To Be Ansible Host

az group create -l eastus -n ansibleatl
az vm create -g ansibleatl -n ansibleatl --public-ip-address-dns-name ansibleatl --image OpenLogic:CentOS-LVM:7-LVM:7.6.20190130 --ssh-key-value ~/.ssh/id_rsa.pub --accelerated-networking true --size Standard_D2_v2 --admin-username ansibleatl

############################## NSG rule for alternate SSH port

az network nsg rule create -g ansibleatl --nsg-name ansibleatlNSG --name allow-ssh2112 --description "Allow SSH Port 2112" --access Allow --protocol Tcp --direction Inbound --priority 110 --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "*" --destination-port-range "2112"

############################## Provision Demo VM

ssh ansibleatl@YOUR.IP.ADDRESS.OF.AZURE.VM

sudo yum -y install epel-release deltarpm
sudo yum -y install policycoreutils-python libsemanage-devel gcc gcc-c++ kernel-devel python-devel libxslt-devel libffi-devel openssl-devel python2-pip iptables-services git docker podman
sudo sed -i "s/dport 22/dport 2112/g" /etc/sysconfig/iptables
sudo semanage port -a -t ssh_port_t -p tcp 2112
sudo sed -i "s/#Port 22/Port 2112/g" /etc/ssh/sshd_config
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl restart sshd
sudo systemctl stop firewalld 
sudo systemctl disable firewalld
sudo systemctl mask firewalld
sudo systemctl enable iptables
sudo systemctl start iptables
sudo wget -P /root https://wolverine.itscloudy.af/config/tuneazure.sh
sudo chmod 755 /root/tuneazure.sh                      
sudo /root/tuneazure.sh

############################## Full Update

sudo yum -y update

############################## Reboot host if you wish

sudo reboot 

############################## Create SP for Ansible

az account list
az ad sp create-for-rbac --name="Ansiblefest2019-Azure" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID_FROM_PREVIOUS_COMMAND"

##################################################################################################################### Install Ansible Bits

ssh ansibleatl@YOUR.IP.ADDRESS.OF.AZURE.VM

sudo pip install --upgrade pip
sudo pip install ansible==2.8.5
sudo pip install ansible[azure]
sudo pip install --ignore-installed kubernetes
sudo pip install openshift

############################## Provision Ansible account

git clone https://github.com/stuartatmicrosoft/Ansiblefest2019
ssh-keygen -t rsa -q -P "" -f $HOME/.ssh/id_rsa
echo "export AZURE_CLIENT_ID=" >> $HOME/.bashrc
echo "export AZURE_SECRET=" >> $HOME/.bashrc
echo "export AZURE_SUBSCRIPTION_ID=" >> $HOME/.bashrc
echo "export AZURE_TENANT=" >> $HOME/.bashrc

############################## Populate Credentials File

vi $HOME/.bashrc

############################## Source .bashrc to set new variables

source $HOME/.bashrc

############################## Generate random number and set variables
#
#cd $HOME/Ansiblefest2018
#
#RANDNUM=`shuf -i 20000-50000 -n 1`
#sed -i "s/mmmysqlansiblefestxxxx/mmmysqlansiblefest$RANDNUM/g" vars.yml
#sed -i "s/mmvmpublicipxx/mmvmpublicip$RANDNUM/g" vars.yml
#sed -i "s/vmsspublicipxxy/vmsspublicip$RANDNUM/g" vars.yml
#sed -i "s/appgwpublicipxx/appgwpublicip$RANDNUM/g" vars.yml
#
############################### Run Playbooks 0-3
#
#ansible-playbook 00-prerequisites.yml --extra-vars "@vars.yml"
#ansible-playbook 01-mm-vm-deploy.yml --extra-vars "@vars.yml"
#ansible-playbook 02-create-mysql.yml --extra-vars "@vars.yml"
#ansible-playbook 03-mm-setup.yml --extra-vars "@vars.yml"
#
############################### Test Mattermost App
#
#echo It will take a minute for the server to start
#echo View in web browser - visit http://ip.address.of.mm.server:8065
#
############################### Run Playbooks 4-6
#
#ansible-playbook 04-create-vm-image.yml --extra-vars "@vars.yml"
#ansible-playbook 05-vmss-create.yml --extra-vars "@vars.yml"
#ansible-playbook 06-appgateway-attach.yml --extra-vars "@vars.yml"
#
############################### Test Mattermost App
#
#echo It will take roughly 4 min 30 sec for the server to start
#echo View in web browser - visit http://ip.address.of.ag
#
############################### RESET
az group delete -n ansibleatl -y
az group delete -n ansiblefestrg -y
az ad sp delete --id http://Ansiblefest2019-Azure
sed -i "/ansibleatl/d" ~/.ssh/known_hosts

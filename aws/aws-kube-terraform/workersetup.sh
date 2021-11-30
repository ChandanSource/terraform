sudo apt update && sudo apt install -y gnupg gnupg2 gnupg1 conntrack apt-transport-https ca-certificates curl lsb-release

curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:1.22/Debian_11/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -

curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_11/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -

sudo apt update && sudo apt install -y ca-certificates && sudo apt install -y gnupg gnupg2 gnupg1 conntrack apt-transport-https ca-certificates curl lsb-release

cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_11/ /
EOF

cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:1.22.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.22/Debian_11/ /
EOF

cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo apt update && sudo apt install -y cri-o cri-o-runc && sudo systemctl enable crio --now

curl -O https://packages.cloud.google.com/apt/doc/apt-key.gpg

sudo apt-key add apt-key.gpg

cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt update && sudo apt install -y kubelet kubeadm kubectl && sudo apt-mark hold kubelet kubeadm kubectl

echo "Waiting 260 seconds for control plane to initiate before joining worker node" && sleep 120

sudo bash /tmp/joinworker.sh

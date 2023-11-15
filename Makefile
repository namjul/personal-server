HOST='hobl.at'

.PHONY: install package ssh firewall install_k3s install_helm k8s

install:
	sops -d --extract '["public_key"]' --output ~/.ssh/nam_rsa.pub secrets/ssh.yml
	sops -d --extract '["private_key"]' --output ~/.ssh/nam_rsa.key secrets/ssh.yml
	chmod 600 ~/.ssh/nam_rsa.*
	grep -q hobl.at ~/.ssh/config > /dev/null 2>&1 || cat config/ssh_client_config >> ~/.ssh/config
	mkdir ~/.kube || exit 0
	sops -d --output ~/.kube/config secrets/kubernetes-config.yml

package:
	ssh ${HOST} 'apt-get update && apt-get install -y curl vim'
	# Enable automatic security Updates
	ssh ${HOST} 'echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true" | debconf-set-selections && apt-get install unattended-upgrades -y'

# Check if the file is different from our git repository and if it is the case re-upload and restart the ssh server
ssh:
	ssh ${HOST} "cat /etc/ssh/sshd_config" | diff  - config/sshd_config || (scp config/sshd_config ${HOST}:/etc/ssh/sshd_config && ssh ${HOST} systemctl restart)

firewall:
	scp config/ufw.sh ${HOST}:/tmp/ufw.sh
	ssh ${HOST} 'chmod +x /tmp/ufw.sh && /tmp/ufw.sh'

install_k3s:
	ssh ${HOST} 'export INSTALL_K3S_EXEC=" --disable servicelb --disable traefik --disable local-storage"; curl -sfL https://get.k3s.io | sh -'

k8s:
	kubectl apply -f k8s/ingress-nginx-v1.8.2.yml
	kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

site:
	kubectl apply -f site.yml


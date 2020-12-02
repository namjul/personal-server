.PHONY: install

install:
	sops -d --extract '["public_key"]' --output ~/.ssh/nam_rsa.pub secrets/ssh.yml
	sops -d --extract '["private_key"]' --output ~/.ssh/nam_rsa.key secrets/ssh.yml
	chmod 600 ~/.ssh/nam_rsa.*
	grep -q namart.xyz ~/.ssh/config > /dev/null 2>&1 || cat config/ssh_client_config >> ~/.ssh/config
	mkdir ~/.kube || exit 0

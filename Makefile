.PHONY: lint validate-panel validate-wings install-collections all

all: install-collections lint

install-collections:
	ansible-galaxy collection install -r requirements.yml

lint:
	ansible-lint panel/site.yml
	ansible-lint wings/site.yml

validate-panel:
	ansible-playbook panel/tests/validate.yml -i inventories/panel/hosts.yml

validate-wings:
	ansible-playbook wings/tests/validate.yml -i inventories/wings/hosts.yml

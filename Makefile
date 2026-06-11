.PHONY: test run docker-build terraform-fmt terraform-validate

test:
	pytest -q

run:
	cd app && python app.py

docker-build:
	docker build -t medcare-dashboard:local .

terraform-fmt:
	cd terraform && terraform fmt

terraform-validate:
	cd terraform && terraform init -backend=false && terraform validate

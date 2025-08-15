SHELL:=/bin/bash
TF_DIR:=infra/terraform/envs/prod
.PHONY: tf-init tf-plan tf-apply tf-destroy
tf-init: ; cd $(TF_DIR) && terraform init
tf-plan: ; cd $(TF_DIR) && terraform plan
tf-apply: ; cd $(TF_DIR) && terraform apply -auto-approve
tf-destroy: ; cd $(TF_DIR) && terraform destroy -auto-approve

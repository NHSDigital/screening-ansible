# This file is for you! Edit it to implement your own hooks (make targets) into
# the project as automated steps to be executed on locally and in the CD pipeline.

include scripts/init.mk
-include .env

# ==============================================================================

# Example CI/CD targets are: dependencies, build, publish, deploy, clean, etc.

dependencies: # Install dependencies needed to build and test the project @Pipeline
	# TODO: Implement installation of your project dependencies

build: # Build the project artefact @Pipeline
	mkdir ansible
	cp -r playbooks ansible/
	cp -r roles ansible/
	cp ansible.cfg ansible/
	zip ansible.zip -r ansible
	rm -rf ansible

publish: # Publish the project artefact @Pipeline
	aws s3 cp ansible.zip s3://test-ssm-ansible-ancl11

deploy: # Deploy the project artefact to the target environment @Pipeline
	aws ssm create-association \
		--name "AWS-ApplyAnsiblePlaybooks" \
		--parameters '{
			"SourceType": ["S3"],
			"SourceInfo": ["{\"path\": $BUCKET_URL}"],
			"InstallDependencies": ["True"],
			"PlaybookFile": [$PLAYBOOK_FILE],
			"ExtraVariables": ["SSM=True"],
			"Check": ["False"],
			"Verbose": ["-v"]
		}' \
		--targets '[{"Key":"tag:Name","Values":[$INSTANCE_NAME]}]' \
		--region eu-west-2 \
		--association-name $INSTANCE_NAME

clean:: # Clean-up project resources (main) @Operations
	# TODO: Implement project resources clean-up step

config:: # Configure development environment (main) @Configuration
	# TODO: Use only 'make' targets that are specific to this project, e.g. you may not need to install Node.js
	make _install-dependencies
# ==============================================================================

${VERBOSE}.SILENT: \
	build \
	clean \
	config \
	dependencies \
	deploy \

# Basemap rendering job

basemap-rendering-job-dev.yaml: basemap-rendering-job.yaml
	sed -e 's/%S3_BASEMAP_PATH%/s3:\/\/basemap-locker01\/DEV\//g' \
		-e 's/%ENV_NAME%/dev/g' \
		basemap-rendering-job.yaml > $@

deploy-rendering-job-dev: basemap-rendering-job-dev.yaml
	kubectl apply -f basemap-rendering-job-dev.yaml -n dev-basemap

teardown-rendering-job-dev: basemap-rendering-job-dev.yaml
	kubectl delete -f basemap-rendering-job-dev.yaml -n dev-basemap

basemap-rendering-job-test.yaml: basemap-rendering-job.yaml
	sed -e 's/%S3_BASEMAP_PATH%/s3:\/\/basemap-locker01\/TEST\//g' \
		-e 's/%ENV_NAME%/test/g' \
		basemap-rendering-job.yaml > $@

deploy-rendering-job-test: basemap-rendering-job-test.yaml
	kubectl apply -f basemap-rendering-job-test.yaml -n test-basemap

teardown-rendering-job-test: basemap-rendering-job-test.yaml
	kubectl delete -f basemap-rendering-job-test.yaml -n test-basemap

basemap-rendering-job-prod.yaml: basemap-rendering-job.yaml
	sed -e 's/%S3_BASEMAP_PATH%/s3:\/\/basemap-locker01\/PROD\//g' \
		-e 's/%ENV_NAME%/prod/g' \
		basemap-rendering-job.yaml > $@

deploy-rendering-job-prod: basemap-rendering-job-prod.yaml
	kubectl apply -f basemap-rendering-job-prod.yaml -n prod-basemap

teardown-rendering-job-prod: basemap-rendering-job-prod.yaml
	kubectl delete -f basemap-rendering-job-prod.yaml -n prod-basemap

# Tileserver-GL deployment

tileserver-gl-deployment-dev.yaml: tileserver-gl-deployment.yaml
	sed -e 's/%TIER%/dev/g' \
		-e 's/%PORT%/3000/g' \
		-e 's/%S3_BASEMAP_PATH%/s3:\/\/basemap-locker01\/DEV\//g' \
		tileserver-gl-deployment.yaml > $@

deploy-tileserver-gl-dev: tileserver-gl-deployment-dev.yaml
	kubectl apply -f tileserver-gl-deployment-dev.yaml -n dev-basemap

teardown-tileserver-gl-dev: tileserver-gl-deployment-dev.yaml
	kubectl delete -f tileserver-gl-deployment-dev.yaml -n dev-basemap

tileserver-gl-deployment-test.yaml: tileserver-gl-deployment.yaml
	sed -e 's/%TIER%/test/g' \
		-e 's/%PORT%/3001/g' \
		-e 's/%S3_BASEMAP_PATH%/s3:\/\/basemap-locker01\/TEST\//g' \
		tileserver-gl-deployment.yaml > $@

deploy-tileserver-gl-test: tileserver-gl-deployment-test.yaml
	kubectl apply -f tileserver-gl-deployment-test.yaml -n test-basemap

teardown-tileserver-gl-test: tileserver-gl-deployment-test.yaml
	kubectl delete -f tileserver-gl-deployment-test.yaml -n test-basemap

tileserver-gl-deployment-prod.yaml: tileserver-gl-deployment.yaml
	sed -e 's/%TIER%/prod/g' \
		-e 's/%PORT%/3002/g' \
		-e 's/%S3_BASEMAP_PATH%/s3:\/\/basemap-locker01\/PROD\//g' \
		tileserver-gl-deployment.yaml > $@

deploy-tileserver-gl-prod: tileserver-gl-deployment-prod.yaml
	kubectl apply -f tileserver-gl-deployment-prod.yaml -n prod-basemap

teardown-tileserver-gl-prod: tileserver-gl-deployment-prod.yaml
	kubectl delete -f tileserver-gl-deployment-prod.yaml -n prod-basemap

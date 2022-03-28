# SPDX-FileCopyrightText: 2021-present Open Networking Foundation <info@opennetworking.org>
#
# SPDX-License-Identifier: Apache-2.0

# If any command in a pipe has nonzero status, return that status
SHELL = bash -o pipefail

export CGO_ENABLED=1
export GO111MODULE=on

.PHONY: build

KIND_CLUSTER_NAME           ?= kind
DOCKER_REPOSITORY           ?= onosproject/
ONOS_CHRONOS_EXPORTER_VERSION ?= latest
LOCAL_CHRONOS_EXPORTER         ?=
OAPI_CODEGEN_VERSION := v1.7.0

all: build images

build-tools:=$(shell if [ ! -d "./build/build-tools" ]; then cd build && git clone https://github.com/onosproject/build-tools.git; fi)
include ./build/build-tools/make/onf-common.mk

images: # @HELP build simulators image
images: chronos-exporter-docker rasa-model-server-docker rasa-action-server-docker rasa-sanic-docker

.PHONY: local-chronos-exporter
local-chronos-exporter:
ifdef LOCAL_CHRONOS_EXPORTER
	rm -rf ./local-chronos-exporter
	cp -a ${LOCAL_CHRONOS_EXPORTER} ./local-chronos-exporter
endif

build: # @HELP build the go binary in the cmd/chronos-exporter package
build: local-chronos-exporter
	go build -o build/_output/chronos-exporter ./cmd/chronos-exporter

openapi-spec-validator: # @HELP install openapi-spec-validator
	openapi-spec-validator -h || python -m pip install openapi-spec-validator==0.3.1

openapi-linters: # @HELP lints the Open API specifications
openapi-linters: openapi-spec-validator
	openapi-spec-validator api/config-openapi3.yaml
	openapi-spec-validator api/alerts-openapi3.yaml
	openapi-spec-validator api/aether-2.0.0-openapi3.yaml

oapi-codegen: # @HELP check that the oapi-codegen tool exists
	oapi-codegen || ( cd .. && go install github.com/deepmap/oapi-codegen/cmd/oapi-codegen@${OAPI_CODEGEN_VERSION})

oapi-codegen-config: # @HELP generate openapi types from config-openapi3.yaml
oapi-codegen-config: oapi-codegen
	oapi-codegen \
		-generate types -package collector \
		-o pkg/collector/config-types.go api/config-openapi3.yaml
	sed -i -E 's/json\:"(.+)"/json:"\1"\ yaml\:"\1"/g' pkg/collector/config-types.go
	oapi-codegen \
		-generate server -package collector \
		-o pkg/collector/config-server.go api/config-openapi3.yaml
	sed -i '1i// Code generated by oapi-codegen. DO NOT EDIT.' pkg/collector/config-*.go

oapi-codegen-aether: # @HELP generate openapi types from config-openapi3.yaml
oapi-codegen-aether: oapi-codegen
	oapi-codegen \
		-generate types -package aether \
		-o pkg/aether/config-types.go api/aether-2.0.0-openapi3.yaml
	sed -i -E 's/json\:"(.+)"/json:"\1"\ yaml\:"\1"/g' pkg/aether/config-types.go
	oapi-codegen \
		-generate server -package aether \
		-o pkg/aether/config-server.go api/aether-2.0.0-openapi3.yaml
	sed -i 's/ctx.Param(\"target\")/Target(ctx.Param(\"target\"))/g' pkg/aether/config-server.go
	sed -i '1i// Code generated by oapi-codegen. DO NOT EDIT.' pkg/aether/config-*.go

oapi-codegen-alerts: oapi-codegen
	oapi-codegen \
		-generate types -package alerts \
		-o pkg/alerts/alerts-types.go api/alerts-openapi3.yaml
	sed -i -E 's/json\:"(.+)"/json:"\1"\ yaml\:"\1"/g' pkg/alerts/alerts-types.go
	oapi-codegen \
		-generate server -package alerts \
		-o pkg/alerts/alerts-server.go api/alerts-openapi3.yaml
	sed -i '1i// Code generated by oapi-codegen. DO NOT EDIT.' pkg/alerts/alerts-*.go

test: build deps license linters openapi-linters
	go test -cover -race github.com/onosproject/chronos-exporter/pkg/...
	go test -cover -race github.com/onosproject/chronos-exporter/cmd/...

jenkins-test:  # @HELP run the unit tests and source code validation producing a junit style report for Jenkins
jenkins-test: build deps license linters
	TEST_PACKAGES=github.com/onosproject/chronos-exporter/... ./build/build-tools/build/jenkins/make-unit

chronos-exporter-docker: local-chronos-exporter
	docker build . -f build/chronos-exporter/Dockerfile \
	-t ${DOCKER_REPOSITORY}chronos-exporter:${ONOS_CHRONOS_EXPORTER_VERSION}

rasa-model-server-docker:
	docker build . -f build/rasa-model-server/Dockerfile \
	-t ${DOCKER_REPOSITORY}rasa-model-server:${ONOS_CHRONOS_EXPORTER_VERSION}

rasa-action-server-docker:
	docker build . -f build/rasa-action-server/Dockerfile \
	-t ${DOCKER_REPOSITORY}rasa-action-server:${ONOS_CHRONOS_EXPORTER_VERSION}

rasa-sanic-docker:
	docker build . -f build/rasa-sanic/Dockerfile \
	-t ${DOCKER_REPOSITORY}rasa-sanic:${ONOS_CHRONOS_EXPORTER_VERSION}

kind: # @HELP build Docker images and add them to the currently configured kind cluster
kind: images kind-only

kind-only: # @HELP deploy the image without rebuilding first
kind-only:
	@if [ "`kind get clusters`" = '' ]; then echo "no kind cluster found" && exit 1; fi
	kind load docker-image --name ${KIND_CLUSTER_NAME} ${DOCKER_REPOSITORY}chronos-exporter:${ONOS_CHRONOS_EXPORTER_VERSION}

publish: # @HELP publish version on github and dockerhub
	./build/build-tools/publish-version ${VERSION} onosproject/chronos-exporter

jenkins-publish: # @HELP Jenkins calls this to publish artifacts
jenkins-publish: jenkins-tools
	./build/bin/push-images
	./build/build-tools/release-merge-commit

clean:: # @HELP remove all the build artifacts
	rm -rf ./build/_output
	rm -rf ./vendor
	rm -rf ./cmd/chronos-exporter/chronos-exporter
	rm -rf ./rasa-models/rasa/models
	rm -rf ./rasa-models/rasa/.rasa
	rm -rf ./rasa-models/rasa/.config
	rm -rf ./rasa-models/rasa/.keras

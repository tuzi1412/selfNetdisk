MODULE:=selfnetdisk
SRC_FILES:=$(shell find . -type f -name '*.go')
BIN_FILE:=selfnetdisk
BIN_CMD=$(shell echo $(@:$(OUTPUT)/%/bin/$(BIN_FILE)=%)  | sed 's:/v:/:g' | awk -F '/' '{print "CGO_ENABLED=0 GOOS="$$1" GOARCH="$$2" GOARM="$$3" go build"}') -o $@ ${GO_FLAGS} .
COPY_DIR:=output
PLATFORM_ALL:=linux/amd64 linux/arm/v7
#PLATFORM_ALL:=darwin/amd64 linux/amd64 linux/arm64 linux/386 linux/arm/v7 linux/arm/v6 linux/arm/v5 linux/ppc64le linux/s390x

VERSION:=v1.0.0

ifndef PLATFORMS
	GO_OS:=$(shell go env GOOS)
	GO_ARCH:=$(shell go env GOARCH)
	GO_ARM:=$(shell go env GOARM)
	PLATFORMS:=$(if $(GO_ARM),$(GO_OS)/$(GO_ARCH)/$(GO_ARM),$(GO_OS)/$(GO_ARCH))
	ifeq ($(GO_OS),darwin)
		PLATFORMS+=linux/amd64
	endif
else ifeq ($(PLATFORMS),all)
	override PLATFORMS:=$(PLATFORM_ALL)
endif

REGISTRY?=
XFLAGS?=--load
XPLATFORMS:=$(shell echo $(filter-out darwin/amd64,$(PLATFORMS)) | sed 's: :,:g')

OUTPUT:=output
OUTPUT_MODS:=$(PLATFORMS:%=$(OUTPUT)/%)
OUTPUT_BINS:=$(OUTPUT_MODS:%=%/bin/$(BIN_FILE))
OUTPUT_IMAGE:=$(OUTPUT_MODS:%=%/image/$(MODULE)-$(VERSION).tar)

.PHONY: all
all: $(OUTPUT_BINS)

$(OUTPUT_BINS): $(SRC_FILES)
	@echo "BUILD $@"
	@install -d -m 0755 $(dir $@)
	$(BIN_CMD)

.PHONY: image
image: $(OUTPUT_BINS)
	@echo "BUILDX: $(REGISTRY)$(MODULE):$(VERSION)"
	@-docker buildx create --name tyf
	@docker buildx use tyf
	docker buildx build $(XFLAGS) --platform $(XPLATFORMS) -t $(REGISTRY)$(MODULE):$(VERSION) -f Dockerfile $(COPY_DIR)
	@install -d -m 0755 $(OUTPUT_MODS:%=%/image)
	@docker save -o $(OUTPUT_IMAGE) $(REGISTRY)$(MODULE):$(VERSION)

.PHONY: rebuild
rebuild: clean all

.PHONY: clean
clean:
	@rm -rf $(OUTPUT) 




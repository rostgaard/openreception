-include makefile.setup

PWD=$(shell pwd)
TIMESTAMP=$(shell date +%s)

PREFIX?=/opt/openreception/bin

RELEASE=$(shell git tag | tail -n1)
GIT_REV=$(shell git rev-parse --short HEAD)

BUILD_DIR?=build
RUNNABLES=bin/authserver.dart \
	  bin/calendarserver.dart \
	  bin/callflowcontrol.dart \
	  bin/cdrserver.dart \
	  bin/configserver.dart \
	  bin/contactserver.dart \
	  bin/dialplanserver.dart \
	  bin/messagedispatcher.dart \
	  bin/messageserver.dart \
	  bin/notificationserver.dart \
	  bin/receptionserver.dart \
	  bin/userserver.dart

all: $(BUILD_DIR) snapshots

$(BUILD_DIR):
	-@mkdir $(BUILD_DIR)

snapshots-no-rev: $(BUILD_DIR) \
	   $(BUILD_DIR)/authserver.dart \
	   $(BUILD_DIR)/calendarserver.dart \
	   $(BUILD_DIR)/callflowcontrol.dart \
	   $(BUILD_DIR)/cdrserver.dart \
	   $(BUILD_DIR)/configserver.dart \
	   $(BUILD_DIR)/contactserver.dart \
	   $(BUILD_DIR)/dialplanserver.dart \
	   $(BUILD_DIR)/messagedispatcher.dart \
	   $(BUILD_DIR)/messageserver.dart \
	   $(BUILD_DIR)/notificationserver.dart \
	   $(BUILD_DIR)/receptionserver.dart \
	   $(BUILD_DIR)/userserver.dart


snapshots: $(BUILD_DIR) \
	   $(BUILD_DIR)/authserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/calendarserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/callflowcontrol-$(GIT_REV).dart \
	   $(BUILD_DIR)/cdrserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/configserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/contactserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/dialplanserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/messagedispatcher-$(GIT_REV).dart \
	   $(BUILD_DIR)/messageserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/notificationserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/receptionserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/userserver-$(GIT_REV).dart

.PHONY: binaries
binaries: $(BUILD_DIR) \
	   $(BUILD_DIR)/authserver \
	   $(BUILD_DIR)/calendarserver \
	   $(BUILD_DIR)/callflowcontrol \
	   $(BUILD_DIR)/configserver \
	   $(BUILD_DIR)/contactserver \
	   $(BUILD_DIR)/dialplanserver \
	   $(BUILD_DIR)/messagedispatcher \
	   $(BUILD_DIR)/messageserver \
	   $(BUILD_DIR)/notificationserver \
	   $(BUILD_DIR)/receptionserver \
	   $(BUILD_DIR)/userserver



$(BUILD_DIR)/%-$(GIT_REV).dart: bin/%.dart
	dart --snapshot=$@ $<

$(BUILD_DIR)/%.dart: bin/%.dart
	dart --snapshot=$@ $<

$(BUILD_DIR)/%-$(GIT_REV): bin/%.dart
	dart2native $@.dart -o $<

$(BUILD_DIR)/%: bin/%.dart
	dart2native $< -o $@

analyze-all: analyze analyze-hints

analyze:
	@(dartanalyzer --no-hints --fatal-warnings $(RUNNABLES))

analyze-hints:
	@echo "! (dartanalyzer $(RUNNABLES) | grep '^\[')" | bash

dependencies: pubspec.lock

pubspec.lock: pubspec.yaml
	@pub upgrade

upgrade-dependency:
	@pub upgrade

clean:
	-rm -rf $(BUILD_DIR)

install: build
	install --directory ${PREFIX}
	install --target-directory=${PREFIX} \
	   $(BUILD_DIR)/authserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/calendarserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/callflowcontrol-$(GIT_REV).dart \
	   $(BUILD_DIR)/cdrserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/datastore-$(GIT_REV).dart \
	   $(BUILD_DIR)/configserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/contactserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/dialplanserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/messagedispatcher-$(GIT_REV).dart \
	   $(BUILD_DIR)/messageserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/notificationserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/receptionserver-$(GIT_REV).dart \
	   $(BUILD_DIR)/userserver-$(GIT_REV).dart

install-symlinks: install
	ln -s ${PREFIX}/authserver-$(GIT_REV).dart ${PREFIX}/authserver.dart
	ln -s ${PREFIX}/calendarserver-$(GIT_REV).dart ${PREFIX}/calendarserver.dart
	ln -s ${PREFIX}/callflowcontrol-$(GIT_REV).dart ${PREFIX}/callflowcontrol.dart
	ln -s ${PREFIX}/cdrserver-$(GIT_REV).dart ${PREFIX}/cdrserver.dart
	ln -s ${PREFIX}/datastore-$(GIT_REV).dart ${PREFIX}/cdrserver.dart
	ln -s ${PREFIX}/configserver-$(GIT_REV).dart ${PREFIX}/configserver.dart
	ln -s ${PREFIX}/contactserver-$(GIT_REV).dart ${PREFIX}/contactserver.dart
	ln -s ${PREFIX}/dialplanserver-$(GIT_REV).dart ${PREFIX}/dialplanserver.dart
	ln -s ${PREFIX}/messagedispatcher-$(GIT_REV).dart ${PREFIX}/messagedispatcher.dart
	ln -s ${PREFIX}/messageserver-$(GIT_REV).dart ${PREFIX}/messageserver.dart
	ln -s ${PREFIX}/notificationserver-$(GIT_REV).dart ${PREFIX}/notificationserver.dart
	ln -s ${PREFIX}/receptionserver-$(GIT_REV).dart ${PREFIX}/receptionserver.dart
	ln -s ${PREFIX}/userserver-$(GIT_REV).dart ${PREFIX}/userserver.dart

remove-symlinks:
	-rm ${PREFIX}/authserver.dart
	-rm ${PREFIX}/calendarserver.dart
	-rm ${PREFIX}/callflowcontrol.dart
	-rm ${PREFIX}/cdrserver.dart
	-rm ${PREFIX}/datastore.dart
	-rm ${PREFIX}/configserver.dart
	-rm ${PREFIX}/contactserver.dart
	-rm ${PREFIX}/dialplanserver.dart
	-rm ${PREFIX}/messagedispatcher.dart
	-rm ${PREFIX}/messageserver.dart
	-rm ${PREFIX}/notificationserver.dart
	-rm ${PREFIX}/receptionserver.dart
	-rm ${PREFIX}/userserver.dart

default-config: lib/configuration.dart

clean-config:
	-rm lib/configuration.dart

lib/configuration.dart:
	install lib/configuration.dart.dist lib/configuration.dart

PROMETHEUS_BIN=/home/tim/prometheus-2.55.0-rc.0.linux-amd64/prometheus
CONFIG_FILE=/home/tim/prometheus-2.55.0-rc.0.linux-amd64/prometheus.yml
STORAGE_PATH=/var/lib/prometheus/
CONSOLES_PATH=/home/tim/prometheus-2.55.0-rc.0.linux-amd64/consoles
CONSOLE_LIBRARIES_PATH=/home/tim/prometheus-2.55.0-rc.0.linux-amd64/console_libraries

prom:
	$(PROMETHEUS_BIN) --config.file=$(CONFIG_FILE) --storage.tsdb.path=$(STORAGE_PATH) --web.console.templates=$(CONSOLES_PATH) --web.console.libraries=$(CONSOLE_LIBRARIES_PATH)

.PHONY: prom

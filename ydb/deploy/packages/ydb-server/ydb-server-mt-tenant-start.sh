#!/bin/bash
set -e

ydbd_service_tenant_config="$YDBD_SERVICE_TENANT_DIR/config.json"
ydbd_service_syslog_tag="ydbd_$YDBD_SERVICE_TENANT"

if [ ! -f "$ydbd_service_tenant_config" ]; then
  logger -p daemon.err -t "$ydbd_service_syslog_tag" "No YDB tenant ($YDBD_SERVICE_TENANT) configuration file at: $ydbd_service_tenant_config"
  exit 1
fi

read_config_value() {
  field=$1
  value=$(jq -r ".$field | select(.!=null)" "$ydbd_service_tenant_config")

  if [ -z "$value" ]; then
    logger -p daemon.err -t "$ydbd_service_syslog_tag" "Required field $field not exists in config"
    return 2
  fi

  echo "$value"
}

optional_args=""

if [ -f "$YDBD_SERVICE_MAIN_DIR/token/ydbd.token" ]; then
  optional_args="--auth-token-file $YDBD_SERVICE_MAIN_DIR/token/ydbd.token"
fi

ydbd_service_grpc_port=$(read_config_value grpc_port) || exit 2
ydbd_service_ic_port=$(read_config_value ic_port) || exit 2
ydbd_service_mon_port=$(read_config_value mon_port) || exit 2
ydbd_service_database=$(read_config_value database) || exit 2

exec "$YDBD_SERVICE_MAIN_DIR/bin/ydbd" server \
  --yaml-config "$YDBD_SERVICE_MAIN_DIR/cfg/config.yaml" \
  --log-level 3 \
  --syslog \
  --syslog-service-tag "$ydbd_service_syslog_tag" \
  --tcp \
  --node-broker-port 2135 \
  --grpc-port "$ydbd_service_grpc_port" \
  --ic-port "$ydbd_service_ic_port" \
  --mon-port "$ydbd_service_mon_port" \
  --tenant "$ydbd_service_database" $optional_args

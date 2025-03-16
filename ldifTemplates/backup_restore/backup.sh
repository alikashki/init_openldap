#!/bin/bash

set -e

BACKUP_PATH=/export/backup
SLAPCAT=/usr/sbin/slapcat

nice ${SLAPCAT} -b "cn=config" > ${BACKUP_PATH}/config.ldif
nice ${SLAPCAT} -b "dc=part,dc=local" > ${BACKUP_PATH}/dit.ldif
chown root:root ${BACKUP_PATH}/*
chmod 600 ${BACKUP_PATH}/*.ldif

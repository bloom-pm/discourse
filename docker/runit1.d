#!/bin/bash
touch /var/log/syslog   && chown -f root:adm /var/log/syslog*
touch /var/log/auth.log && chown -f root:adm /var/log/auth.log*
touch /var/log/kern.log && chown -f root:adm /var/log/kern.log*
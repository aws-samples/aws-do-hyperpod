#!/bin/bash

help(){
	echo ""
	echo "Usage: $0 <node_name>"
	echo "       node_name - required, partial or full node name on which to inject fault"
	echo "                   that can only be corrected with a node replacement"
	echo ""
}

if [ "$1" == "" ]; then
	help
else

	node_name=$1

	CMD="export current_time=\$(date +%s); export time_plus_2_minutes=\$((current_time + 120)); export formatted_date=\$(date -d @\$time_plus_2_minutes +'%b %d %H:%M:%S'); echo \${formatted_date} 'ip-10-2-248-222 kernel: [ 378.703529] NVRM: Xid (PCI:0000:b9:00): 74, pid=<unknown>, name=<unknown>, NVLink: fatal error detected on link 6(0x10000, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)' > /tmp/fault.txt; cat /tmp/fault.txt; cat /tmp/fault.txt >> /var/log/messages"

	node-exec.sh $node_name "$CMD"

fi


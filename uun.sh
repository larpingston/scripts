#!/bin/sh
while :
do
	printf "1 on\n2 off\n3 status\n4 exit\n> "
	read x
	case "$x" in
		1) sudo sysctl -w kernel.unprivileged_userns_clone=1 ;;
		2) sudo sysctl -w kernel.unprivileged_userns_clone=0 ;;
		3) sysctl kernel.unprivileged_userns_clone ;;
		4) exit ;;
	esac
done
```


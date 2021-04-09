#!/bin/bash -eu
runpatch()
{
	FILE="$1"
	POS=$(LANG=C LC_ALL=C grep -obUaP -m1 "\xC7\x83\xD0\x05\x00\x00\x19\x00\x00\x00\x41\xBC\xED\xFF\xFF\xFF" "$FILE" | cut -d: -f1)
	if test -z "$POS"; then
		echo "Needle is missing, aborting..." >&2
		return
	fi
	printf "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x41\xBC\x00\x00\x00\x00" | dd of="$FILE" bs=1 seek="$POS" conv=notrunc
	POS=$(LANG=C LC_ALL=C grep -obUa "~Module signature appended~" "$FILE" | cut -d: -f1)
	if test -n "$POS"; then
		echo "Disabling signature check..." >&2
		printf "~No more signature checks.~" | dd of="$FILE" bs=1 seek="$POS" conv=notrunc
	fi
}

detect()
{
	echo "Checking $1..."
	MD5=$(md5sum - < $1 | cut -d' ' -f1)
	if [ "$MD5" = "05968682e5aff64234f4960029029e81" ]; then
		echo "Known version, patching..."
		runpatch $1
	elif [ "$MD5" = "793b5db3a0b7744535bd26dfa2012506" ]; then
		echo "Already patched."
	else
		echo "Unknown version: $MD5."
	fi
}

main()
{
	detect /lib/modules/$(uname -r)/kernel/drivers/net/ethernet/intel/ixgbe/ixgbe.ko
}

main "${1:-}"


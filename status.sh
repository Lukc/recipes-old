#!/usr/bin/env zsh

for packager in Youbi piernov Kooda Lukc; do
	echo "%% {{ $packager }} %%"
	: > log.$packager
	for i in *; do
		if [[ "$i" = includes || "$i" =~ log\..* || "$i" = status.sh ]]; then
			continue
		fi
		(
			cd "$i"
			if egrep -q "$packager" Pkgfile*; then
				echo "-- [[ $i ]]"
				pkg++ -cp 2>&1 | tee -a ../log.$packager
			fi
		)
	done
	echo -n "Errors:           "; grep "ERROR:" log.$packager | wc -l
	echo -n "Warnings:         "; grep "WARNING:" log.$packager | wc -l
	echo -n "Correct packages: "; grep "Everything is in perfect order." log.$packager | wc -l
done



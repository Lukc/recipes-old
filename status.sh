#!/usr/bin/env zsh

# Things to avoid having too much parsing errors. o/
PKGMK_ROOT=.

export PATH="$PATH:/usr/libexec/pkg++/"
alias use=true
alias use_with=true
alias use_enable=true
. /etc/pkg++/*/uses
include() {
	for p in . ../includes /usr/share/pkg++/includes; do
		[[ -e $p/$1 ]] && . $p/$1 && return 0
	done
}

echo "=== {{ pkg++ standards compliance }} ==="

for packager in Youbi Kooda Lukc; do
	echo "%% {{ $packager }} %%"
	: > log.$packager
	for i in *; do
		if [[ "$i" = includes || "$i" =~ log\..* || "$i" = status.sh ]]; then
			continue
		fi
		(
			cd "$i"
			if egrep -q "$packager" Pkgfile*; then
				{
					echo "-- [[ $i ]]"
					pkg++ -cp 2>&1
				} | tee -a ../log.$packager
			fi
		)
	done
	echo -n "Errors:           "; grep "ERROR:" log.$packager | wc -l
	echo -n "Warnings:         "; grep "WARNING:" log.$packager | wc -l
	echo -n "Correct packages: "; grep "Everything is in perfect order." log.$packager | wc -l
done

echo "=== {{ Orphan packages }} ==="

for i in *; do
	if [[ "$i" = includes || "$i" =~ log\..* || "$i" = status.sh ]]; then
		continue
	fi
	(
		cd "$i"
		local pkgfile="$(ls | grep Pkgfile | (tail -n 1 || cat))"
		. ./$pkgfile
		if [[ -z "$maintainer" || -z "$packager" ]]; then
			echo "-- [[ $i ]]"
		fi
		if [[ -z "$maintainer" ]]; then
			echo "  > No maintainer."
		fi
		if [[ -z "$packager" ]]; then
			echo "  > No packager."
		fi
	)
done

echo "=== {{ useflags }} ==="

for i in *; do
	if [[ "$i" = includes || "$i" =~ log\..* || "$i" = status.sh ]]; then
		continue
	fi
	(
		cd "$i"
		local pkgfile="$(ls | grep Pkgfile | (tail -n 1 || cat))"
		. ./$pkgfile
		if [[ -n "${iuse[@]}" ]]; then
			echo "-- [[ $i ]]"
			echo "  > iuse declared"
			for flag in ${iuse[@]}; do
				if [[ -n "$(eval echo "\$use_$flag")" ]]; then
					echo "    > $flag"
				else
					echo "    > $flag [not defined]"
				fi
			done
		fi
	)
done


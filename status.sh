#!/usr/bin/env zsh

VERSION=0.1.0

: ${OUTPUT:=txt} # (x)html is to come soon!

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

is_a_port() {
	if [[ "$1" = includes || "$1" =~ log\..* || "$1" =~ .*\.sh || "$1" = tmp\..* || ! -d "$1" ]]; then
		return 1
	fi
}

# Display, I/O (more O than I, btw)

html_escape() {
	local string="$@"
	string=${string//&/&amp;}
	string=${string//</&lt;}
	string=${string//>/&gt;}
	echo -n "$string"
}

title() {
	if [[ "$OUTPUT" = html ]]; then
		echo "<h2>$(html_escape "$@")</h2>"
	else
		echo "=== {{ $@ }} ==="
	fi
}

subtitle() {
	if [[ "$OUTPUT" = html ]]; then
		echo "<h3>$(html_escape "$@")</h3>"
	else
		echo "-= {{ $@ }} =-"
	fi
}

subsubtitle() {
	if [[ "$OUTPUT" = html ]]; then
		echo "<h4>$(html_escape "$@")</h4>"
	else
		echo "-- [[ $@ ]]"
	fi
}

info() {
	if [[ "$OUTPUT" = html ]]; then
		echo "<div class=\"info\">$@</div>"
	else
		echo "  > $@"
	fi
}

subinfo() {
	if [[ "$OUTPUT" = html ]]; then
		echo "<div class=\"subinfo\">$@</div>"
	else
		echo "    > $@"
	fi
}

if [[ "$OUTPUT" = html ]]; then
	ERROR='<div class="error">'
	WARNING='<div class="warning">'
	cat > tmp.pkgxx.config <<-EOF
PKGMK_DOWNLOAD_TOOL=curl # There is currently a problem with wget…
info() {
	echo "<div class=\"info\">\$@</div>"
}
warning() {
	echo "<div class=\"warning\">\$@</div>"
}
error() {
	echo "<div class=\"error\">\$@</div>"
}
EOF
else
	ERROR="ERROR:"
	WARNING="WARNING:"
	cat > tmp.pkgxx.config <<-EOF
PKGMK_DOWNLOAD_TOOL=curl # There is currently a problem with wget…
# The same as pkg++… but without redirection to stderr.
warning() {
	echo -e "\${fg_bold[yellow]}-- WARNING: \$@\${reset_color}"
}

error() {
	echo -e "\${fg_bold[red]}-- ERROR: \$@\${reset_color}"
}
	EOF
fi

# Just in case of txt output.
autoload -U colors
colors

. ./tmp.pkgxx.config

title "pkg++ standards compliance"

for packager in Youbi Kooda Lukc Pingax; do
	subtitle "$packager"
	: > log.$packager
	for i in *; do
		(
			if ! is_a_port "$i"; then
				continue
			fi
			cd "$i"
			if egrep -q "$packager" Pkgfile*; then
				{
					subsubtitle "$i"
					pkg++ -cf ../tmp.pkgxx.config -cp 2> log.pkgxx-error
				} | tee -a ../log.$packager
			fi
			if [[ -e log.pkgxx-error ]]; then
				if [[ "$OUTPUT" = html ]]; then
					sed -e "s/^/<div id=\"zsh-error\">/;s/$(echo -n -e "\033")/\\e/g;s/$/<\/div>/" log.pkgxx-error
				else
					cat log.pkgxx-error
				fi
				rm log.pkgxx-error
			fi
		)
	done
	subsubtitle "Summary:"
	info "Errors:           $(grep "$ERROR" log.$packager | wc -l)"
	info "Warnings:         $(grep "$WARNING" log.$packager | wc -l)"
	info "Correct packages: $(grep "Everything is in perfect order." log.$packager | wc -l)"
done

subtitle "Orphan packages"

for i in *; do
	if ! is_a_port "$i"; then
		continue
	fi
	(
		cd "$i"
		local pkgfile="$(ls | grep Pkgfile | (tail -n 1 || cat))"
		. ./$pkgfile
		if [[ -z "$maintainer" || -z "$packager" ]]; then
			subsubtitle "$i"
		fi
		if [[ -z "$maintainer" ]]; then
			info "No maintainer."
		fi
		if [[ -z "$packager" ]]; then
			info "No packager."
		fi
	)
done

subtitle "useflags"

for DIR in *; do
	if ! is_a_port "$DIR"; then
		continue
	fi
	(
		cd "$DIR"
		local pkgfile="$(ls | grep Pkgfile | (tail -n 1 || cat))"
		. ./$pkgfile
		if [[ -n "${iuse[@]}" ]]; then
			subsubtitle "$DIR"
			for flag in ${iuse[@]}; do
				if [[ -n "$(eval echo "\${use_$flag[@]}")" ]]; then
					if [[ -z "$(eval echo "\${use_${flag}[1]}")" || -z "$(eval echo "\${use_${flag}[2]}")" ]]; then
						warning "$flag is only partially defined."
					else
						info "$flag"
					fi
				else
					error "$flag is not defined."
				fi
			done
		fi
	)
done


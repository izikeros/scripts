

#!/bin/ksh
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ${SCRIPT_NAME} [-hv] [-o[file]] args ...
#%
#% DESCRIPTION
#%    This is a script template
#%    to start any good shell script.
#%
#% OPTIONS
#%    -o [file], --output=[file]    Set log file (default=/dev/null)
#%                                  use DEFAULT keyword to autoname file
#%                                  The default value is /dev/null.
#%    -t, --timelog                 Add timestamp to log ("+%y/%m/%d@%H:%M:%S")
#%    -x, --ignorelock              Ignore if lock file exists
#%    -h, --help                    Print this help
#%    -v, --version                 Print script information
#%
#% EXAMPLES
#%    ${SCRIPT_NAME} -o DEFAULT arg1 arg2
#%
#================================================================
#- IMPLEMENTATION
#-    version         ${SCRIPT_NAME} 0.0.6
#-    author          Michel VONGVILAY (https://www.uxora.com)
#-    license         CC-BY-SA Creative Commons License
#-    script_id       0
#-
#================================================================
#  HISTORY
#     2015/03/01 : mvongvilay : Script creation
#     2015/04/01 : mvongvilay : Add long options and improvements
#     2017/09/01 : mvongvilay : Licence change and minor code change
#     2018/02/01 : mvongvilay : Add Inter Process Communication File functions (ipcf)
#     2018/02/01 : mvongvilay : Add Parrallelism (bg jobs) management with ipcf
#     2018/02/01 : mvongvilay : Change lock with mkdir to be more mutex
#     2018/02/01 : mvongvilay : Change exec_cmd to use ipcf and tag stderr output
#
#================================================================
#  DEBUG OPTION
#    set -n  # Uncomment to check your syntax, without execution.
#    set -x  # Uncomment to debug this shell script
#
#================================================================
# END_OF_HEADER
#================================================================
trap 'error "${SCRIPT_NAME}: FATAL ERROR at $(date "+%HH%M") (${SECONDS}s): Interrupt signal intercepted! Exiting now..."
	2>&1 | tee -a ${fileLog:-/dev/null} >&2 ;
	exit 99;' INT QUIT TERM
trap 'cleanup' EXIT

#============================
#  FUNCTIONS
#============================

  #== fecho function ==#
fecho() {
	_Type=${1} ; shift ;
	[[ ${SCRIPT_TIMELOG_FLAG:-0} -ne 0 ]] && printf "$( date ${SCRIPT_TIMELOG_FORMAT} ) "
	printf "[${_Type%[A-Z][A-Z]}] ${*}\n"
	if [[ "${_Type}" = CAT ]]; then
		_Tag="[O]"
		[[ "$1" == \[*\] ]] && _Tag="${_Tag} ${1}"
		if [[ ${SCRIPT_TIMELOG_FLAG:-0} -eq 0 ]]; then
			cat -un - | awk '$0="'"${_Tag}"' "$0; fflush();' ;
		elif [[ "${GNU_AWK_FLAG}" ]]; then # fast - compatible linux
			cat -un - | awk -v tformat="${SCRIPT_TIMELOG_FORMAT#+} " '$0=strftime(tformat)"'"${_Tag}"' "$0; fflush();' ;
		elif [[ "${PERL_FLAG}" ]]; then # fast - if perl installed
			cat -un - | perl -pne 'use POSIX qw(strftime); print strftime "'${SCRIPT_TIMELOG_FORMAT_PERL}' ' "${_Tag}"' ", gmtime();'
		else # average speed but resource intensive- compatible unix/linux
			cat -un - | while read LINE; do \
				[[ ${OLDSECONDS:=$(( ${SECONDS}-1 ))} -lt ${SECONDS} ]] && OLDSECONDS=$(( ${SECONDS}+1 )) \
				&& TSTAMP="$( date ${SCRIPT_TIMELOG_FORMAT} ) "; printf "${TSTAMP}${_Tag} ${LINE}\n"; \
			done
		fi
	fi
}

  #== custom function ==#
check_cre_file() {
	_File=${1}
	_Script_Func_name="${SCRIPT_NAME}: check_cre_file"
	[[ "x${_File}" = "x" ]] && error "${_Script_Func_name}: No parameter" && return 1
	[[ "${_File}" = "/dev/null" ]] && return 0
	[[ -e ${_File} ]] && error "${_Script_Func_name}: ${_File}: File already exists" && return 2
	touch ${_File} 1>/dev/null 2>&1
	[[ $? -ne 0 ]] && error "${_Script_Func_name}: ${_File}: Cannot create file" && return 3
	rm -f ${_File} 1>/dev/null 2>&1
	[[ $? -ne 0 ]] && error "${_Script_Func_name}: ${_File}: Cannot delete file" && return 4
	return 0
}

#============================
#  ALIAS AND FUNCTIONS
#============================

  #== error management functions ==#
info() { fecho INF "${*}"; }
warning() { [[ "${flagMainScriptStart}"  -eq 1 ]] && ipcf_save "WRN" "0" "${*}" ; fecho WRN "WARNING: ${*}" 1>&2 ; }
error() { [[ "${flagMainScriptStart}" -eq 1 ]] && ipcf_save "ERR" "0" "${*}" ; fecho ERR "ERROR: ${*}" 1>&2 ; }
debug() { [[ ${flagDbg} -ne 0 ]] && fecho DBG "DEBUG: ${*}" 1>&2; }

tag() { [[ "x$1" == "x--eol" ]] && awk '$0=$0" ['$2']"; fflush();' || awk '$0="['$1'] "$0; fflush();' ; }
infotitle() { _txt="-==# ${*} #==-"; _txt2="-==#$( echo " ${*} " | tr '[:print:]' '#' )#==-" ;
	info "$_txt2"; info "$_txt"; info "$_txt2";
}

  #== startup and finish functions ==#
cleanup() { [[ flagScriptLock -ne 0 ]] && [[ -e "${SCRIPT_DIR_LOCK}" ]] && rm -fr ${SCRIPT_DIR_LOCK}; }
scriptstart() { trap 'kill -TERM ${$}; exit 99;' TERM
	info "${SCRIPT_NAME}: Start $(date "+%y/%m/%d@%H:%M:%S") with pid ${EXEC_ID} by ${USER}@${HOSTNAME}:${PWD}"\
		$( [[ ${flagOptLog} -eq 1 ]] && echo " (LOG: ${fileLog})" || echo " (NOLOG)" );
	flagMainScriptStart=1 && ipcf_save "PRG" "${EXEC_ID}" "${FULL_COMMAND}"
}
scriptfinish() {
	kill $(jobs -p) 1>/dev/null 2>&1 && warning "${SCRIPT_NAME}: Some bg jobs have been killed" ;
	[[ ${flagOptLog} -eq 1 ]] && info "${SCRIPT_NAME}: LOG file can be found here: ${fileLog}" ;
	countErr="$( ipcf_count ERR )" ; countWrn="$( ipcf_count WRN )" ;
	[[ $rc -eq 0 ]] && endType="INF" || endType="ERR";
	fecho ${endType} "${SCRIPT_NAME}: Finished$([[ $countErr -ne 0 ]] && echo " with ERROR(S)") at $(date "+%HH%M") (Time=${SECONDS}s, Error=${countErr}, Warning=${countWrn}, RC=$rc).";
	exit $rc ; }

  #== usage functions ==#
usage() { printf "Usage: "; scriptinfo usg ; }
usagefull() { scriptinfo ful ; }
scriptinfo() { headFilter="^#-"
	[[ "$1" = "usg" ]] && headFilter="^#+"
	[[ "$1" = "ful" ]] && headFilter="^#[%+]"
	[[ "$1" = "ver" ]] && headFilter="^#-"
	head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "${headFilter}" | sed -e "s/${headFilter}//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }

  #== Inter Process Communication File functions (ipcf) ==#
#== Create semaphore on fd 101 #==  Not use anymore ==#
# ipcf_cre_sem() { SCRIPT_SEM_RC="${SCRIPT_DIR_LOCK}/pipe-rc-${$}";
# 	mkfifo "${SCRIPT_SEM_RC}" && exec 101<>"${SCRIPT_SEM_RC}" && rm -f "${SCRIPT_SEM_RC}"; }
#==  Use normal file instead for persistency ==#
ipcf_save() { # Usage: ipcf_save <TYPE> <ID> <DATA>
	_Line="${1}|${2}"
	shift 2 && _Line+="|${*}"
	[[ "${*}" == "${_Line}" ]] \
		&& warning "ipcf_save: Failed: Wrong format: ${*}" && return 1
	echo "${_Line}" >> ${ipcf_file} ;
	[[ "${?}" -ne 0 ]] \
		&& warning "ipcf_save: Failed: Writing error to ${ipcf_file}: ${*}" && return 2
	return 0 ;
}
ipcf_load() { # Usage: ipcf_load <TAG> <ID> ; Return: $ipcf_return ;
	ipcf_return=""
	_Line="$( grep "^${1}${ipcf_IFS}${2}" ${ipcf_file} | tail -1 )" ;
	[[ "$( echo "${_Line}" | wc -w )" -eq 0 ]] \
		&& warning "ipcf_load: Failed: No data found: ${1} ${2}" && return 1 ;
	IFS="${ipcf_IFS}" read ipcftype ipcfid ipcfdata <<< $(echo "${_Line}") ;
	[[ "$( echo "${ipcfdata}" | wc -w )" -eq 0 ]] \
		&& warning "ipcf_load: Failed: Cannot parse - wrong format: ${1} ${2}" && return 2 ;
	ipcf_return="$ipcfdata" && echo "${ipcf_return}" && return 0 ;
}
ipcf_count() { # Usage: ipcf_count <TAG> [<ID>] ; Return: $ipcf_return ;
	ipcf_return="$( grep "^${1}${ipcf_IFS}${2:-0}" ${ipcf_file} | wc -l )";
	echo ${ipcf_return}; return 0;
}

ipcf_save_rc() { rc=$? && ipcf_return="${rc}"; ipcf_save "RC_" "${1:-0}" "${rc}"; return $? ; }
ipcf_load_rc() { # Usage: ipcf_load_rc [<ID>] ; Return: $ipcf_return ;
	ipcf_return=""; ipcfdata=""; ipcf_load "RC_" "${1:-0}" >/dev/null ;
	[[ "${?}" -ne 0 ]] && warning "ipcf_load_rc: Failed: No rc found: ${1:-0}" && return 1 ;
	[[ ! "${ipcfdata}" =~ ^-?[0-9]+$ ]] \
		&& warning "ipcf_load_rc: Failed: Not a Number (ipcfdata=${ipcfdata}): ${1:-0}" && return 2 ;
	rc="${ipcfdata}" && ipcf_return="${rc}" && echo "${rc}"; return 0 ;
}

ipcf_save_cmd() { # Usage: ipcf_save_cmd <CMD> ; Return: $ipcf_return ;
	ipcf_return=""; cmd_id="" ;
	_cpid="$(exec sh -c 'echo $PPID')"; _NewId="$( printf '%.5d' ${_cpid:-${RANDOM}} )" ;
	ipcf_save "CMD" "${_NewId}" "${*}" ;
	[[ "${?}" -ne 0 ]] && warning "ipcf_save_cmd: Failed: ${1:-0}" && return 1 ;
	cmd_id="${_NewId}" && ipcf_return="${cmd_id}" && echo "${ipcf_return}"; return 0;
}
ipcf_load_cmd() { # Usage: ipcf_load_cmd <ID> ; Return: $ipcf_return ;
	ipcf_return=""; cmd="" ;
	if [[ "x${1}"  =~ ^x[0]*$ ]]; then ipcfdata="0" ;
	else
		ipcfdata=""; ipcf_load "CMD" "${1:-0}" >/dev/null ;
		[[ "${?}" -ne 0 ]] && warning "ipcf_load_cmd: Failed: No cmd found: ${1:-0}" && return 1 ;
	fi
	cmd="${ipcfdata}" && ipcf_return="${ipcfdata}" && echo "${ipcf_return}"; return 0 ;
}

ipcf_assert_cmd() { # Usage: ipcf_assert_cmd [<ID>] ;
	cmd=""; rc=""; msg="";
	ipcf_load_cmd ${1:-0} >/dev/null
	[[ "${?}" -ne 0 ]] && warning "ipcf_assert_cmd: Failed: No cmd found: ${1:-0}" && return 1 ;
	ipcf_load_rc ${1:-0} >/dev/null
	[[ "${?}" -ne 0 ]] && warning "ipcf_assert_cmd: Failed: No rc found: ${1:-0}" && return 2 ;
	msg="[${1:-0}] Command succeeded [OK] (rc=${rc}): ${cmd} " ;
	[[ $rc -ne 0 ]] && error "$(echo ${msg} | sed -e "s/succeeded \[OK\]/failed [KO]/1")" || info "${msg}" ;
	return $rc ;
}

  #== exec_cmd function ==#
exec_cmd() { # Usage: exec_cmd <CMD> ;
	cmd_id="" ; ipcf_save_cmd "${*}" >/dev/null || return 1 ;
	{ {
		eval ${*}
		ipcf_save_rc ${cmd_id} ;
	} 2>&1 1>&3 | tag STDERR 1>&2 ; } 3>&1 2>&1 | fecho CAT "[${cmd_id}]" "${*}"
	ipcf_assert_cmd ${cmd_id}
	return $rc ;
}

wait_cmd() { # Usage: wait_cmd [<TIMEOUT>] ;
	_num_timer=0 ; _num_fail_cmd=0 ; _num_run_jobs=0 ;
	_tmp_txt="" ; _tmp_rc=0 ; _flag_nokill=0 ;
	_cmd_id_fail="" ; _cmd_id_check="" ; _cmd_id_list="" ;
	_tmp_grep_bash="exec_cmd" ;
	[[ "x$BASH" == "x" ]] && _tmp_grep_bash=""
	sleep 1
	[[ "x$1" == "x--nokill" ]] && _flag_nokill=1 && shift
	_num_timeout=${1:-32768} ;
	_num_start_line="$( grep -sn "^CHK${ipcf_IFS}" ${ipcf_file} | tail -1 | cut -f1 -d: )"
	_cmd_id_list="$( tail -n +${_num_start_line:-0} ${ipcf_file} | grep "^CMD${ipcf_IFS}" | cut -d"${ipcf_IFS}" -f2 | xargs ) " ;
	while true; do
		# Retrieve all RC from ipcf_file to Array
		unset -v _cmd_rc_a
		[[ "x$BASH" == "x" ]] && typeset -A _cmd_rc_a || declare -A _cmd_rc_a #Other: ps -ocomm= -q $$
		eval $( tail -n +${_num_start_line:-0} ${ipcf_file} | grep "^RC_${ipcf_IFS}" | cut -d"${ipcf_IFS}" -f2,3 | xargs | sed "s/\([0-9]*\)|\([0-9]*\)/_cmd_rc_a[\1]=\2\;/g" ) ;

		#debug "wait_cmd: \$_cmd_id_list='$_cmd_id_list' ; \${_cmd_rc_a[@]}=${_cmd_rc_a[@]}; \${!_cmd_rc_a[@]}=${!_cmd_rc_a[@]};"

		for __cmd_id in ${_cmd_id_list}; do
			#_tmp_rc="$(ipcf_load_rc ${__cmd_id} 2>/dev/null)"
			if [[ "${_cmd_rc_a[$__cmd_id]}" ]]; then
				_cmd_id_list=${_cmd_id_list/"${__cmd_id} "}
				_cmd_id_check+="${__cmd_id} "
				[[ "${_cmd_rc_a[$__cmd_id]}" -ne 0 ]] && _cmd_id_fail+="${__cmd_id} "
			fi
		done

		_num_run_jobs="$( jobs -l | grep -i "Running.*${_tmp_grep_bash}" | wc -l )"
		[[ $((_num_timer%5)) -eq 0 ]] && info "wait_cmd: Waiting for ${_num_run_jobs} bg jobs to finish: $( echo ${_cmd_id_list} | sed -e "s/\([0-9]*\)/[\1]/g" ) (elapsed: ${_num_timer}s)"
		((++_num_timer))
		if [[ $((_num_timer%_num_timeout)) -eq 0 ]]; then
			[[ "$_flag_nokill" -eq 0 ]] \
				&& kill $( jobs -l | grep -i "Running.*${_tmp_grep_bash}" | tr -d '+-' | tr -s ' ' | cut -d" " -f2 | xargs ) 1>/dev/null 2>&1 \
				&& _tmp_txt="- killed ${_num_run_jobs} bg job(s)" || _tmp_txt=""
			warning "wait_cmd: Time out reached (${_num_timer}s) ${_tmp_txt} - exit function"
			return 255
		fi

		[[ "$( echo "${_cmd_id_list}" | wc -w )" -eq 0 ]] && break

		[[ "${_num_run_jobs}" -eq 0 ]] \
			&& warning "wait_cmd: No more running jobs but there is still cmd_id left: ${_cmd_id_list}" \
			&& _cmd_id_fail+="${_cmd_id_list} " && break
		sleep 1;
	done

	_num_run_jobs="$( jobs -l | grep -i "Running.*${_tmp_grep_bash}" | wc -l )"
	[[ ${_num_run_jobs} -gt 1 ]] \
		&& warning "wait_cmd: No more cmd but Still have running jobs: $( jobs -p | xargs echo )"

	_num_fail_cmd="$( echo ${_cmd_id_fail} | wc -w )"
	[[ ${_num_fail_cmd} -eq 0 ]] && info "wait_cmd: All cmd_id succeeded" \
		|| warning "wait_cmd: ${_num_fail_cmd} cmd_id failed: $( echo ${_cmd_id_fail} | sed -e "s/\([0-9]*\)/[\1]/g" )"

	ipcf_save "CHK" "0" "${_cmd_id_check}"

	return $_num_fail_cmd
}

assert_rc() { [[ $rc -ne 0 ]] && error "${*} (RC=$rc)"; return $rc; }

#============================
#  FILES AND VARIABLES
#============================

  #== general variables ==#
SCRIPT_NAME="$(basename ${0})" # scriptname without path
SCRIPT_DIR="$( cd $(dirname "$0") && pwd )" # script directory
SCRIPT_FULLPATH="${SCRIPT_DIR}/${SCRIPT_NAME}"

SCRIPT_ID="$(scriptinfo | grep script_id | tr -s ' ' | cut -d' ' -f3)"
SCRIPT_HEADSIZE=$(grep -sn "^# END_OF_HEADER" ${0} | head -1 | cut -f1 -d:)

SCRIPT_UNIQ="${SCRIPT_NAME%.*}.${SCRIPT_ID}.${HOSTNAME%%.*}"
SCRIPT_UNIQ_DATED="${SCRIPT_UNIQ}.$(date "+%y%m%d%H%M%S").${$}"

SCRIPT_DIR_TEMP="/tmp" # Make sure temporary folder is RW
SCRIPT_DIR_LOCK="${SCRIPT_DIR_TEMP}/${SCRIPT_UNIQ}.lock"

SCRIPT_TIMELOG_FLAG=0
SCRIPT_TIMELOG_FORMAT="+%y/%m/%d@%H:%M:%S"
SCRIPT_TIMELOG_FORMAT_PERL="$(echo ${SCRIPT_TIMELOG_FORMAT#+} | sed 's/%y/%Y/g')"

HOSTNAME="$(hostname)"
FULL_COMMAND="${0} $*"
EXEC_DATE=$(date "+%y%m%d%H%M%S")
EXEC_ID=${$}
GNU_AWK_FLAG="$(awk --version 2>/dev/null | head -1 | grep GNU)"
PERL_FLAG="$(perl -v 1>/dev/null 2>&1 && echo 1)"

  #== file variables ==#
filePid="${SCRIPT_DIR_LOCK}/pid"
fileLog="/dev/null"

  #== function variables ==#
ipcf_file="${SCRIPT_DIR_LOCK}/${SCRIPT_UNIQ_DATED}.tmp.ipcf";
ipcf_IFS="|" ; ipcf_return="" ;
rc=0 ; countErr=0 ; countWrn=0 ;

  #== option variables ==#
flagOptErr=0
flagOptLog=0
flagOptTimeLog=0
flagOptIgnoreLock=0

flagTmp=0
flagDbg=1
flagScriptLock=0
flagMainScriptStart=0

#============================
#  PARSE OPTIONS WITH GETOPTS
#============================

  #== set short options ==#
SCRIPT_OPTS=':o:txhv-:'

  #== set long options associated with short one ==#
typeset -A ARRAY_OPTS
ARRAY_OPTS=(
	[timelog]=t
	[ignorelock]=x
	[output]=o
	[help]=h
	[man]=h
)

  #== parse options ==#
while getopts ${SCRIPT_OPTS} OPTION ; do
	#== translate long options to short ==#
	if [[ "x$OPTION" == "x-" ]]; then
		LONG_OPTION=$OPTARG
		LONG_OPTARG=$(echo $LONG_OPTION | grep "=" | cut -d'=' -f2)
		LONG_OPTIND=-1
		[[ "x$LONG_OPTARG" = "x" ]] && LONG_OPTIND=$OPTIND || LONG_OPTION=$(echo $OPTARG | cut -d'=' -f1)
		[[ $LONG_OPTIND -ne -1 ]] && eval LONG_OPTARG="\$$LONG_OPTIND"
		OPTION=${ARRAY_OPTS[$LONG_OPTION]}
		[[ "x$OPTION" = "x" ]] &&  OPTION="?" OPTARG="-$LONG_OPTION"

		if [[ $( echo "${SCRIPT_OPTS}" | grep -c "${OPTION}:" ) -eq 1 ]]; then
			if [[ "x${LONG_OPTARG}" = "x" ]] || [[ "${LONG_OPTARG}" = -* ]]; then
				OPTION=":" OPTARG="-$LONG_OPTION"
			else
				OPTARG="$LONG_OPTARG";
				if [[ $LONG_OPTIND -ne -1 ]]; then
					[[ $OPTIND -le $Optnum ]] && OPTIND=$(( $OPTIND+1 ))
					shift $OPTIND
					OPTIND=1
				fi
			fi
		fi
	fi

	#== options follow by another option instead of argument ==#
	if [[ "x${OPTION}" != "x:" ]] && [[ "x${OPTION}" != "x?" ]] && [[ "${OPTARG}" = -* ]]; then
		OPTARG="$OPTION" OPTION=":"
	fi

	#== manage options ==#
	case "$OPTION" in
		o ) fileLog="${OPTARG}"
			[[ "${OPTARG}" = *"DEFAULT" ]] && fileLog="$( echo ${OPTARG} | sed -e "s/DEFAULT/${SCRIPT_UNIQ_DATED}.log/g" )"
			flagOptLog=1
		;;

		t ) flagOptTimeLog=1
			SCRIPT_TIMELOG_FLAG=1
		;;

		x ) flagOptIgnoreLock=1
		;;

		h ) usagefull
			exit 0
		;;

		v ) scriptinfo
			exit 0
		;;

		: ) error "${SCRIPT_NAME}: -$OPTARG: option requires an argument"
			flagOptErr=1
		;;

		? ) error "${SCRIPT_NAME}: -$OPTARG: unknown option"
			flagOptErr=1
		;;
	esac
done
shift $((${OPTIND} - 1)) ## shift options

#============================
#  MAIN SCRIPT
#============================

[ $flagOptErr -eq 1 ] && usage 1>&2 && exit 1 ## print usage if option error and exit

  #== Check/Set arguments ==#
[[ $# -gt 2 ]] && error "${SCRIPT_NAME}: Too many arguments" && usage 1>&2 && exit 2

  #== Create lock ==#
flagScriptLock=0
while [[ flagScriptLock -eq 0 ]]; do
	if mkdir ${SCRIPT_DIR_LOCK} 1>/dev/null 2>&1; then
		info "${SCRIPT_NAME}: ${SCRIPT_DIR_LOCK}: Locking succeeded" >&2
		flagScriptLock=1
	elif [[ ${flagOptIgnoreLock} -ne 0 ]]; then
		warning "${SCRIPT_NAME}: ${SCRIPT_DIR_LOCK}: Lock detected BUT IGNORED" >&2
		SCRIPT_DIR_LOCK="${SCRIPT_UNIQ_DATED}.lock"
		filePid="${SCRIPT_DIR_LOCK}/pid"
		ipcf_file="${SCRIPT_DIR_LOCK}/${SCRIPT_UNIQ_DATED}.tmp.ipcf";
		flagOptIgnoreLock=0
	elif [[ ! -e "${SCRIPT_DIR_LOCK}" ]]; then
		error "${SCRIPT_NAME}: ${SCRIPT_DIR_LOCK}: Cannot create lock folder" && exit 3
	else
		[[ ! -e ${filePid} ]] && sleep 1 # In case of concurrency
		if [[ ! -e ${filePid} ]]; then
			warning "${SCRIPT_NAME}: ${SCRIPT_DIR_LOCK}: Remove stale lock (no filePid)"
		elif [[ "x$( ps -ef | grep $(head -1 "${filePid}"))" == "x" ]]; then
			warning "${SCRIPT_NAME}: ${SCRIPT_DIR_LOCK}: Remove stale lock (no running pid)"
		else
			error "${SCRIPT_NAME}: ${SCRIPT_DIR_LOCK}: Lock detected (running pid: $(head -1 "${filePid}")) - exit program" && exit 3
		fi
		rm -fr "${SCRIPT_DIR_LOCK}" 1>/dev/null 2>&1
		[[ "${?}" -ne 0 ]] && error "${SCRIPT_NAME}: ${SCRIPT_DIR_LOCK}: Cannot delete lock folder" && exit 3
	fi
done

  #== Create files ==#
check_cre_file "${filePid}" || exit 4
check_cre_file "${ipcf_file}" || exit 4
check_cre_file "${fileLog}" || exit 4

echo "${EXEC_ID}" > ${filePid}

if [[ "${fileLog}" != "/dev/null" ]]; then
	touch ${fileLog} && fileLog="$( cd $(dirname "${fileLog}") && pwd )"/"$(basename ${fileLog})"
fi

  #== Main part ==#
  #===============#
{ scriptstart ;
  #== start your program here ==#
infotitle "Running simple cmd"
exec_cmd "ls -lrt $* ;"

infotitle "Running cmd in parrallel (bg jobs)"
exec_cmd "sleep 10 ;" &
exec_cmd "cat somequotes.txt ;" &
exec_cmd "echo Another sleep cmd; sleep 9 ;" &
exec_cmd "ls -lrt filenotexist ;" &
sleep 1
jobs -l 2>&1 | fecho CAT "jobs -l"
wait_cmd 60

infotitle "Generating a wait_cmd timeout"
exec_cmd "sleep 8 ;" &
wait_cmd 6

ipcf_save_rc >/dev/null

  #== end   your program here ==#
scriptfinish ; } 2>&1 | tee ${fileLog}

  #== End ==#
  #=========#
ipcf_load_rc >/dev/null
exit $rc

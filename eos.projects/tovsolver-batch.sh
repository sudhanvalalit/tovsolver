#!/bin/bash
#
#
# tovsolver-batch.sh - Executes the TOV solver for a batch of central
#               		densities, found in the EoS file.
#
# Author: 	Rodrigo Alvares de Souza
# 		rsouza01@gmail.com
#
#
# History:
# Version 0.4: 2014/04/05 (rsouza) - Improving legibility, adding coments, etc.
# Version 0.5: 2014/04/14 (rsouza) - Update regarding the tov_parameters.sh.
# Version 0.6: 2014/04/16 (rsouza) - Added error treatment, sanity checks and some colors :-).
# Version 0.7: 2015/05/11 (rsouza) - New name, minor improvements.
#
# DO NOT EDIT THIS FILE. 
# MODEL RELATED PARAMETERS SHOULD BE ENTERED VIA COMMAND LINE PARAMETERS.
# IN PRINCIPLE, THESE PARAMETERS DO NOT NEED TO BE CHANGED.


#FUNCTIONS DEFINITIONS

print2stringslncolor () {
        echo -e "\e[0m$1\e[1;34m$2\e[0m\n"
}


print2stringslncolorERROR () {
        echo -e "\e[0m$1\e[1;91m$2\e[0m\n"
}

printlncolor () {
        echo -e "\e[1;34m$1\e[0m\n"
}

printlncolorERROR () {
        echo -e "\e[1;91m$1\e[0m\n"
}
#END FUNCTIONS DEFINITIONS

#MAIN PROGRAM
_CONFIG_FILE="./tov_solver.conf"
_OUTPUT_DIR="./output/"
# _EXECUTABLE="FORTRAN_TOV_Solver"
_EXECUTABLE="tovsolver"

USE_MESSAGE="
Usage: $(basename "$0") [OPTIONS]

OPTIONS:
  -c, --config          Sets the TOV Solver config file, '${_CONFIG_FILE}' by default.
  -o, --outputdir       Sets the Output directory, '${_OUTPUT_DIR}' by default.
  -e, --executable      Sets the TOV Solver executable, '${_EXECUTABLE}' by default.

  -h, --help            Show this help screen and exits
  -V, --version         Show program version and exits
"

_VERSION=$(grep '^# Version ' "$0" | tail -1 | cut -d : -f 1 | tr -d \#)

#Command line arguments
while test -n "$1"
do
        case "$1" in

		-c | --config) 
                        shift
                        _CONFIG_FILE=$1 
                ;;

		-o | --outputdir) 
                        shift
                        _OUTPUT_DIR=$1 
                ;;

		-e | --executable) 
                        shift
                        _EXECUTABLE=$1 
                ;;

		-h | --help)
			echo "$USE_MESSAGE"
			exit 0
		;;

		-V | --version)
			echo -n $(basename "$0")
                        echo " ${_VERSION}"
			exit 0
		;;

		*)
			echo Invalid option: $1
			exit 1
		;;
	esac

	shift
done


#Lets find out which EoS file we should use...
while read LINE; do
        #Ignoring comments...
        [ "$(echo $LINE | cut -c1)" = '#' ] && continue

        #Ignoring white lines...
        [ "$LINE" ] || continue

        #Splits the config file line
        arrIN=(${LINE//=/ })

        #Taking the key value but converting to lower case first.
        key=$(echo ${arrIN[0]} | tr A-Z a-z) 

        #Taking the value.
        value=${arrIN[1]}

        case "$key" in
                eos_file_name) _EOS_FILE_NAME=$value ;;
        esac

done < "${_CONFIG_FILE}"

printlncolor "\n\n__________________________________________________________________________________________________________"
printlncolor "---------------------------------  TOV Solver Shell Script ${_VERSION} ----------------------------------"
printlncolor "__________________________________________________________________________________________________________"

# Replaces the INTERNAL FIELD SEPARATOR, but storing a copy first
OLD_IFS=$IFS
IFS=', '

print2stringslncolor "EoS file: " "'${_EOS_FILE_NAME}'."
print2stringslncolor "Batch config file: " "'${_CONFIG_FILE}'."
print2stringslncolor "Output folder: " "'${_OUTPUT_DIR}'."

# Does the EoS file exist?
if [ ! -f $_EOS_FILE_NAME ]
then
	printlncolorERROR "EoS file '${_EOS_FILE_NAME}' not found."
	exit -1
fi

# Does the output dir exist?
if [ ! -d "$_OUTPUT_DIR" ]; then
	echo "Folder '${_OUTPUT_DIR}' not found, creating..."
	mkdir $_OUTPUT_DIR
fi

# Does the Executable file exist?
if [ ! -f ${_EXECUTABLE} ]
then
	printlncolorERROR "Executable file '${_EXECUTABLE}' not found."
	exit -1
fi

#Is the executable executable?
if [ ! -x ${_EXECUTABLE} ]
then
	printlncolorERROR "'${_EXECUTABLE}' does not have execution permission.\nRun 'sudo chmod a+x ${_EXECUTABLE}'."
	exit -1
fi

echo "__________________________________________________________________________________________________________"

declare -i secondsProcessing=0

while read line; do 
	arr=($line)
	_rho_0=${arr[0]}

	#Ignores lines beginning with '#'
	if [[ $_rho_0 != '#'* ]];  
	then
		echo "Processing rho_0=${_rho_0}..."

		beginProcessing=`date +%s%N | cut -b1-13`

		commandLine="${_EXECUTABLE} -rho_0=${_rho_0} -config=${_CONFIG_FILE} > ${_OUTPUT_DIR}out_${_rho_0}.txt"
		
                echo $commandLine
		
                #Next command is a possible flaw in hands of ill-intentioned users. 
                #Please do not execute this script as a root.
                eval $commandLine

		if [ $? -ne 0 ]; then
                        print2stringslncolorERROR "Return status: " "ERROR!"
		else
                        print2stringslncolor "Return status: " "OK!"
		fi

		endProcessing=`date +%s%N | cut -b1-13`

		secondsProcessing=endProcessing-beginProcessing

		echo "Processing time: $secondsProcessing ms."

		#Return code == 0 ? 'GREAT SUCCESS!!' : 'NAUGHTY, NAUGHTY!'

		echo "__________________________________________________________________________________________________________"
	fi

done < "$_EOS_FILE_NAME"

#Restoring the INTERNAL FIELD SEPARATOR
IFS=$OLD_IFS

printlncolor "Done."
#!/bin/bash

clear

# Colors
greenColor="\e[0;32m\033[1m"
endColor="\033[0m\e[0m"
redColor="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColor="\e[0;33m\033[1m"
purpleColor="\e[0;35m\033[1m"
greyColor="\e[0;37m\033[1m"

# Port Scan
port_scan(){
	stdbuf -oL nmap -p- --open -sS -v "$ip_target" -oG /tmp/ports | \
	grep -v --line-buffered "adjust_timeouts2: " | \
	sed -u '/adjust_timeouts2: /d' | \
	grep --line-buffered "Discovered open port" | \
	awk '{print "\033[32m[+] \033[0m" "\033[1;90m"$4"\033[0m"}'

	# Extract ports from Nmap's generated file and store them in a variable
	ports=$(grep -oP '(\d+)/open' /tmp/ports | awk -F'/' '{print $1}' | tr '\n' ',')

	# Clean last character from the list (last coma)
	ports="${ports%,}"
}

# Scans
normal_scan() {
	nmap -p$ports -sCV -T5 --stats-every 0.7s $ip_target -n -Pn -oN $results
}
stealth_scan() {
	nmap -p$ports -sCV -T2 --stats-every 0.7s $ip_target -n -Pn -oN $results
}
UDP_scan() {
	nmap -sU --top-ports 100 --open -T5 --stats-every 0.7s $ip_target -n -oN $results
}
vuln_scan(){
	nmap --script "vuln" --stats-every 0.7s $ip_target -oN $results
}
vuln_scan_ports(){
	nmap -p$ports --script "vuln" --stats-every 0.7s $ip_target -oN $results
}


# Ctrl+C function
ctrl_c() {
	tput civis
	stty -echo
	stty -icanon
    # No content in results variable
    if [[ -z "$results" ]]; then
	message "exito" "Saliendo...:)"
	sleep 0.5
	tput cnorm
	stty echo
	stty icanon
	exit 0
    fi

	# Content in results variable
	echo -ne "\n\n\n${purpleColor}[!]${endColor}${yellowColor} Escaneo cancelado. ¿Eliminar archivos creados? ${endColor}${redColor}[${endColor}${greyColor}Y${endColor}${redColor}/${endColor}${greyColor}N${endColor}${redColor}]${endColor} ${yellowColor}: ${endColor}"
	tput cnorm
	stty echo
	stty icanon

	# Read user's answer
	read -r -n 1 answer
	tput civis
	stty -echo
	stty -icanon
    # Convert answer to lowercase and show options
    case "${answer,,}" in
	y|yes)
	    rm -f "$results" 2>/dev/null
	    message "exito" "Éxito. Archivo '$results' eliminado."
	    ;;
	n|no)
	    message "advertencia" "Archivo '$results' no eliminado."
	    ;;
	*)
	    message "error" "Opción inválida, el archivo '$results' no ha sido eliminado."
	    ;;
    esac

	# Exit message
	sleep 0.5
	message "exito" "Saliendo...:)"
	tput cnorm
	stty echo
	stty icanon
	sleep 0.5
	exit 0
}

# SIGINT signal capture (Ctrl+C)
trap ctrl_c SIGINT

# Showing messages function
message() {
	local type="$1"
	local message="$2"
    case $type in
	"info") echo -ne "${purpleColor}\n\n[*]${blueColor} $message ${endColor}" ;;
	"exito") echo -e "${purpleColor}\n\n[+]${greenColor} $message ${endColor}" ;;
 	"error") echo -e "${purpleColor}\n\n[!]${redColor} $message ${endColor}" ;;
	"advertencia") echo -e "${purpleColor}\n\n[-]${yellowColor} $message ${endColor}" ;;
    esac
}


# IP validator
ip_validator() {
	local ip="$1"
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        sleep 0.5
        tput cuu 3
        tput ed
        message "exito" "IP válida: $ip\n"
        sleep 0.7
        tput cuu 4
        tput ed
        return 0
    else
        message "error" "Formato de IP no válido. Intenta nuevamente."
        sleep 1
        tput cuu 6
        tput ed
        return 1
    fi
}

# Function to remove duplicated ports
remove_duplicates() {
    local input_ports="$1"

    # Convert port's string into an array
    IFS=',' read -r -a ports_array <<< "$input_ports"

    # Create new array to store unique ports
    declare -A unique_ports
    for port in "${ports_array[@]}"; do
        unique_ports["$port"]=1
    done

    # Convert the ports into a string again
    unique_ports_string=$(IFS=','; echo "${!unique_ports[*]}")

    echo "$unique_ports_string"
}

# Scanning function
scanning() {
    while true; do
	tput cnorm
	stty -icanon
	stty echo
        read -e -p $'\e[0;35m\033[1m\n\n[*] \e[0;34m\033[1mIntroduce una IP para escanear: \033[0m\e[0m' ip_target
	stty -echo
        tput civis

        # Calling IP validator function
	if ip_validator "$ip_target"; then
            break
        fi
	    tput cnorm
    done

	message "info" "Iniciando escaneo con nmap...\n"
	sleep 1
	tput cuu 3
	tput ed

	# Show open ports
	message "exito" "Mostrando puertos TCP abiertos:\n"
	port_scan

    # Scan selection
    while true; do
        tput cnorm
        message "info" "Selecciona el tipo de escaneo:\n\n"
        echo -e "\t${blueColor}{1}${endColor} ${greyColor}->${endColor} ${yellowColor}Escaneo normal [rápido] (nmap -sCV -T5 -n -Pn)${endColor}\n\n"
        echo -e "\t${blueColor}{2}${endColor} ${greyColor}->${endColor} ${yellowColor}Escaneo silencioso [muy lento] (nmap -sCV -T2 -n -Pn)${endColor}\n\n"
        echo -e "\t${blueColor}{3}${endColor} ${greyColor}->${endColor} ${yellowColor}Escaneo de puertos UDP (nmap -sU --top-ports 100 --open -T5 -n)${endColor}\n\n"
	echo -e "\t${blueColor}{4}${endColor} ${greyColor}->${endColor} ${yellowColor}Escaneo de vulnerabilidades (nmap --script 'vuln')${endColor}\n\n"
	stty echo
	stty icanon
	read -e -p $'\e[0;34m\033[1mElige una opción: \033[0m\e[0m' -n 1 scan_option
	tput civis
	stty -echo
	stty -icanon

        # Definir el comando de escaneo según la opción seleccionada
	case $scan_option in
            1)
		scan=normal_scan
		results="nmap_scan"
		tput cuu 17
		break
		;;
            2)
		scan=stealth_scan
		results="stealth_scan"
		tput cuu 17
		break
		;;
            3)
		scan=UDP_scan
		results="UDP_scan"
		tput cuu 17
		break
		;;
	    4)
		tput cuu 17
		tput ed
		while true; do
		    message "info" "Selecciona el objetivo:\n\n"
		    echo -e "\t${blueColor}   {1}${endColor} ${greyColor}->${endColor} ${yellowColor}Alguno de los puertos encontrados [$ports]${endColor}\n\n"
		    echo -e "\t${blueColor}   {2}${endColor} ${greyColor}->${endColor} ${yellowColor}IP completa [$ip_target]${endColor}\n\n"
		    echo -e "\t${blueColor}<- {3}${endColor} ${greyColor}->${endColor} ${yellowColor}Volver atrás${endColor}\n\n"
		    tput cnorm
		    stty echo
		    stty icanon
		    read -e -p $'\e[0;34m\033[1mElige una opción: \033[0m\e[0m' -n 1 vuln_option
		    tput civis
		    stty -echo
		    stty -icanon

		    # Define different vuln_scan options
		    case "$vuln_option" in
			1)
			   scan=vuln_scan_ports
			   tput cuu 12
			   tput ed

			   # Let the user select what ports wants to scan
			   while true; do
				tput cnorm
				stty echo
				read -e -p $'\n\t\t\033[1;2mIntroduce [b/B] para volver atrás.\033[0m\n\e[0;34m\033[1mIntroduce los puertos, separados por una coma y sin espacios (1,2,3,53,445,65535), que quieres escanear: \033[0m\e[0m' input_ports
				tput civis
				stty -echo
				stty -icanon
				# If the user enters [b|B], go back
				if [[ "$input_ports" == "b" || "$input_ports" == "B" ]]; then
				    tput cuu 5
				    tput ed
				    break
				fi

				# Validate that the entry has only numbers and commas
				if [[ "$input_ports" =~ ^([0-9]+,)*[0-9]+$ ]]; then
				    valid=true

				    # Delete duplicate ports
				    input_ports=$(remove_duplicates "$input_ports")

				    # Delete commas from input
				    IFS=',' read -r -a fixed_ports <<< "$input_ports"

				    # Check if the ports entered are in the variable $ports
				    for port in "${fixed_ports[@]}"; do
					if [[ ! ",$ports," =~ ",$port," ]]; then
					    valid=false
					    wrong_ports+=("$port") # Add incorrect port to an array
					fi
				    done

				    # Check if the user entered a wrong port
				    if [[ "$valid" == false ]]; then
					message "error" "¡Has introducido puertos erróneos! -> [Puerto $wrong_ports]. Debes introducir puertos que estén abiertos [$ports]\n"
					sleep 1
					echo -ne "\t\033[1;2mPresiona cualquier tecla para continuar...\033[0m"
					read -n 1
					tput cuu 7
					tput ed
					wrong_ports=()
				    fi
				else
				    valid=false
				    message "error" "¡Solo se pueden introducir números o comas!\n"
				    sleep 1.5
				    tput cuu 7
				    tput ed
				fi

				# If all ports are valid, we change $ports for the numbers introduced
				if $valid; then
				    tput cuu 3
				    tput ed
				    echo -e "\033[1;30m[\033[0m$input_ports\033[1;30m]\033[0m -> \033[1;2mGuardados. ;)\033[0m"
				    sleep 1
				    results="vuln_scan"
				    ports=$input_ports
				    tput cuu 3
				    tput ed
				    break 3
			    	fi

			    done
			    ;;
			2)
			    scan=vuln_scan
			    results="vuln_scan"
			    tput cuu 14
			    tput ed
			    break 2
			    ;;
			3)
			    tput cuu 14
			    tput ed
			    break
			    ;;
			*)
			    message "error" "Opción no válida. Intenta de nuevo."
			    sleep 0.7
			    tput cuu 17
			    tput ed
			    ;;
		    esac
		done
		;;
            *)
		message "error" "Opción no válida. Intenta de nuevo."
		sleep 0.7
		tput cuu 20
		tput ed
		;;
	esac
    done

	# Execute the selected scan
	stty -echo
	tput civis
	tput ed
	message "info" "Iniciando el escaneo seleccionado...\n\n"
	$scan | \
	grep --line-buffered -E "Timing: About" | \

    # List the scan's progress and its percentage
    while read -r line; do
        if [[ $line =~ (SYN\ Stealth\ Scan|NSE|Service\ scan|UDP\ Scan|Script\ Scan|Script\ Pre-Scan).*About\ ([0-9]+\.[0-9]+)% ]]; then
            escaneo="${BASH_REMATCH[1]}"
            porcentaje="${BASH_REMATCH[2]}"
            echo -ne "\r$escaneo ${greyColor}-->${endColor} $porcentaje%"
            # Limpiar las líneas
            tput ed
        fi
    done

    # Check if the scan found any ports [or active IPs]
    if [ $? -ne 0 ]; then
        message "error" "Hubo un problema al realizar el escaneo. Asegúrate de tener permisos root.\n"
        rm -f "$results"
    fi

    if ! grep -q "scan report" $results; then
        tput cuu 3
        tput ed
        message "error" "El escaneo no encontró ninguna IP activa o puertos abiertos en el objetivo.\n"
        rm -f $results
        sleep 1
        return 1
    else
        tput cuu 4
        tput ed
        message "exito" "Escaneo completado. Resultados guardados en: $results\n"
        sleep 0.6
    fi
}


# Show banner
echo -e "${yellowColor}╔╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╗${endColor}";
echo -e "${yellowColor}╠╬╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╬╣${endColor}";
echo -e "${yellowColor}╠╣~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~╠╣${endColor}";
echo -e "${yellowColor}╠╣~~~~▄████████~~▄████████~~~~▄████████~███▄▄▄▄~~~~~~~~~~~~~~~~▄████████~~▄████████~~~~▄█~~~~█▄~~~~~▄██████▄~~╠╣${endColor}";
echo -e "${yellowColor}╠╣~~~███~~~~███~███~~~~███~~~███~~~~███~███▀▀▀██▄~~~~~~~~~~~~~███~~~~███~███~~~~███~~~███~~~~███~~~███~~~~███~╠╣${endColor}";
echo -e "${yellowColor}╠╣~~~███~~~~█▀~~███~~~~█▀~~~~███~~~~███~███~~~███~~~~~~~~~~~~~███~~~~█▀~~███~~~~█▀~~~~███~~~~███~~~███~~~~███~╠╣${endColor}";
echo -e "${yellowColor}╠╣~~~███~~~~~~~~███~~~~~~~~~~███~~~~███~███~~~███~~~~~~~~~~~~▄███▄▄▄~~~~~███~~~~~~~~~▄███▄▄▄▄███▄▄~███~~~~███~╠╣${endColor}";
echo -e "${yellowColor}╠╣~▀███████████~███~~~~~~~~▀███████████~███~~~███~~~█████~~~▀▀███▀▀▀~~~~~███~~~~~~~~▀▀███▀▀▀▀███▀~~███~~~~███~╠╣${endColor}";
echo -e "${yellowColor}╠╣~~~~~~~~~~███~███~~~~█▄~~~~███~~~~███~███~~~███~~~~~~~~~~~~~███~~~~█▄~~███~~~~█▄~~~~███~~~~███~~~███~~~~███~╠╣${endColor}";
echo -e "${yellowColor}╠╣~~~~▄█~~~~███~███~~~~███~~~███~~~~███~███~~~███~~~~~~~~~~~~~███~~~~███~███~~~~███~~~███~~~~███~~~███~~~~███~╠╣${endColor}";
echo -e "${yellowColor}╠╣~~▄████████▀~~████████▀~~~~███~~~~█▀~~~▀█~~~█▀~~~~~~~~~~~~~~██████████~████████▀~~~~███~~~~█▀~~~~~▀██████▀~~╠╣${endColor}";
echo -e "${yellowColor}╠╣~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~╠╣${endColor}";
echo -e "${yellowColor}╠╬╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╬╣${endColor}";
echo -e "${yellowColor}╚╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╝${endColor}\n";
echo -e "\t\t\t${blueColor}###################################################${endColor}";
echo -e "\t\t\t${blueColor}##            Automatic Nmap Scanner             ##${endColor}";
echo -e "\t\t\t${blueColor}##       Developed by: Samuel García (SamuCrow)  ##${endColor}";
echo -e "\t\t\t${blueColor}###################################################${endColor}";

# Check if the user is root
if [ "$EUID" -ne 0 ]; then
    message "error" "El script debe ser ejecutado con privilegios de root."
	sleep 1
    exit 1
fi

# Calling scanning function
scanning
tput cnorm
stty echo
stty icanon

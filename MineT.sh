#!/bin/sh

#Global variables:

#Field size:
x_size=10
y_size=40

#Cursor position:
cur_x=3
cur_y=0

#Mines and flags count:
mines=20
flags=$mines

draw_f=0

mined_flag=0
true_flags=0

declare -A F_symbls
declare -A F_opnd

end_msg=""

#Color data:

NOCLR='\e[0m'

RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
MAGENTA='\e[35m'
PINK='\e[91m'
CYAN='\e[36m'
LIGHTYELLOW='\e[93m'
YELLOW='\e[33m'

GRAY='\e[90m'

BACKGREEN='\e[42m'
BACKRED='\e[41m'

#Filling field with mines:

generate_field() {
	#Initialize 2d arrays:
	for (( i = 1; i <=x_size; i++ )) do
		for (( j = 1; j <= y_size; j++)) do
			F_symbls[$i,$j]=0
			F_opnd[$i,$j]=0
		done
	done
	
	#Place mines and numbers:
	for (( cnt = 1; cnt <= mines; cnt++ )) do
		local x=$((1+$RANDOM%$x_size))
		local y=$((1+$RANDOM%$y_size))
		
		#If trying to place a mine twice on the same place:
		if [[ ${F_symbls[$x,$y]} == X ]]
		then
			cnt=$(($cnt-1))
			continue
		fi
		
		#Mine placed:
		F_symbls[$x,$y]=X
		
		#Calculate numbers around it:
		for (( i = -1; i <= 1; i++ )) do
			for (( j = -1; j <= 1; j++ )) do
				local xi=$(($x+$i))
				local yj=$(($y+$j))

				if (($xi >= 0)) && (($xi <= $x_size)) && (($yj >= 0)) && (($yj <= $y_size)); then	
					if [[ ${F_symbls[$xi,$yj]} != X ]]; then
						F_symbls[$xi,$yj]=$((${F_symbls[$xi,$yj]}+1))
					fi
				fi
			done
		done
	done
}


#Graphics functions section:

repeat_str() {
	local repeat="$1"
	local count="$2"

	#Create empty string with the size of $count:
	printf -v str '%*s' "$count"
	#Replace every empty space with $repeat:
	printf -v result '%s' "${str// /$repeat}"

	echo "$result"
}

draw_box() {
	#Draw "+---...---+":
	printf '%s\n' "+$(repeat_str - $(($y_size-2)))+"

	#Draw "| .. $mines .. |":
	printf -v indent "$(repeat_str " " $((y_size/2-2)))"
	printf '%s\n' "|$indent$flags$indent|"

	#Draw "+---...---+":
	printf '%s\n' "+$(repeat_str - $(($y_size-2)))+"
}

draw_field() {
	#Draw symbol only if it is opened:
	for (( i = 1; i <= x_size; i++ )) do
		for (( j = 1; j <= y_size; j++ )) do
			if [[ ${F_opnd[$i,$j]} == 1 ]]; then
				local symbl=${F_symbls[$i,$j]}
				case $symbl in
				0)
					printf '%s' "0"
					;;
				1)
					printf '%b' "${BLUE}" "1" "${NOCLR}"
					;;
				2)
					printf '%b' "${GREEN}" "2" "${NOCLR}"
					;;
				3)
					printf '%b' "${RED}" "3" "${NOCLR}" 
					;;
				4)
					printf '%b' "${MAGENTA}" "4" "${NOCLR}" 
					;;
	
				5)
					printf '%b' "${PINK}" "5" "${NOCLR}" 
					;;
				6)
					printf '%b' "${CYAN}" "6" "${NOCLR}" 
					;;
				7)
					printf '%b' "${LIGHTYELLOW}" "7" "${NOCLR}" 
					;;
				8)
					printf '%b' "${YELLOW}" "8" "${NOCLR}" 
					;;
				X)
					printf '%b' "${BACKRED}" "X" "${NOCLR}"
				esac
			elif [[ ${F_opnd[$i,$j]} == 2 ]]; then
				printf '%b' "${BACKGREEN}" "F" "${NOCLR}"
			else
				printf '%b' "${GRAY}" "#" "${NOCLR}" 
			fi
		done
		printf '%s\n' ""
	done
}

draw_game() {
	#Info box:
	draw_box

	#Field itself:
	draw_field
}


#Gameplay functions:

reveal() {
	#Open symbol, if it is zero - open around it recursivly:
	F_opnd[$1,$2]=1

	if [[ ${F_symbls[$1,$2]} == X ]]; then
		mined_flag=1
	fi

	if [[ ${F_symbls[$1,$2]}  == 0 ]]; then
		for (( i = -1; i <= 1; i++ )) do
			for (( j = -1; j <= 1; j++ )) do
				local xo=$(($1+$i))
				local yo=$(($2+$j))
			
				if [[ $xo == $1 ]] && [[ $yo == $2 ]]; then
					continue
				fi

				if (( $xo >= 1)) && (( $xo <= $x_size )) && (( $yo >= 1 )) && (( $yo <= $y_size )); then
					if [[ ${F_opnd[$xo,$yo]} == 0 ]]; then
						reveal $xo $yo
						reveal $xo $yo
					fi
				fi
			done
		done
	fi
}

#Game inspector checks if game should end:

game_inspector() {
	local reveal_f=0

	if [[ $mined_flag == 1 ]]; then
		end_msg="YOU LOST!"
		reveal_f=1
	fi
	
	if [[ $true_flags == $mines ]]; then
		end_msg="YOU WON!"
		reveal_f=1
	fi

	#Reveal all field:
	if [[ $reveal_f == 1 ]]; then
		for (( i = 1; i <= x_size; i++ )) do
			for (( j = 1; j <= y_size; j++ )) do
				F_opnd[$i,$j]=1
			done
		done
		
		tput rc
		tput clear
		printf '%s\n' "$end_msg"
		draw_game

		sleep 10
		exit
	fi
}

#Controls handler:

controls_handler() {
	#Read one character from input and discard all others to avoid input lag:
	local key
	local discard
	read -n 1 -t 0.001 key
	read -t 0.001 discard

	#Calculating cursor position on the field:
	local x_f=$(($cur_x-2))
	local y_f=$(($cur_y+1))

	case $key in
	w)
		if (( $cur_x >= 4 )); then
			cur_x=$(($cur_x-1))
			draw_f=1
		fi
		;;
	a)
	
		if (( $cur_y >= 1 )); then
			cur_y=$(($cur_y-1))
			draw_f=1
		fi
		;;
			
	s)
		if (( $cur_x <= $x_size+1 )); then
			cur_x=$(($cur_x+1))
			draw_f=1
		fi
		;;
	d)
		if (( $cur_y <= $y_size-2 )); then
			cur_y=$(($cur_y+1))
			draw_f=1
		fi
		;;
	 e)
		if [[ ${F_opnd[$x_f,$y_f]} == 0 ]]; then 
		 	reveal $x_f $y_f
			draw_f=1
		fi 
		;;
	f)
		draw_f=1
		if [[ ${F_opnd[$x_f,$y_f]} == 0 ]] && (( $flags >= 1 )); then
			flags=$(($flags-1))
			F_opnd[$x_f,$y_f]=2
			if [[ ${F_symbls[$x_f,$y_f]} == X ]]; then
				true_flags=$(($true_flags+1))
			fi
		elif [[ ${F_opnd[$x_f,$y_f]} == 2 ]]; then
			flags=$(($flags+1))
		 	F_opnd[$x_f,$y_f]=0
			if [[ ${F_symbls[$x_f,$y_f]} == X ]]; then
				true_flags=$(($true_flags-1))
			fi
		fi
		;;
	esac
	tput cup $cur_x $cur_y
}

generate_field
tput rc
tput clear
draw_game

#Main loop:

while true
do
	#Draw only if action from player was taken:
	if [[ $draw_f == 1 ]]; then
		tput rc
		tput clear
		draw_game
		draw_f=0
	fi

	controls_handler
	game_inspector
done

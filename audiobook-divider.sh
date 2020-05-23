#!/bin/bash

#
# ------------------------------------------------------------
# "THE BEERWARE LICENSE" (Revision 42):
# <author> wrote this code. As long as you retain this
# notice, you can do whatever you want with this stuff. If we
# meet someday, and you think this stuff is worth it, you can
# buy me a beer in return.
# ------------------------------------------------------------
#

DEBUG=true

function debug() {
  if [ "${DEBUG}" = "true" ]; then
    echo "[DEBUG] ${1}"
  fi
}

function usage() {
  echo "Usage: $0 \\" 1>&2;
  echo "    [-i <image-location>] \\" 1>&2;
  echo "    [-a <artist>] \\" 1>&2;
  echo "    [-s <skip>] \\                       # default 0" 1>&2;
  echo "    [-d <duration-in-seconds>] \\        # default: 120s" 1>&2;
  echo "    [-g <genre-default-audiobook>] \\    # default 'audiobook'" 1>&2;
  echo "    [-p <package-size>] \\               # default 50" 1>&2;
  echo "    [-f path-to-ffmpeg-directory] \\     # default '/usr/local/bin/'" 1>&2;
  echo "    your-media-file " 1>&2;
  echo "" 1>&2;
  echo "    eg. $0 -f /bin -i screenshot.png -a \"Andrzej Wajda\" -d 30 my-movie.webm " 1>&2;
  echo "" 1>&2;
  exit 1;
}

function display_progress() {
  local current=${1}
  local duration=${2}
  local all_parts=${3}
  debug "display_progress (current='${current}', duration: '${duration}', all parts: '${all_parts}') {"
  local current_part=$(( ( ${current} + ${duration} ) / ${duration} ))
  debug "display_progress   current_part='${current_part}'"
  echo -n "\n\n    Working on ${current_part}/${all_parts}\n\n\n"
  debug "display_progress }"
}

function get_end_position() {
  local current=${1}
  local duration=${2}
  local length=${3}
  local end=$(( ${current} + ${duration} ))

  if [ ${end} -gt ${length} ]; then
    end=$(( ${length} ))
  fi
  echo "${end}"
}

function process_to_mp3() {
  local file="${1}"
  local target="${2}"
  local genre="${3}"
  local artist="${4}"
  debug "process_to_mp3 (file: '${file}', target: '${target}', genre: '${genre}', artist: '${artist}') {"

  echo "Converting file: '${file}' to mp3: ${target}"

  echo "${ffmpeg_location}/ffmpeg -i \"${1}\" -metadata genre=\"${genre}\" -metadata artist=\"${artist}\" -acodec libmp3lame -aq 4 \"${target}\""
  ${ffmpeg_location}/ffmpeg -i "${1}" \
      -metadata genre="${3}" \
      -metadata artist="${4}" \
      -acodec libmp3lame -aq 4 "${2}"
  echo -n "\n\n"
  debug "process_to_mp3 }"
}

function convert_to_mp3_or_reuse_existing_file() {
  local convert_to_mp3="true"
  local filename="${1}"
  local mp3_file_name="${2}"
  local artist="${3}"
  local genre="${4}"

  debug "convert_to_mp3_or_reuse_existing_file (filename: '${filename}', mp3_file_name: '${mp3_file_name}', artist: '${artist}', genre: '${genre}') {"
  if [ -f "${mp3_file_name}" ]; then
    debug "convert_to_mp3_or_reuse_existing_file   file already exits"
    read -r -p "Temp file ${mp3_file_name} already exists. Override? [y/N]" response
    case "$response" in
      [yY])
          debug "convert_to_mp3_or_reuse_existing_file answered to override"
          convert_to_mp3="true"
          ;;
      [nN])
          debug "convert_to_mp3_or_reuse_existing_file answered to reuse"
          convert_to_mp3="false"
          ;;
      *)
          echo "Invalid answer. Stop processing..."
          exit 1
          ;;
    esac
  fi

  if [ "true" == "${convert_to_mp3}" ]; then
    echo "Converting to mp3..."
    debug "convert_to_mp3_or_reuse_existing_file process_to_mp3((filename: '${filename}', mp3_file_name: '${mp3_file_name}', artist: '${artist}', genre: '${genre}')"
    process_to_mp3 "${filename}" "${mp3_file_name}" "${artist}" "${genre}"
  else
    echo "Skipping converting to mp3..."
  fi
  debug "convert_to_mp3_or_reuse_existing_file }"
}

ffmpeg_location="/usr/local/bin/"
image=""
duration=$(( 2 * 60 ))
genre="audiobook"
artist=""
skip=$(( 0 ))
package_size=$(( 50 ))

while getopts ":f:i:d:g:a:s:" o; do
    case "${o}" in
        f)
            ffmpeg_location=${OPTARG}
            ;;
        i)
            image=${OPTARG}
            ;;
        d)
            duration=${OPTARG}
            ;;
        g)
            genre=${OPTARG}
            ;;
        a)
            artist=${OPTARG}
            ;;
        s)
            skip=$(( ${OPTARG} ))
            ;;
        p)
            package_size=$(( ${OPTARG} ))
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

filename=${1}

if [ -z "${filename}" ]; then
  usage
fi

directory_name=${filename%.*}
debug "directory_name: '${directory_name}'"
directory_unified_name=`echo "${directory_name}" | iconv -f utf-8 -t us-ascii//TRANSLIT | sed -e 's/[ ]/_/g'`

echo ""
echo "Filename: ${filename}"
echo "Duration: ${duration}s"
echo "Media length: ${length}"
echo "Directory: ${directory_unified_name}"
echo "Skip: ${skip}"
echo ""

mkdir -p "${directory_unified_name}"

mp3_file_name="${directory_unified_name}/temp_all.mp3"
convert_to_mp3_or_reuse_existing_file "${filename}" "${mp3_file_name}" "${artist}" "${genre}"

length_string=$(${ffmpeg_location}/ffprobe -i "${mp3_file_name}" -show_entries format=duration -v quiet -of csv="p=0" | sed)
debug "length_string: '${length_string}', running: ${ffmpeg_location}/ffprobe -i \"${mp3_file_name}\" -show_entries format=duration -v quiet -of csv=\"p=0\" | sed"
length=${length_string%.*}

counter=$(( ( 000001 * ${skip} ) + 1 ))
current=$(( ${duration} * ${skip} ))
all_parts=$(( ${length} / ${duration} + 1 ))

debug "couter: '${counter}', current: '${current}', all_parts: '${all_parts}'"

function get_current_file_name() {
  local package_size="${1}"
  local dir="${2}"
  local counter="${3}"
  local length="${4}"
  local unified_counter=`printf "%03d\n" ${counter}`
  local current_file="${unified_counter}_${dir}"
  if [ ${package_size} -lt 1 ] || [ ${package_size} -lt ${length} ]; then
    local package=$(( ${counter} / ${package_size} ))
    package=$(( ${package} + 1 ))
    local unified_package=`printf "%02d\n" ${package}`
    if [ ! -d "${dir}/${dir}_${unified_package}" ]; then
      mkdir -p "${dir}/${dir}_${unified_package}"
    fi
    current_file="${dir}_${unified_package}/${unified_counter}_${dir}"
  fi
  
  echo "${current_file}"
}

function add_image() {
  local current_full_file_path="${1}"
  local temp_file="${2}"
  local image="${image}"

  debug "add_image (current_full_file_path: '${current_full_file_path}', temp_file: '${temp_file}', image: '${image}') {"
  if [ -n "${image}" ]; then  
    debug "add_image mv '${current_full_file_path}' '${temp_file}'"
    mv "${current_full_file_path}" "${temp_file}"
    local command="${ffmpeg_location}/ffmpeg -i \"${temp_file}\" -i \"${image}\" -map_metadata 0 -map 0 -map 1 \"${current_full_file_path}\""
    debug "add_image adding image via command: ${command}"
    eval "${command}"
    debug "add_image remove temp file: ${temp_file}"
    rm "${temp_file}"
  else
    debug "add_image skipping adding image as image is empty"
  fi
  debug "add_image }"
}

function create_mp3_file_part() {
  local current_full_file_path="${1}"
  local mp3_file_name="${2}"
  local start="${3}"
  local duration="${4}"
  local artist="${5}"
  local genre="${6}"

  local command="${ffmpeg_location}/ffmpeg -i \"${mp3_file_name}\" -metadata genre=\"${genre}\" -metadata artist=\"${artist}\" -ss ${start} -t ${duration} -acodec copy \"${current_full_file_path}\""
  debug "create_mp3_file_part (current_full_file_path: '${current_full_file_path}', mp3_file_name: '${mp3_file_name}', start: '${start}', duration: '${duration}', artist: '${artist}', genre: '${genre}') {"
  debug "create_mp3_file_part running command: ${command}"
  eval "${command}"
  debug "create_mp3_file_part }"
}

while [ ${current} -lt ${length} ]
do
  display_progress ${current} ${duration} ${all_parts}

  current_file=$(get_current_file_name ${package_size} ${directory_unified_name} ${counter} ${all_parts})
  parrent_dir=$(dirname "${current_file}")
  debug "main loop: creating dir: '${parrent_dir}'"
  mkdir -p "${parrent_dir}"

  start=$(( ${current} ))
  end=$(get_end_position ${current} ${duration} ${length})

  echo -n "${current_file} -> ${start} - ${end}\n"

  current_full_file_path=${directory_unified_name}/${current_file}.mp3
  temp_file=${directory_unified_name}/${current_file}.tmp.mp3

  create_mp3_file_part "${current_full_file_path}" "${mp3_file_name}" "${start}" "${duration}" "${artist}" "${genre}"
  add_image "${current_full_file_path}" "${temp_file}" "${image}"

  current=$(( ${current} + ${duration} ))
  counter=$(( ${counter} + 1 ))
done


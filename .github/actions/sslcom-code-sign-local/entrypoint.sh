#!/usr/bin/env bash
# Adapted from https://github.com/bioblaze/sslcom-code-signer (v5 entrypoint.sh).
# Uses CODE_SIGN_ROOT instead of hard-coded /codesign for non-Docker installs.
set -e

CODE_SIGN_ROOT="${CODE_SIGN_ROOT:-/codesign}"

echo "::group::Run CodeSigner"

echo "Running ESigner.com CodeSign Action (local) ====>"
echo ""

if [[ "${INPUT_ENVIRONMENT_NAME:-}" != "PROD" ]]; then
  cp "${CODE_SIGN_ROOT}/conf/code_sign_tool.properties" "${CODE_SIGN_ROOT}/conf/code_sign_tool.properties.production"
  cp "${CODE_SIGN_ROOT}/conf/code_sign_tool_demo.properties" "${CODE_SIGN_ROOT}/conf/code_sign_tool.properties"
fi

BASE_COMMAND="${CODE_SIGN_ROOT}/CodeSignTool.sh"

# Supported file types
SUPPORTED_FILE_TYPES="acm ax bin cab cpl dll drv efi exe mui ocx scr sys tsp msi ps1 ps1xml js vbs wsf jar nupkg"

# Common flags for all executions (match upstream sslcom-code-signer entrypoint.sh)
COMMON_FLAGS=""
[ ! -z "${INPUT_COMMAND:-}" ] && COMMON_FLAGS="$COMMON_FLAGS $INPUT_COMMAND"
[ ! -z "${INPUT_USERNAME:-}" ] && COMMON_FLAGS="$COMMON_FLAGS -username $INPUT_USERNAME"
[ ! -z "${INPUT_PASSWORD:-}" ] && COMMON_FLAGS="$COMMON_FLAGS -password \"$INPUT_PASSWORD\""
[ ! -z "${INPUT_CREDENTIAL_ID:-}" ] && COMMON_FLAGS="${COMMON_FLAGS} -credential_id ${INPUT_CREDENTIAL_ID}"
[ ! -z "${INPUT_TOTP_SECRET:-}" ] && COMMON_FLAGS="${COMMON_FLAGS} -totp_secret \"${INPUT_TOTP_SECRET}\""
[ ! -z "${INPUT_PROGRAM_NAME:-}" ] && COMMON_FLAGS="${COMMON_FLAGS} -program_name ${INPUT_PROGRAM_NAME}"
[ ! -z "${INPUT_OUTPUT_PATH:-}" ] && COMMON_FLAGS="${COMMON_FLAGS} -output_dir_path ${INPUT_OUTPUT_PATH}"

# Conditional flags
[ ! -z "${INPUT_MALWARE_BLOCK:-}" ] && [ "${INPUT_COMMAND:-}" != "batch_sign" ] && COMMON_FLAGS="${COMMON_FLAGS} -malware_block=${INPUT_MALWARE_BLOCK}"
[ ! -z "${INPUT_OVERRIDE:-}" ] && [ "${INPUT_COMMAND:-}" != "batch_sign" ] && COMMON_FLAGS="${COMMON_FLAGS} -override=${INPUT_OVERRIDE}"

# Check and create OUTPUT_PATH if not exists
if [ -n "${INPUT_OUTPUT_PATH:-}" ] && [ ! -d "${INPUT_OUTPUT_PATH}" ]; then
  echo "Directory does not exist, creating director: ${INPUT_OUTPUT_PATH}"
  mkdir -p "${INPUT_OUTPUT_PATH}"
fi

# Handling individual file signing if a directory is specified
if [ ! -z "${INPUT_DIR_PATH:-}" ] && [ -d "${INPUT_DIR_PATH}" ]; then
  for file in "${INPUT_DIR_PATH}"/*; do
    # Extract file extension
    file_ext="${file##*.}"

    # Check if file extension is in the list of supported file types
    if [[ $SUPPORTED_FILE_TYPES =~ (^|[[:space:]])$file_ext($|[[:space:]]) ]]; then
      FILE_COMMAND="$BASE_COMMAND $COMMON_FLAGS -input_file_path \"$file\""
      echo "Processing file: $file"
      echo "$FILE_COMMAND"
      FILE_RESULT=$(bash -c "set -e; $FILE_COMMAND 2>&1")
      if [[ "$FILE_RESULT" =~ .*"Error".* || "$FILE_RESULT" =~ .*"Exception".* ]]; then
        echo "::error::Something Went Wrong with file $file. Please try again."
        echo "::error::$FILE_RESULT"
        exit 1
      else
        echo "$FILE_RESULT"
      fi
    else
      echo "Unsupported file type, moving to output path: $file"
      if [ -n "${INPUT_OUTPUT_PATH:-}" ]; then
        mv "$file" "${INPUT_OUTPUT_PATH}/"
        echo "Moved unsupported file to: ${INPUT_OUTPUT_PATH}"
      else
        echo "Skipping move because OUTPUT_PATH is not set."
      fi
    fi
  done
elif [ ! -z "${INPUT_FILE_PATH:-}" ]; then
  file_ext="${INPUT_FILE_PATH##*.}"
  if [[ $SUPPORTED_FILE_TYPES =~ (^|[[:space:]])$file_ext($|[[:space:]]) ]]; then
    FINAL_COMMAND="$BASE_COMMAND $COMMON_FLAGS -input_file_path \"$INPUT_FILE_PATH\""
    echo "$FINAL_COMMAND"
    RESULT=$(bash -c "set -e; $FINAL_COMMAND 2>&1")
    if [[ "$RESULT" =~ .*"Error".* || "$RESULT" =~ .*"Exception".* ]]; then
      echo "::error::Something Went Wrong. Please try again."
      echo "::error::$RESULT"
      exit 1
    else
      echo "SELECTED_COLOR=green" >> "${GITHUB_OUTPUT}"
      echo "$RESULT"
    fi
  else
    echo "Unsupported file type, moving to output path: $INPUT_FILE_PATH"
    if [ -n "${INPUT_OUTPUT_PATH:-}" ]; then
      mv "$INPUT_FILE_PATH" "${INPUT_OUTPUT_PATH}/"
      echo "Moved unsupported file to: ${INPUT_OUTPUT_PATH}"
    else
      echo "Skipping move because OUTPUT_PATH is not set."
    fi
  fi
fi

if [[ "${INPUT_CLEAN_LOGS:-}" == "true" || "${INPUT_CLEAN_LOGS:-}" == true ]]; then
  rm -rf "${CODE_SIGN_ROOT}/logs"/*.log
  echo "CodeSigner logs folder is deleted: ${CODE_SIGN_ROOT}/logs"
fi

echo "::endgroup::"
exit 0

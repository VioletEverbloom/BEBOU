#!/usr/bin/env bash
# Copyright (C) 2025 Griefed
#
# This script was modified by VioletEverbloom. You can find a link to the source and the script's licence in docs/CREDITS.md 


# commandAvailable(command)
# Check whether the command $1 is available for execution. Can be used in if-statements.
commandAvailable() {
  command -v "$1" > /dev/null 2>&1
}

# installJabba
# Downloads and installs Jabba, the software used to download and install Java for the Minecraft server.
installJabba() {
  echo "Downloading and installing jabba."
  if commandAvailable curl ; then
    curl -sL $JABBA_INSTALL_URL_SH | bash && . ~/.jabba/jabba.sh
  elif commandAvailable wget ; then
    wget -qO- $JABBA_INSTALL_URL_SH | bash && . ~/.jabba/jabba.sh
  else
    echo "[ERROR] wget or curl is required to install jabba."
    exit 1
  fi
  [ -s "$JABBA_HOME/jabba.sh" ] && source "$JABBA_HOME/jabba.sh"
}

if [[ ! -s "_variables.txt" ]]; then
  echo "ERROR! _variables.txt not present. Without it the server can not be installed, configured or started."
  exit 1
fi

source "./_variables.txt"

# if ldd is not available, we may be on MacOS
if commandAvailable ldd ; then
  GBLIC_VERSION=$(ldd --version | awk '/ldd/{print $NF}')
  IFS="." read -ra GBLIC_SEMANTICS <<<"${GBLIC_VERSION}"

  # Older Linux systems aren't supported, sadly. This mainly affects Ubuntu 20 and Linux distributions from around that time
  # which use glibc versions older than 2.32 & 2.34.
  if [[ ${GBLIC_SEMANTICS[1]} -lt 32 ]];then
    echo "Jabba only supports systems with glibc 2.32 & 2.34 onward. You have $GBLIC_VERSION. Automated Java installation can not proceed."
    echo "DO NOT ATTEMPT TO UPDATE OR UPGRADE YOUR INSTALLED VERSION OF GLIBC! DOING SO MAY CORRUPT YOUR ENTIRE SYSTEM!"
    echo "Instead, consider upgrading to a newer version of your OS. Example: In case of Ubuntu 20 LTS, consider upgrading to 22 LTS or 24 LTS."
    echo ""
    echo "If that is not an option, you will have to install the required Java version on your system manually, the old fashioned way."
    echo "Your _variables.txt says you require: ${JDK_VENDOR}@${RECOMMENDED_JAVA_VERSION}"
    echo "When you installed said Java version, 'SKIP_JAVA_CHECK=true' in the _variables.txt and run the start-script again."
    exit 1
  fi
fi

export JABBA_VERSION=${JABBA_INSTALL_VERSION}

if [[ -s ~/.jabba/jabba.sh ]];then
  source ~/.jabba/jabba.sh
elif ! commandAvailable jabba ; then
  echo "Automated Java installation requires a piece of Software called 'Jabba'."
  echo "Type 'I agree' if you agree to the installation of the aforementioned software."
  echo -n "Response: "
  read -r ANSWER

  if [[ "${ANSWER}" == "I agree" ]]; then
    installJabba
  else
    echo "User did not agree to Jabba installation. Aborting Java installation process."
    exit 1
  fi
fi

echo "Downloading and using Java ${JDK_VENDOR}@${RECOMMENDED_JAVA_VERSION}"
jabba install ${JDK_VENDOR}@${RECOMMENDED_JAVA_VERSION}
jabba use ${JDK_VENDOR}@${RECOMMENDED_JAVA_VERSION}

echo "Installation finished. Returning to start-script."
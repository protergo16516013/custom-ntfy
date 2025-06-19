#!/bin/sh
ADMINS="${ADMINS}"
USERS="${USERS}"
USERS_FILE="/var/lib/ntfy/users.list"


# initial checks
if [ -z "$ADMINS" ] && [ -z "$USERS" ]; then
  echo "ERROR! environment variable ADMINS and USERS are empty!"
  echo "EXiting..."
  exit 1
fi

mkdir -p "$(dirname '${USERS_FILE}')" 2>/dev/null
touch "${USERS_FILE}" 2>/dev/null
if [ ! -f "${USERS_FILE}" ]; then
  echo "ERROR! Cannot create users file at ${USERS_FILE}"
  exit 1
fi


# block all and only allow rw for public-*
ntfy access everyone "*" deny
ntfy access everyone "public-*" rw



# create users and admin based on env
generate_random() {
  local length="${1:=16}"
  echo "$(tr -dc A-Za-z0-9 </dev/urandom | head -c ${length}; echo)"
}

loop_overlist(){
  local list="${1}"
  local role="${2}"

  OLDIFS="${IFS}"
  IFS=','
  for item in $list; do
    if grep -q "^${item}" "$USERS_FILE"; then
      echo "User ${item} already exist! Skipping."
      continue
    fi

    local password="$(generate_random 24)"
    if [ "${role}" = "admin" ]; then
      echo -e "${password}\n${password}" | ntfy user add --role=admin "${item}"
    else
      echo -e "${password}\n${password}" | ntfy user add "${item}"
    fi
    echo "a user was generated! ${item}:${password}"

    echo "${item}:${password}:${role}" >> "${USERS_FILE}"
  done
  IFS="${OLDIFS}"
}

init_user() {
  loop_overlist "${ADMINS}" "admin"
  loop_overlist "${USERS}" "user"
}


# start the server first before any modification
(sleep 3;init_user) & ntfy "$@"
#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon -t -c"

SHOW_SERVICES() {
  RESULT_SERVICES=$($PSQL "SELECT service_id, name FROM services")
  
  if [[ -z "$RESULT_SERVICES" ]]; then
    echo "No services available."
    return
  fi

  echo "Available Services:"
  echo "$RESULT_SERVICES" | while read ID BAR NAME
  do
    if [[ $ID =~ ^[0-9]+$ ]]; then
      echo "$ID) $NAME"
    fi
  done
}

PICK_SERVICE() {
  while true; do
    echo -e "\nPick a service by ID:"
    read SERVICE_ID_SELECTED
    
    RESULT_FOUND_SERVICE=$($PSQL "SELECT service_id, name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
    
    if [[ -z "$RESULT_FOUND_SERVICE" || "$RESULT_FOUND_SERVICE" =~ "0 rows" ]]; then
      echo -e "\nService not found. Please pick a valid service ID.\n"
      SHOW_SERVICES
    else
      break
    fi
  done
}

CREATE_CUSTOMER() {
  CUSTOMER_NAME=$1
  CUSTOMER_PHONE=$2

  INSERT_RESULT=$($PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
  
  if [[ $? -eq 0 ]]; then
    echo "Customer $CUSTOMER_NAME with phone $CUSTOMER_PHONE has been successfully added."
  else
    echo "Error adding customer."
  fi
}

CREATE_APPOINTMENT() {
  CUSTOMER_ID=$1
  SERVICE_ID=$2
  APPOINTMENT_TIME=$3

  RESULT_SERVICE=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID")
  if [[ -z $RESULT_SERVICE ]]; then
    echo "Invalid service ID, returning to the main menu."
    MAIN_MENU
    return
  fi

  RESULT_CUSTOMER=$($PSQL "SELECT customer_id FROM customers WHERE customer_id = $CUSTOMER_ID")
  if [[ -z $RESULT_CUSTOMER ]]; then
    echo "Invalid customer ID, returning to the main menu."
    MAIN_MENU
    return
  fi

  INSERT_APPOINTMENT=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID, '$APPOINTMENT_TIME')")
  
  if [[ $? -eq 0 ]]; then
    CUSTOMER_NAME=$(echo $($PSQL "SELECT TRIM(name) FROM customers WHERE customer_id = $CUSTOMER_ID"))
    SERVICE_NAME=$(echo $($PSQL "SELECT TRIM(name) FROM services WHERE service_id = $SERVICE_ID"))

    echo "I have put you down for a $SERVICE_NAME at $APPOINTMENT_TIME, $CUSTOMER_NAME."
  else
    echo "Error scheduling appointment."
  fi
}

MAIN_MENU() {
  SHOW_SERVICES
  PICK_SERVICE
  
  echo -e "\nEnter your phone number:"
  read CUSTOMER_PHONE

  # Check if the customer already exists
  RESULT_FOUND_CUSTOMER=$($PSQL "SELECT customer_id, name FROM customers WHERE phone='$CUSTOMER_PHONE'")

  if [[ -z "$RESULT_FOUND_CUSTOMER" || "$RESULT_FOUND_CUSTOMER" =~ "0 rows" ]]; then
    echo -e "\nThis phone number is not registered. Please enter your name:"
    read CUSTOMER_NAME
    CREATE_CUSTOMER "$CUSTOMER_NAME" "$CUSTOMER_PHONE"
    # Get the new customer_id
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  else
    CUSTOMER_ID=$(echo "$RESULT_FOUND_CUSTOMER" | cut -d '|' -f 1)
    CUSTOMER_NAME=$(echo "$RESULT_FOUND_CUSTOMER" | cut -d '|' -f 2)
  fi
  
  echo -e "\nEnter the time for the appointment:"
  read SERVICE_TIME

  CREATE_APPOINTMENT $CUSTOMER_ID $SERVICE_ID_SELECTED "$SERVICE_TIME"
}

MAIN_MENU

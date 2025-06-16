#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "copying Mongodb.repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "installing Mongodb"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "enabling Mongodb"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "starting Mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$LOG_FILE
VALIDATE $? "changing to Ipv4"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "restarting mongodb"

echo "MongoDB Setup Completed Successfully."

# #!/bin/bash

# USERID=$(id -u)
# R="\e[31m"
# G="\e[32m"
# Y="\e[33m"
# N="\e[0m"
# LOGS_FOLDER="/var/log/roboshop-logs"
# SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
# LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

# mkdir -p $LOGS_FOLDER
# echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# if [ $USERID -ne 0 ]; then
#     echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
#     exit 1
# else
#     echo "You are running with root access" | tee -a $LOG_FILE
# fi

# VALIDATE(){
#     if [ $1 -eq 0 ]; then
#         echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
#     else
#         echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
#         exit 1
#     fi
# }

# COMMANDS=(
#     "cp mongo.repo /etc/yum.repos.d/mongo.repo"
#     "dnf install mongodb-org -y"
#     "systemctl enable mongod"
#     "systemctl start mongod"
#     "sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf"
#     "systemctl restart mongod"
# )

# DESCRIPTIONS=(
#     "copying Mongodb.repo"
#     "installing Mongodb"
#     "enabling Mongodb"
#     "starting Mongodb"
#     "changing to Ipv4"
#     "restarting Mongodb"
# )

# for i in "${!COMMANDS[@]}"; do
#     ${COMMANDS[i]} &>>$LOG_FILE
#     VALIDATE $? "${DESCRIPTIONS[i]}"
# done


# #!/bin/bash

# # Stop the script if any command fails
# set -e

# # --- Configuration ---
# LOGS_FOLDER="/var/log/roboshop-logs"
# # More robust way to get the script name without extension
# SCRIPT_NAME=$(basename "$0" .sh)
# LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

# # --- Colors for Output ---
# R="\e[31m"
# G="\e[32m"
# N="\e[0m"

# # --- Setup ---
# mkdir -p "$LOGS_FOLDER"
# # Redirect all script output (stdout and stderr) to a log file and also show it on the terminal
# exec &> >(tee -a "$LOG_FILE")

# echo "Script started executing at: $(date)"

# # --- Pre-run Checks ---
# if [ "$(id -u)" -ne 0 ]; then
#    echo -e "$R ERROR:: Please run this script with root access $N"
#    exit 1
# fi

# # --- Core Function ---
# # This function executes a command and validates its success.
# # It takes the description as the first argument and the command as the rest.
# VALIDATE() {
#     DESCRIPTION=$1
#     # The 'shift' command removes the first argument, so $@ now contains only the command to run.
#     shift
#     COMMAND="$@"
    
#     echo -n "$DESCRIPTION... "
    
#     # Run the command, suppressing its output from the console but it will still be logged due to 'exec'
#     $COMMAND &>/dev/null
    
#     # Check the exit status and print the result
#     if [ $? -eq 0 ]; then
#         echo -e "$G SUCCESS $N"
#     else
#         echo -e "$R FAILURE $N"
#         echo "Check the log file for details: $LOG_FILE"
#         exit 1
#     fi
# }

# # --- Main Logic ---
# VALIDATE "Copying MongoDB repo file"      cp mongo.repo /etc/yum.repos.d/mongo.repo
# VALIDATE "Installing MongoDB"             dnf install mongodb-org -y
# VALIDATE "Enabling MongoDB service"       systemctl enable mongod
# VALIDATE "Starting MongoDB service"       systemctl start mongod
# VALIDATE "Updating MongoDB listen address" sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
# VALIDATE "Restarting MongoDB service"     systemctl restart mongod

# echo "MongoDB Setup Completed Successfully."
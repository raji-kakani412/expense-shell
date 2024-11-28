#!/bin/bash

LOGS_FOLDER="/var/logs/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1) # where $0 gives us script name 17-redirectors.sh
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER #Creates a folder shell-script

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"


#Functions
CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then 
        echo -e "$R Please run this script with root privileges $N" | tee -a $LOG_FILE
        exit 1
    fi
}


VALIDATE(){
    if [ $1 -ne 0 ]
    then 
        echo -e "$2 is $R failed $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is $G success $N"  | tee -a $LOG_FILE
    fi
}

echo "script started executing at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT 

dnf list installed mysql-server
if [ $? -ne 0 ]
then
    echo "MySQL is not installed. Going to install it.."
    dnf install mysql-server -y &>>$LOG_FILE
    VALIDATE $? "Installing MySQL server"
else
    echo "MySQL is already installed. Nothing to do.."
fi

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabled MySQL server"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Started MySQL server"

# create mysql.devops-aws.tech r53 record first or update them if already exits
mysql -h mysql.devops-aws.tech -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo "MySQL root password is not set up. Setting up now.." &>>$LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE
    VALIDATE $? "Setting up root password"
else
    echo -e "MySQL root password is already setup. $Y Skipping.. $N" | tee -a $LOG_FILE
fi
#!/bin/bash

# AMI_ID="ami-09c813fb71547fc4f"
# SG_ID="sg-0f63039a616382c25" 
# INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
# ZONE_ID="Z0443285370E15R10QIN" 
# DOMAIN_NAME="dsops84.space"

# #for instance in ${INSTANCES[@]}
# for instance in $@
# do
#     INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-0f63039a616382c25 --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)
#     if [ $instance != "frontend" ]
#     then
#         IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
#         RECORD_NAME="$instance.$DOMAIN_NAME"
#     else
#         IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
#         RECORD_NAME="$DOMAIN_NAME"
#     fi
#     echo "$instance IP address: $IP"

#     aws route53 change-resource-record-sets \
#     --hosted-zone-id $ZONE_ID \
#     --change-batch '
#     {
#         "Comment": "Creating or Updating a record set for cognito endpoint"
#         ,"Changes": [{
#         "Action"              : "UPSERT"
#         ,"ResourceRecordSet"  : {
#             "Name"              : "'$RECORD_NAME'"
#             ,"Type"             : "A"
#             ,"TTL"              : 1
#             ,"ResourceRecords"  : [{
#                 "Value"         : "'$IP'"
#             }]
#         }
#         }]
#     }'
# done

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0f63039a616382c25"
ZONE_ID="Z0443285370E15R10QIN"
DOMAIN_NAME="dsops84.space"

# Example usage: ./script.sh mongodb redis frontend
for instance in "$@"
do
    echo "Launching instance: $instance"

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t2.micro \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    echo "Instance ID: $INSTANCE_ID"

    # Wait for the instance to be in 'running' state
    echo "Waiting for instance to enter 'running' state..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    # Retrieve Private and Public IPs
    PRIVATE_IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text)

    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text)

    # Determine DNS record name
    if [ "$instance" != "frontend" ]; then
        RECORD_NAME="$instance.$DOMAIN_NAME"
        ROUTE53_IP="$PRIVATE_IP"
    else
        RECORD_NAME="$DOMAIN_NAME"
        ROUTE53_IP="$PUBLIC_IP"
    fi

    echo "$instance launched successfully:"
    echo "  Private IP: $PRIVATE_IP"
    echo "  Public IP : $PUBLIC_IP"
    echo "  Route53 will point $RECORD_NAME to $ROUTE53_IP"

    # Update Route53 record
    aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "
    {
        \"Comment\": \"Creating or Updating a record set for $RECORD_NAME\",
        \"Changes\": [{
            \"Action\": \"UPSERT\",
            \"ResourceRecordSet\": {
                \"Name\": \"$RECORD_NAME\",
                \"Type\": \"A\",
                \"TTL\": 1,
                \"ResourceRecords\": [{
                    \"Value\": \"$ROUTE53_IP\"
                }]
            }
        }]
    }"
    echo "Route53 record updated for $RECORD_NAME"
    echo "-----------------------------------------"
done
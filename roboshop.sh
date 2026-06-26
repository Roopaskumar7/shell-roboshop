#!/bin/bash

# shellcheck disable=SC2034
AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0222f350150ea711b"
INSTANCES=("mongob" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "Shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z0946757NTIK8E1MS5MG"
DOMAIN_NAME="roopaskumar.online"

# shellcheck disable=SC2068
for instance in ${INSTANCES[@]}
do
     
    # shellcheck disable=SC1073
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0220d79f3f480ecf5 --instance-type t3.micro --security-group-ids sg-0222f350150ea711b --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)
    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
         IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi
     echo "$instance IP address: $IP"

      # shellcheck disable=SC1009
      aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating or Updating a record set for cognito endpoint"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }'
done
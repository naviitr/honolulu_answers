#!/bin/bash -e

export SHA=`ruby -e 'require "opendelivery"' -e "puts OpenDelivery::Domain.new('$region').get_property '$sdb_domain','$pipeline_instance_id', 'SHA'"`
export timestamp=`ruby -e 'require "opendelivery"' -e "puts OpenDelivery::Domain.new('$region').get_property '$sdb_domain','$pipeline_instance_id', 'started_at'"`
echo checking out revision $SHA
git checkout $SHA

# hardcoding this for now until I figure out how to get it into Jenkins
VPC=vpc-35947a50
PublicSubnet=subnet-7300e204
PrivateSubnetA=subnet-7200e205
PrivateSubnetB=subnet-4fae682a

gem install trollop opendelivery --no-ri --no-rdoc
gem install aws-sdk-core --pre --no-ri --no-rdoc
export stack_name=HonoluluAnswers-$timestamp
ruby -e 'require "opendelivery"' -e "OpenDelivery::Domain.new('$region').set_property '$sdb_domain','$pipeline_instance_id', 'stack_name', '$stack_name'"
aws cloudformation create-stack --stack-name $stack_name --template-body "`cat pipeline/config/honolulu.template`" --region ${region}  --disable-rollback --capabilities="CAPABILITY_IAM" \
  ParameterKey=vpc,ParameterValue=$VPC \
  ParameterKey=publicSubnet,ParameterValue=$PublicSubnet \
  ParameterKey=privateSubnetA,ParameterValue=$PrivateSubnetA \
  ParameterKey=privateSubnetB,ParameterValue=$PrivateSubnetB \

# make sure we give AWS a chance to actually create the stack...
sleep 30
ruby pipeline/bin/monitor_stack.rb  --stack $stack_name --region ${region}

ruby -e 'require "opendelivery"' -e "OpenDelivery::Domain.new('$region').set_property '$sdb_domain','$pipeline_instance_id', 'furthest_pipeline_stage_completed', 'build-and-deploy'"
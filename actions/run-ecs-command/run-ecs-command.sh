#!/bin/bash
set -o errexit
set -o nounset

YELLOW='\033[1;33m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
RED='\033[0;31m'
NC='\033[0m'

sudo apt-get install -y expect

echo $(cat "${TASK_DEFINITION_JSON_FILE}" | jq 'del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities) | del(.registeredAt) | del(.registeredBy)') > "${TASK_DEFINITION_JSON_FILE}"
task_definition_arn=$(aws ecs register-task-definition --cli-input-json "file://${TASK_DEFINITION_JSON_FILE}" | jq -r '.taskDefinition.taskDefinitionArn')
printf "Registered new task definition with arn: ${GREEN}${task_definition_arn}${NC}.\n"

task_arn=$(aws ecs run-task --task-definition "${task_definition_arn}" --cluster "${CLUSTER_NAME}" --query "tasks[0].taskArn" --output text)
task_id=${task_arn##*/}

printf "Started task with arn: ${GREEN}${task_arn}${NC} and id: ${GREEN}${task_id}${NC}\n"

printf "Waiting for task to start... "
aws ecs wait tasks-running --cluster "${CLUSTER_NAME}" --tasks "${task_arn}" &>/dev/null ||: # wait for start, ignore "already stopped" error
printf "${GREEN}Done!${NC}\n"

log_conf_json=$(aws ecs describe-task-definition --task-definition raidtimers-com-command | jq '.taskDefinition.containerDefinitions[0].logConfiguration.options')
log_stream_prefix=$(echo $log_conf_json | jq -r '.["awslogs-stream-prefix"]')
log_group=$(echo $log_conf_json | jq -r '.["awslogs-group"]')
log_stream="${log_stream_prefix}/${log_group}/${task_id}"

printf "Tailing output of task ${BLUE}${task_id}${NC} for from Cloudwatch group: ${GREEN}${log_group}${NC}, stream: ${GREEN}${log_stream}${NC}.\n"
unbuffer aws logs tail "${log_group}" --log-stream-names "${log_stream}" --since 30m --follow &

printf "Waiting for task to finish... "
aws ecs wait tasks-stopped --cluster "${CLUSTER_NAME}" --tasks "${task_arn}"
printf "${GREEN}Done!${NC}\n"

sleep 6 # allow final polling period of aws logs tail
exit_code=$(aws ecs describe-tasks --cluster "${CLUSTER_NAME}" --tasks "${task_arn}" --query "tasks[0].containers[0].exitCode" --output text)
printf "Task ${BLUE}${task_arn}${NC} exited with code: ${YELLOW}${exit_code}${NC}.\n"

exit "${exit_code}"

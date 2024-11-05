# resource "aws_cloudwatch_log_subscription_filter" "api_access_logging_to_kinesis_firehose_subscription_filter" {
#   name            = "Kinesis Firehose"
#   role_arn        = aws_iam_role.api_gateway_access_logging_log_group_to_kinesis_firehose_subscription_filter.arn
#   log_group_name  = aws_cloudwatch_log_group.api_access_logging.name
#   filter_pattern  = ""
#   destination_arn = aws_kinesis_firehose_delivery_stream.api_gateway_access_logging.arn
# }
# 
# resource "aws_iam_role" "api_gateway_access_logging_log_group_to_kinesis_firehose_subscription_filter" {
#   name                = "api-gateway-access-logging-log-group-to-kinesis-firehose-sub-fil"
#   path                = "/aws-playground/sample-arch/"
#   assume_role_policy  = data.aws_iam_policy_document.trust_policy_for_cloud_watch_logs.json
# }
# 
# resource "aws_iam_role_policy_attachment" "api_gateway_access_logging_log_group_to_kinesis_firehose_subscription_filter_role_attach" {
#   role       = aws_iam_role.api_gateway_access_logging_log_group_to_kinesis_firehose_subscription_filter.name
#   policy_arn = aws_iam_policy.api_gateway_access_logging_kinesis_firehose_policy.arn
# }

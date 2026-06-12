# sns.tf - SNS Topic and Email Subscription

# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "cpu_alarm" {
  name         = "${var.project_name}-cpu-high-alert"
  display_name = "CPU High Alert"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-cpu-alert-topic"
    }
  )
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "cpu_alarm_email" {
  topic_arn = aws_sns_topic.cpu_alarm.arn
  protocol  = "email"
  endpoint  = var.email_address

  # Note: Email subscriptions require manual confirmation
  # Check your email inbox after terraform apply
}

# SNS Topic Policy (allow CloudWatch to publish)
resource "aws_sns_topic_policy" "cpu_alarm" {
  arn    = aws_sns_topic.cpu_alarm.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "AllowCloudWatchToPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    actions = [
      "SNS:Publish"
    ]

    resources = [
      aws_sns_topic.cpu_alarm.arn
    ]
  }

  statement {
    sid    = "AllowAccountAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }

    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish"
    ]

    resources = [
      aws_sns_topic.cpu_alarm.arn
    ]
  }
}

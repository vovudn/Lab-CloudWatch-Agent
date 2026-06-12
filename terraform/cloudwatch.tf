# cloudwatch.tf - CloudWatch Alarm for CPU monitoring

# CloudWatch Alarm for High CPU
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high-alarm"
  alarm_description   = "Alert when CPU utilization > ${var.cpu_alarm_threshold}% for ${var.cpu_alarm_period} seconds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_alarm_period
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.cloudwatch_lab.id
  }

  alarm_actions = [
    aws_sns_topic.cpu_alarm.arn
  ]

  ok_actions = [
    aws_sns_topic.cpu_alarm.arn
  ]

  insufficient_data_actions = []

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-cpu-alarm"
    }
  )

  depends_on = [
    aws_instance.cloudwatch_lab,
    aws_sns_topic.cpu_alarm
  ]
}

# CloudWatch Dashboard (Optional)
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "CPU Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 CPU Utilization"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["CWAgent", "mem_used_percent", { stat = "Average", label = "Memory Used %" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Memory Utilization"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      }
    ]
  })
}

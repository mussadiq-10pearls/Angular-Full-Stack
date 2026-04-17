output "bucket_name" {
  value = aws_s3_bucket.eb_bucket.bucket
}

output "app_name" {
  value = aws_elastic_beanstalk_application.app.name
}

output "env_name" {
  value = aws_elastic_beanstalk_environment.env.name
}
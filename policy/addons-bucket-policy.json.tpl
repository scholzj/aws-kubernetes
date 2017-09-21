{
  "Version": "2012-10-17",
  "Id": "${bucket_name}",
  "Statement": [
    {
      "Sid": "AllowGet",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${node_role_arn}",
          "${master_role_arn}"
        ]
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${bucket_name}",
        "arn:aws:s3:::${bucket_name}/*"
      ]
    }
  ]
}
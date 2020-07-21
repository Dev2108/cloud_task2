
provider "aws"{
	region = "ap-south-1"
	profile = "dev"
}

resource "aws_s3_bucket" "bucket1" {
  bucket = "my-tf-task-bucket1"
  acl    = "private"
  region ="ap-south-1"

  tags = {
    Name        = "My_tfbucket"
  }
}
locals {
   s3_origin_id="s3-origin" 
}

 resource "aws_s3_bucket_public_access_block" "s3_public"{
       bucket = "my-tf-task-bucket1"


   block_public_acls  = false
   block_public_policy  = false
}

resource "aws_s3_bucket_object" "object" {
  bucket = "my-tf-task-bucket1"
   key ="dawneyjr.jpg"
  source ="C:/Users/Prashant/Downloads/dawneyjr.jpg"
  acl = "public-read"
}
  



resource "aws_cloudfront_distribution" "devtfs3_distribution" {
 depends_on = [aws_s3_bucket.bucket1]
 origin {
    domain_name = aws_s3_bucket.bucket1.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    custom_origin_config {
        http_port = 80
        https_port = 80
       origin_protocol_policy = "match-viewer"
         origin_ssl_protocols=["TLSv1","TLSv1.1","TLSv1.2"] 
  }
}


enabled             = true
  

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
     
    }
  }


  

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
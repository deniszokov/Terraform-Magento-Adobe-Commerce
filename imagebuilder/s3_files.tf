# # ---------------------------------------------------------------------------------------------------------------------#
# Upload ImageBuilder build script to s3 bucket
# # ---------------------------------------------------------------------------------------------------------------------#
resource "aws_s3_object" "imagebuilder_build" {
  bucket = local.var["S3_SYSTEM_BUCKET"]
  key    = "imagebuilder/build.sh"
  source = "${abspath(path.root)}/scripts/build.sh"
  etag = filemd5("${abspath(path.root)}/scripts/build.sh")
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Upload ImageBuilder test script to s3 bucket
# # ---------------------------------------------------------------------------------------------------------------------#
resource "aws_s3_object" "imagebuilder_test" {
  bucket = local.var["S3_SYSTEM_BUCKET"]
  key    = "imagebuilder/test.sh"
  source = "${abspath(path.root)}/scripts/test.sh"
  etag = filemd5("${abspath(path.root)}/scripts/test.sh")
}

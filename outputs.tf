output "codebuild_role_arn" {
  value = "${aws_iam_role.codebuild.arn}"
}

output "codepipeline_role_arn" {
  value = "${aws_iam_role.codepipeline.arn}"
}

output "codepipeline_role_name" {
  value = "${aws_iam_role.codepipeline.name}"
}

output "terraform_role_arn" {
  value = "${aws_iam_role.terraform.arn}"
}

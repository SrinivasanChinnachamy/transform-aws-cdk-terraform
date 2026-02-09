# Migrate AWS CDK Python to Terraform HCL

## Objective
Transform AWS Cloud Development Kit (CDK) infrastructure code written in Python into HashiCorp Terraform HCL configuration files, enabling cloud-agnostic infrastructure management with declarative syntax and state-based resource tracking.

## Summary
This transformation converts Python-based CDK constructs and stacks into equivalent Terraform HCL resource definitions. The process involves mapping CDK construct patterns to Terraform resource blocks, converting Python syntax to HCL syntax, translating CDK-specific abstractions to explicit Terraform resources, transforming CDK properties and configurations to Terraform arguments, and establishing proper Terraform module structure with state management.

## Entry Criteria
1. The codebase contains AWS CDK Python applications with Stack and Construct definitions
2. CDK code uses `aws_cdk` library imports and defines infrastructure resources
3. The project has a CDK app entry point (typically `app.py` or similar)
4. Infrastructure is currently deployed or deployable using CDK CLI commands
5. CDK stacks contain AWS resource definitions using L1 (CloudFormation) or L2 (construct) patterns

## Implementation Steps

<possible_quality_improvement>
Note: Specific CDK construct to Terraform resource mappings would be more precise with example CDK code showing the actual constructs being used (e.g., ec2.Vpc, s3.Bucket, lambda.Function patterns).
</possible_quality_improvement>

1. Identify all CDK Stack classes in the Python codebase and create corresponding Terraform root modules or child modules for each stack
2. Map CDK construct imports (e.g., `aws_cdk.aws_s3`, `aws_cdk.aws_ec2`) to equivalent Terraform AWS provider resource types (e.g., `aws_s3_bucket`, `aws_vpc`)
3. Convert CDK L2 construct instantiations to Terraform resource blocks, translating construct properties to resource arguments using HCL syntax
4. Transform CDK L1 (CloudFormation) constructs to their corresponding Terraform resource equivalents, mapping CloudFormation properties to Terraform arguments
5. Replace CDK property references and construct attributes (e.g., `bucket.bucket_name`) with Terraform attribute references (e.g., `aws_s3_bucket.example.id`)
6. Convert CDK stack parameters and context values to Terraform input variables with appropriate type constraints and default values
7. Transform CDK outputs to Terraform output values, maintaining the same export structure
8. Replace CDK resource dependencies (implicit through construct references) with explicit Terraform `depends_on` where necessary
9. Convert CDK aspects, custom resources, and escape hatches to equivalent Terraform provisioners, null resources, or external data sources
10. Create Terraform backend configuration for state management (replacing CDK's CloudFormation-based state)
11. Establish Terraform provider configuration with appropriate AWS region and credential settings
12. Convert CDK bundled Lambda functions and assets to Terraform archive data sources or separate build processes
13. Transform CDK tagging strategies to Terraform default tags or explicit resource tags
14. Replace CDK removal policies with Terraform lifecycle rules (prevent_destroy, create_before_destroy)

<possible_quality_improvement>
Note: More specific validation criteria could be provided with knowledge of the CDK project's deployment patterns, test structure, and specific AWS services being used.
</possible_quality_improvement>

## Validation / Exit Criteria
1. All CDK Stack classes have been converted to Terraform modules with proper directory structure
2. Running `terraform init` successfully initializes the Terraform configuration without errors
3. Running `terraform plan` generates an execution plan without syntax or validation errors
4. The Terraform plan shows resources that match the AWS resources currently managed by CDK stacks
5. All CDK construct properties have corresponding Terraform resource arguments defined
6. Resource dependencies are correctly expressed through attribute references or explicit depends_on declarations
7. Input variables and outputs maintain the same interface as CDK parameters and outputs
8. Lambda functions and other assets are properly packaged and referenced in Terraform configuration
9. Terraform state backend is configured and accessible
10. All custom logic previously in CDK (aspects, custom resources) has equivalent implementation in Terraform

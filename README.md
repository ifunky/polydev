# PolyDev

"Poly" - Comes from the Greek word which means many. PolyDev contains a mixture of best practice development and infrastructure tools that can be used locally and as part of a CI/CD process.

**Why PolyDev?**

- Security - Use best practices with IAM Assume Role, no clear text keys
- Consistency - Just spin up a container and use the right tool versions
- Extensible - Use the tools the way you want or add new ones

**What Can I do With PolyDev?**
- Use it locally instead of installing lots of individual tools
- Use it in your CI infrastructure pipeline

**Features**

- Uses Docker-out-of-Docker which uses your host docker installation with just the cli tools running in the tooling container
- Mounts your `.ssh` and `.aws` folders
- Mounts the current folder to `/data` within the running container

**What's in the box?**

Languages

- Python v3.10.5
- Ruby v3.1.2
- Go 1.18.6
- Node v17.9.1 (npm)
-> Why multiple languages? This enables us to use best of breed tools regardless of what they're written in.

## Tools

**Wiz-Cli**

Wiz-cli is a locally deployed command line tool that helps you detect and prevent security misconfigurations and vulnerabilities early in the development cycle.

**Terraform**

Our tool of choice for infrastructure as code.

**TFLint**

Tool for linting Terraform code.

**Checkov**

Static code analysis tool for infrastructure-as-code for security best practices

**Conftest**

Utility to help you write tests against structured configuration data.

**Terraform-Inspect-Config**

Helper library for extracting high-level metadata about Terraform modules from their source code.

https://github.com/hashicorp/terraform-config-inspect

**AWS CLI V2**

AWS command line tool (with bash auto) if we need to do any adhoc checks

**TFSec (https://github.com/liamg/tfsec)**

Performs basic Terraform static code analysis. This isn't the strongest tool but covers some basics, TerraScan would be better but the setup wasn't easy. To be revisited.

**Inspec**

Multi cloud testing tool for continuous compliance and testing of infrastructure

**Yeoman**

A scafolding framework used for creating new projects.

https://yeoman.io/

**Gomplate**

Gomplate is a template renderer which supports a growing list of datasources, such as: JSON (including EJSON - encrypted JSON), YAML, AWS EC2 metadata, BoltDB, Hashicorp Consul and Hashicorp Vault secrets.

https://github.com/hairyhenderson/gomplate

**Boto3**
Python 3 AWS framework

**YamlLint**
Python YAML linting tool

**Packer**
Hashicorp Packer for building images

**Helm**
K8S packaging manager

**Kubectl**
Command line tool for controlling Kubernetes clusters

**AWS-IAM-Authenticator**
A tool to use AWS IAM credentials to authenticate to a Kubernetes cluster

## Getting Started

**Optional Local Setup (IAM Keys)**

If you're still using IAM keys then the following workflow provides a secure process to use PolyDev locally whilst not exposing IAM credentials.
 
We've tried to keep the setup minimal so here are the pre-requisites to get going with PolyDev. Primarily this has been designed to be run under Linux/Mac but will also work on Windows.

**Windows**

1.  **WSL** - Follow the offical guide here: [https://docs.microsoft.com/en-us/windows/wsl/install-win10](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

2.  **Docker** - Install Docker Community addition and setup with WSL: [https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly](https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly). Also see https://code.visualstudio.com/docs/remote/troubleshooting#_docker-desktop-for-windows-tips for troubleshooting local docker file sharing issues.

3.  **AWS-Vault** - In WSL run the following to install AWS-Vault
    $ sudo curl -L -o /usr/local/bin/aws-vault https://github.com/99designs/aws-    vault/releases/download/v4.5.1/aws-vault-linux-amd64
    $ sudo chmod 755 /usr/local/bin/aws-vault

  **MAC**

    brew cask install aws-vault

**Configuring AWS-Vault**

AWS-Vault is used to store encrypted AWS keys using the operating systems keystore which is also configured for assuming IAM roles. This ensures we never expose keys in clear text and gives an additional benefit of only using short lived sessions.

The key concept is that you will have one basic non privileged IAM user and from this login you will have been granted access to other accounts via IAM roles that you can assume.
You can create multiple profiles for each account that you have IAM roles in, for example below will create a basic profile and additional profiles for each available role ([https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html))

**Create Basic AWS-Vault Profile**

In a bash session run the following changing the names as appropriate:

    $ aws-vault add ifunky_readonly
Follow the prompts to enter your AWS keyss.  These will be encrypted in your OS keystore
  
**Create Role Profiles**

Now we'll setup some additional role profiles:

    $ vi ~/.aws/config
    
    [profile ifunky_readonly]
    region=eu-west-1
    output=json
    
    [profile ifunky_prod]
    source_profile=ifunky_readonly
    role_arn=arn:aws:iam::626351345541:role/pipeline-engineer
    mfa_serial=YOUR_MFA_ARN

> For more info and usage guide see: [https://github.com/99designs/aws-vault](https://github.com/99designs/aws-vault)
>
> NOTE : The above setup is based on using IAM users with minimal access combined with roles that can be assumed

## Using PolyDev
Here are some examples of using PolyDev as part of your day to day routine.
 - The current folder where you run the commands are mounted to */data*
 - Your *.ssh* folder is mounted in the running container

**AWS Command Line**

In this scenario you might just need to run some AWS CLI commands.
From any folder run the following:

    $ aws-vault exec --duration 1h ifunky_prod -- \                                                                                                                                                                            
            docker run -it --rm \
            -e AWS_ACCESS_KEY_ID \
            -e AWS_SECRET_ACCESS_KEY \
            -e AWS_SESSION_TOKEN \
            -e AWS_SECURITY_TOKEN \
            -e AWS_DEFAULT_REGION=eu-west-1 \
            -v "$PWD:/data" \
            -v ~/.ssh:/root/.ssh \
            -v ~/.kube:/root/.kube \
            -v ~/.aws:/root/.aws \
            -v /var/run/docker.sock:/var/run/docker.sock \
            ifunky/polydev:latest
Once in the PolyDev shell start typing AWS commands - with tab completion :-)

    aws s3 ls

**Terraform Workflow**

In this scenario you can use PolyDev to perform Terraform linting, validation during module development.  You could also run Terraform apply but we don't recommend this and rather a CI/CD pipeline should be implemented.

From your Terraform folder enter the PolyDev shell and run Terraform commands:

    $ cd /projects/my_terraform_module
    $ aws-vault exec --duration 1h ifunky_prod -- \                                                                                                                                                                            
                docker run -it --rm \
                -e AWS_ACCESS_KEY_ID \
                -e AWS_SECRET_ACCESS_KEY \
                -e AWS_SESSION_TOKEN \
                -e AWS_SECURITY_TOKEN \
                --env AWS_DEFAULT_REGION=eu-west-1 \
                --user "$(id -u):$(id -g)" \
                -v "$PWD:/data" \
                -v ~/.ssh:/root/.ssh \
                ifunky/polydev:latest

    $ terraform init
    $ terraform validate
    $ tflint --aws-region=eu-west-1

> NOTE : It is recommended to wrap Terraform commands in a Makefile giving you a CI/CD tool agnostic way of creating a pipeline that can run Terraform

## Create a Shell Alias
To make your life easier create a shell alias, for example:

    $ vim ~/.zshrc
    function polydev() {
            aws-vault exec --duration 1h $1 -- \
            docker run -it --rm \
            -e AWS_ACCESS_KEY_ID \
            -e AWS_SECRET_ACCESS_KEY \
            -e AWS_SESSION_TOKEN \
            -e AWS_SECURITY_TOKEN \
            --env AWS_DEFAULT_REGION=eu-west-1 \
            -v "$PWD:/data" \
            -v ~/.ssh:/root/.ssh \
            ifunky/polydev:latest
    }
Then from your shell call `polydev` passing in the name of a profile from .aws/config:

    $ polydev ifunky_prod

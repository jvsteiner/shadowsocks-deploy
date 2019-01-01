# On demand shadowsocks proxy

Ever wanted to have an ip address which is somewhere else?  It's easy with shadowsocks - a proxy designed to traverse the great firewall of china.  But these services cost money, and maybe you only need to use it for an hour or so.  AWS makes it simple and cheap to spin up servers on demand, and only pay for what you use.  With this tool, you can spin up a temporary server, anywhere inside an aws datacenter and use it as a shadowsocks proxy.  Destroy it when you are done - only pay for what you use.  Coupla cents per hour... This guide is oriented towards OSX users.

## Installation

In order to use this script, some set up is required:

### AWS account

1. Sign up for a free AWS account.  The first 750 hours are free, and this script uses only resources which qualify for the free tier.
2. Go to `My Security Credentials` from the dropdown menu behind your username.
3. Click on `Access keys` then `Create new access key`.
4. Download the Key File, rename it `credentials` and place it in `~/.aws/`.

### SSH

1. Open the [EC2 dashboard](https://console.aws.amazon.com/ec2/). 
2. Under NETWORK & SECURITY, choose Key Pairs, then Create Key Pair. Note: you may generate the key pair locally, and upload the pubkey, if you don't trust Amazon.
3. Name the key `ssocks_key`. 
4. Save the key to `~/.ssh/ssocks_key.pem` and change its permissions to 400.
5. Separate the public key into a separate file, this can be done with: `ssh-keygen -y -f ~/.ssh/ssocks_key.pem > ~/.ssh/ssocks_key.pub`.
6. Keys are _per region_, so you must install the public key to each AWS region you wish to use. This is possible manually, but a little fiddly, therefore both manual and automatic options are provided below:
- Copy the pubkey to a place that will be convenient to find using the file upload dialog in your browser, ie. ~/Documents. Switch regions in the dashboard, and Import Key Pair, by uploading the pubkey.  Note: the fingerprint(s) of the uploaded key(s) does not match the original for some reason, however, I have found that the key will work.
- Install the `awscli` tool with `brew install awscli`. Then, issue the following command: `for region in us-east-1 us-east-2 us-west-1 us-west-2 ap-south-1 ap-northeast-2 ap-southeast-1 ap-southeast-2 ap-northeast-1 eu-central-1 eu-west-1 eu-west-2 eu-west-3 eu-north-1 ca-central-1 sa-east-1 ; do aws ec2 import-key-pair --key-name ssocks_key --public-key-material file://~/.ssh/ssocks_key.pub --region $region ; done`

### terraform

On OSX, the easiest way is simply:

```bash
$ brew install terraform
```

## Usage

```bash
$ git clone https://github.com/jvsteiner/shadowsocks-deploy.git
$ cd shadowsocks-deploy
$ terraform init
```

Some modules will be downloaded, etc.  Pick which aws datacenter you want to use, by uncommenting the line from the `deploy.tf` file.

```bash
$ terraform apply
```
You will have to confirm by typing `yes`. Deployment takes up to a couple of minutes. Once it is complete, your shadowsocks server is up and running, and its public dns entries will have been placed into `public_dns.txt`.

The included script, `ssh_to.sh` makes it easier to ssh into your new server.  Simply execute `./ssh_to` to login.  You don't need to do this, it's just in case you feel like poking around. 

Copy the dns entry from `public_dns.txt` and use it to configure your shadowsocks client.  Default shadowsocks configuration (which can be adjusted) is:

```json
{
    "server":"0.0.0.0",
    "server_port":443,
    "password":"supersecret",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open": true
}
```

Obviously, you should change the password in `scripts/provision.sh`.  You should also take care to configure your shadowsocks client to use the correct encryption mechanism and port, etc.  If you are here, I assume you already know what you are doing on the client side.

When you are done using your instance:

```bash
$ terraform destroy
```
You will have to confirm by typing `yes`. Destroys the server.

## bash script

you can also create a couple simple bash functions to trigger deployment/destruction - the following two lines should suffice, if entered into you `.bash_profile`:
```
ssup() { pd=`pwd`; cd ~/Code/shadowsocks-deploy; if [ -z ${1+x} ]; then terraform apply -auto-approve; else terraform apply -auto-approve -var "region=$1"; fi; cat public_dns.txt; cd $pd; }
ssdown() { pd=`pwd`; cd ~/Code/shadowsocks-deploy; terraform destroy -auto-approve; cd $pd; }
```

Usage:
```
ssup
ssdown
```

`ssup` accepts an optional aws region parameter, ie. `ssup eu-west-3` for Paris.  Default is `us-east-1` but this can be modified in `deploy.tf`

Note:  I take no responsibility for anything.  By downloading this code, you agree to use it at your own risk and expense.  If you
 run up a 7 million dollar AWS bill, don't come crying to me.  If my code kills your cat, same deal.  Have fun, stay safe, and be smart.

### Thanks

To the awesome people at [shadowsocks-go](https://github.com/shadowsocks/shadowsocks-go)

Your code works, and installs much more easily than the python version - this made my life 10x easier in doing this.


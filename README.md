# AWS/Chef Missing tools
Random bucket of tools

#Install
```bash
bundle install
```

# Monitoring
## monitoring/elb.rb

Examples:
```
./elb.rb list
./elb.rb list -r demo
./elb.rb list -r "^dev-"
./elb.rb details -r "^dev-"
./elb remove -n dumm -i i-b4b2b451
./elb add -n dumm -i i-b4344451
./elb refresh -n dumm
./elb refresh --name dumm
```


# Clean-up
## cleanup/clean_chef_nodes.rb
Removes node and client from Chef server and also delete any created Route53 for each server.
How to use it?!
Make sure you have the credentials setup:
```bash
export AWS_ACCESS_KEY_ID='Q1W...'
export AWS_SECRET_ACCESS_KEY="3E4..."
export REPO=/path_to/repo
export HOSTED_ZONE_ID='Q1W2E3R4T5Y6YU'
export DOMAIN="example.com"
```
Run this to see nodes : ``` ruby clean_chef_nodes.rb ```
Run this to kill nodes: ``` ruby clean_chef_nodes.rb kill ```


## cleanup/clean_ebs_volumes.rb
Removes all 'available', a.k.a. 'not being used', volumes
How to use it?!
Make sure you have the credentials setup:
```bash
export AWS_ACCESS_KEY_ID='Q1W...'
export AWS_SECRET_ACCESS_KEY="3E4..."
```
Run this to see nodes : ``` ruby clean_ebs_volumes.rb ```

Run this to kill nodes: ``` ruby clean_ebs_volumes.rb delete ```

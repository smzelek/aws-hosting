## Setup haproxy ec2 instance
```bash
# test reachability of ECS DNS Target (inside haproxy server)
dig SRV _guildvaults-com.internal 
curl -H "Host: guildvaults.com" 080426da70864a0eb482d04dc90534af._guildvaults-com.internal:32774/elb-status
```

```bash
# test reachability of ECS DNS Target (externally, via haproxy server)
curl -H "Host: guildvaults.com" http://ec2-184-73-164-112.compute-1.amazonaws.com/elb-status

```

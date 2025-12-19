# Monitoring, Logging and Runtime Security

- Perform behaviour analytics of syscalls
- Goal is to be notified as soon as it occurs - to various notification channels
  - Use Falco https://falco.org/ from Sysdig https://www.sysdig.com/
- example of malicious activities

```bash
$ kubectl exec -it nginx-master -- bash
# stores encrypted user passwords and account aging info (like password change dates, expiration warnings) 
# cat /etc/shadow

# remove records from the audit log to erase proof
cat /opt/logs/audit.log  
```


### CKA tips

```bash
alias k=kubectl
export do="--dry-run=client -o yaml"
k run pod1 --image=nginx $do
```


```bash
cat << EOF >> file-name.yml
<copy-paste here>
EOF
```

```bash
$ kubectl get svc web-frontend-svc -n web -o jsonpath='{.spec.selector.app}{.spec.type}' 2>&1
```

'>&' is the syntax to redirect a stream to another file descriptor:
0 is stdin
1 is stdout
2 is stderr

To redirect stderr to stdout:

`echo test 2>&1`

 
```bash
// check if previous command failed or not
echo $?
// 0 means no failure
// anything non 0 means failure 
```
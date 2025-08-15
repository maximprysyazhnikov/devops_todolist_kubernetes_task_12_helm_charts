# INSTRUCTION

## Deploy
```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

## Validate
- Taints & labels:
```bash
kubectl get nodes --show-labels
kubectl describe node $(kubectl get nodes -l app=mysql -o name | sed 's#node/##')
```
- Resources:
```bash
kubectl -n todoapp get all,cm,secret,ing,hpa
kubectl -n mysql get all,cm,secret
```
- Output file for CI:
```bash
cat output.log
```

helm template joplin services/joplin `
    -f services/joplin/values-secret.yaml `
    --output-dir tmp
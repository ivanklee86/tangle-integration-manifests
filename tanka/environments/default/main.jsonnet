{
  configMap: {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: { name: 'tanka-fixture' },
    data: {
      greeting: 'hello',
      removed: 'soon',
    },
  },
}

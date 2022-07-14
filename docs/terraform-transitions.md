# Terraform state transitions

Terraform tries not to delete or overwrite something that it didn't create in
the first place.  It does this by storing the current 'state' of objects that it
did create.  When an object is later removed from the config, but is still in
the 'state', then Terraform will delete it.  But if an object exists in reality
and not in the 'state', then Terraform will leave it be.

```mermaid
graph LR
    A[N: config<br/>N: state<br/>N reality] -->|Nothing to do| B(N: config<br/>N state<br/>N: reality)
    C[Y: config<br/>N: state<br/>N reality] -->|Create| D(Y: config<br/>Y state<br/>Y: reality)
    E[N: config<br/>Y: state<br/>N reality] -->|Someone manually deleted it,<br/>and also removed it from the config.| F(?)
    G[N: config<br/>N: state<br/>Y reality] -->|Ignore| H(N: config<br/>N state<br/>Y: reality)
    I[Y: config<br/>Y: state<br/>N reality] -->|Recreate?<br/>Someone manually deleted it.| D
    K[Y: config<br/>N: state<br/>Y reality] -->|Ask the user to import it into the state.| D
    M[N: config<br/>Y: state<br/>Y reality] -->|Delete| N(N: config<br/>N state<br/>N: reality)
    O[Y: config<br/>Y: state<br/>Y reality] -->|Nothing to do| P(Y: config<br/>Y state<br/>Y: reality)
```

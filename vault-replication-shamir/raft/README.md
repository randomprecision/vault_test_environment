## What is this? 

This is a basic 5 node raft cluster using shamir. It's good for setting up DR replications that don't require consul. 

Sample setup: 

cluster 1:
vault_alpha (vault_primary)
vault_bravo (vault_secondary) 

cluster 2: (DR PR whatever) 
vault_charlie 
vault_delta

Then you have vault_echo as a 5th vault node that you can use to set up transit unseal or use as a CA. This vagrant environment is experimental, as is the nginx subdirectory which will make an nginx host for these nodes with simple load balancing in place for 8200. 

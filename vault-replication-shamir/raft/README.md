* What is this? *

This is a basic 4 node raft cluster using shamir. It's good for setting up DR replications that don't require consul. 

Sample setup: 

cluster 1:
vault_alpha (vault_primary)
vault_bravo (vault_secondary) 

cluster 2: (DR PR whatever) 
vault_charlie 
vault_delta

There is still a lot of cruft I need to get out of this.

# Decision Token Sale
This is the Decision Token (HST) contract, alongside the Decision Token Sale contract.
The sale's contract is used both for a whitelist-powered pre-sale (where only
whitelisted addresses may purchase tokens before the 'start time') and the sale
itself, which runs between start and end times as provided to the contract on
creation.
The Decision Token contract itself is locked for transfers for 10 days after the token
sale ends.
Decision Tokens are minted on demand, up to a cap of 1 billion tokens. The contract
does not support partial purchases, and if the number of tokens calculated for the
amount of wei used in the buy results in going over the token cap - then the purchase
will be rejected.

### The Rate of Tokens Per ETH
The number of tokens minted per ETH changes with the number of days passed since the
beginning of the sale.
  - Presale and day 1: 3500 tokens per ETH
  - Days 2-8: 3250 tokens per ETH
  - Days 9-end-of-sale: 3000 tokens per ETH

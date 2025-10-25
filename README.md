# CreativeTrace Smart Contract - Deployment & Usage Guide

## Overview
This Clarity smart contract implements the core functionality of the CreativeTrace platform on the Stacks blockchain.

## Features Implemented

### 1. **Creator Management**
- Creator registration with unique IDs
- Reputation scoring system
- Creator verification (KYC-like)
- Reputation token staking

### 2. **Provenance Tracking**
- Immutable provenance hash storage (for IoT sensor data)
- Authenticity scoring
- Creation timestamp recording
- Edition tracking

### 3. **Creative Works NFT System**
- Limited edition minting
- Dynamic royalty support
- Collaborative attribution
- Revenue tracking

### 4. **Market Analytics**
- Engagement scoring
- Social sentiment tracking
- Cultural impact measurement
- Trend analysis

### 5. **Smart Royalty Distribution**
- Automatic royalty payments on secondary sales
- Platform fee deduction
- Support for multiple collaborators

## Contract Functions

### Creator Functions

#### `register-creator`
Register as a creator on the platform.
```clarity
(contract-call? .creative-trace register-creator)
```
Returns: Creator ID

#### `verify-creator`
Verify a creator (owner only).
```clarity
(contract-call? .creative-trace verify-creator 'ST1CREATOR...)
```

#### `stake-reputation`
Stake reputation tokens.
```clarity
(contract-call? .creative-trace stake-reputation u100)
```

### Creative Work Functions

#### `create-work`
Create a new creative work with provenance data.
```clarity
(contract-call? .creative-trace create-work 
    "My Amazing Artwork"
    0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
    u95  ;; authenticity score (0-100)
    u1000  ;; 10% royalty
    u100  ;; 100 editions
)
```
Returns: Work ID

#### `add-collaborator`
Add a collaborator to a work.
```clarity
(contract-call? .creative-trace add-collaborator 
    u1  ;; work-id
    'ST1COLLABORATOR...
    u2500  ;; 25% contribution
    "Co-Artist"
)
```

#### `mint-edition`
Purchase/mint an edition of a work.
```clarity
(contract-call? .creative-trace mint-edition 
    u1  ;; work-id
    u1000000  ;; price in microSTX (1 STX)
)
```
Returns: Edition number

#### `transfer-ownership`
Transfer ownership of an edition (secondary sale).
```clarity
(contract-call? .creative-trace transfer-ownership 
    u1  ;; work-id
    u1  ;; edition number
    'ST1NEWOWNER...
    u1500000  ;; sale price in microSTX (1.5 STX)
)
```

#### `deactivate-work`
Deactivate a work (creator only).
```clarity
(contract-call? .creative-trace deactivate-work u1)
```

### Analytics Functions

#### `update-analytics`
Update market analytics for a work (owner/validator only).
```clarity
(contract-call? .creative-trace update-analytics 
    u1  ;; work-id
    u850  ;; engagement score
    u720  ;; social sentiment
    u900  ;; cultural impact
    u780  ;; trend score
)
```

### Read-Only Functions

#### Query Functions
```clarity
;; Get creator info
(contract-call? .creative-trace get-creator 'ST1CREATOR...)

;; Get work details
(contract-call? .creative-trace get-creative-work u1)

;; Get edition owner
(contract-call? .creative-trace get-work-owner u1 u1)

;; Get collaborator info
(contract-call? .creative-trace get-collaborator u1 'ST1COLLABORATOR...)

;; Get work analytics
(contract-call? .creative-trace get-work-analytics u1)

;; Get platform fee
(contract-call? .creative-trace get-platform-fee)

;; Get reputation stake
(contract-call? .creative-trace get-reputation-stake 'ST1CREATOR...)
```

## Deployment Instructions

### Using Clarinet (Recommended)

1. **Install Clarinet**
```bash
curl -L https://github.com/hirosystems/clarinet/releases/download/latest/clarinet-linux-x64.tar.gz | tar xz
```

2. **Create New Project**
```bash
clarinet new creative-trace-project
cd creative-trace-project
```

3. **Add Contract**
```bash
cp creative-trace.clar contracts/
```

4. **Update Clarinet.toml**
```toml
[contracts.creative-trace]
path = "contracts/creative-trace.clar"
```

5. **Test Contract**
```bash
clarinet check
```

6. **Deploy to Testnet**
```bash
clarinet deploy --testnet
```

### Using Stacks CLI

```bash
stx deploy_contract creative-trace creative-trace.clar \
    --testnet \
    --private-key YOUR_PRIVATE_KEY
```

## Usage Examples

### Example 1: Complete Artist Workflow

```clarity
;; 1. Register as creator
(contract-call? .creative-trace register-creator)
;; Returns: (ok u1)

;; 2. Create a work
(contract-call? .creative-trace create-work 
    "Digital Sunrise"
    0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890
    u98
    u500  ;; 5% royalty
    u50
)
;; Returns: (ok u1)

;; 3. Mint first edition
(contract-call? .creative-trace mint-edition u1 u5000000)
;; Returns: (ok u1)
```

### Example 2: Collaborative Work

```clarity
;; 1. Create work as main artist
(contract-call? .creative-trace create-work 
    "Collaborative Masterpiece"
    0x1111111111111111111111111111111111111111111111111111111111111111
    u99
    u1000
    u25
)

;; 2. Add collaborators
(contract-call? .creative-trace add-collaborator u2 'ST1COLLAB1... u3000 "Lead Artist")
(contract-call? .creative-trace add-collaborator u2 'ST1COLLAB2... u2000 "Sound Designer")
```

### Example 3: Secondary Market Sale

```clarity
;; Transfer ownership with automatic royalty distribution
(contract-call? .creative-trace transfer-ownership 
    u1  ;; work-id
    u1  ;; edition
    'ST1BUYER...
    u10000000  ;; 10 STX
)
;; Automatically distributes:
;; - 5% royalty to original creator
;; - 2.5% platform fee
;; - 92.5% to seller
```

## Key Constants & Error Codes

### Error Codes
- `u100`: Owner only
- `u101`: Not found
- `u102`: Already exists
- `u103`: Unauthorized
- `u104`: Invalid amount
- `u105`: Transfer failed
- `u106`: Invalid percentage

### Basis Points
- Percentages use basis points (1% = 100, 100% = 10000)
- Example: `u1000` = 10%, `u250` = 2.5%

## Security Considerations

1. **Provenance Hash**: Store actual IoT sensor data off-chain (IPFS/Arweave), only hash on-chain
2. **Reputation Staking**: Implement slashing mechanism for fraudulent authenticity claims
3. **Validator Network**: Expand authorization beyond contract owner for production
4. **Price Oracle**: Consider integrating STX/USD price feeds for stable pricing

## Future Enhancements

1. **Physical-Digital Linkage**: Add IoT verification for physical item transfers
2. **Fractional Ownership**: Enable multiple owners per edition
3. **Dynamic Pricing**: Implement bonding curve pricing based on analytics
4. **DAO Governance**: Decentralize platform fee and policy decisions
5. **Cross-Chain Bridge**: Enable Ethereum/other chain compatibility

## Testing

Create test files in `tests/` directory:

```typescript
// tests/creative-trace_test.ts
import { Clarinet, Tx, Chain, Account } from 'https://deno.land/x/clarinet@v1.5.0/index.ts';

Clarinet.test({
    name: "Creator can register and create work",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const artist = accounts.get("wallet_1")!;
        
        let block = chain.mineBlock([
            Tx.contractCall("creative-trace", "register-creator", [], artist.address),
            Tx.contractCall("creative-trace", "create-work", [
                '"Test Art"',
                '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
                'u95',
                'u1000',
                'u10'
            ], artist.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        block.receipts[1].result.expectOk().expectUint(1);
    }
});
```

## License
MIT License - Feel free to use and modify

## Support
For issues or questions, refer to the Stacks documentation: https://docs.stacks.co/

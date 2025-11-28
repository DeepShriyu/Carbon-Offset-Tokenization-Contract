# CarbonOffsetTokenization.sol

## Overview

`CarbonOffsetTokenization` is a simple ERC20‑like smart contract for issuing and retiring tokenized carbon offsets on Ethereum‑compatible blockchains.[1][2]
Each token represents one unit of verified carbon offset (for example, one tonne of CO₂e), and retiring a token permanently removes it from circulation to reflect an actual offset claim.[3][1]

This contract is **not** a full compliance solution. Real deployments must integrate with off‑chain registries, MRV processes, and legal frameworks for carbon markets.[4][2]

***

## Key Features

- **Fungible carbon offset token**
  - ERC20‑like interface (`transfer`, `transferFrom`, `approve`, `allowance`, `balanceOf`, `totalSupply`).  
  - `name = "Carbon Offset Token"`, `symbol = "COFF"`, `decimals = 18`.

- **Controlled issuance (minting)**
  - `mint(address to, uint256 amount, string projectRef)`  
  - Only authorized **minters** (e.g., registries/verifiers) can mint new tokens after verifying underlying carbon credits.[5][6]
  - `projectRef` can store a reference to an off‑chain certificate or registry entry (standard ID, URL, or IPFS hash).

- **Offset / retirement (burn)**
  - `retire(uint256 amount, string retireeId, string projectRef)`  
  - Burns tokens from caller balance, increasing `totalRetired` while decreasing `totalSupply` to prevent reuse or resale.[1][3]
  - Stores a detailed `Retirement` record for each retire action:
    - `amount`
    - `retireeId` (e.g., company ID, account code)
    - `projectRef` (which project/credit was used)
    - `timestamp`

- **Transparency and auditability**
  - `getRetirementsOf(address)` returns all retirement records for an address, enabling public audit trails of who retired what, when, and for which project.[2][7]
  - `totalRetired` tracks global retired supply.

- **Role‑based access control**
  - `isMinter[address]` mapping with:
    - `setMinter(address minter, bool approved)` for owner‑controlled minter management.  
  - `owner` can be transferred via `transferOwnership(address)`.

***

## Contract API (High Level)

### ERC20‑like

- `function totalSupply() external view returns (uint256);`  
- `function balanceOf(address account) external view returns (uint256);`  
- `function transfer(address to, uint256 value) external returns (bool);`  
- `function approve(address spender, uint256 value) external returns (bool);`  
- `function allowance(address owner, address spender) external view returns (uint256);`  
- `function transferFrom(address from, address to, uint256 value) external returns (bool);`

### Carbon‑specific

- `function mint(address to, uint256 amount, string calldata projectRef) external onlyMinter;`  
- `function retire(uint256 amount, string calldata retireeId, string calldata projectRef) external;`  
- `function getRetirementsOf(address account) external view returns (Retirement[] memory);`  
- `function totalRetired() external view returns (uint256);`

### Administration

- `function setMinter(address minter, bool approved) external onlyOwner;`  
- `function transferOwnership(address newOwner) external onlyOwner;`

***

## Example Flows

### 1. Issuing new carbon credits

1. Verifier/registry checks an off‑chain project and credits (per its own process).[8][6]
2. Owner calls `setMinter(verifier, true)`.  
3. Verifier calls `mint(beneficiary, amount, projectRef)`.  
4. Beneficiary receives fungible COFF tokens that can be held or transferred.

### 2. Offsetting emissions (retiring tokens)

1. Corporate/user accumulates COFF tokens.  
2. Calls `retire(amount, retireeId, projectRef)` from their address.  
3. Tokens are burned; `totalSupply` decreases and `totalRetired` increases.  
4. A `Retired` event and a `Retirement` record are stored on‑chain for audit and reporting.[3][1]

***

## Security & Integration Notes

- This contract **does not**:
  - Verify that off‑chain credits exist or prevent double‑counting across external registries.  
  - Implement KYC/AML or jurisdiction‑specific compliance.  
- Recommended for production:
  - Integrate with trusted carbon registries and MRV providers via oracles or backend systems.[9][6]
  - Add pausing, upgradability, and role‑management modules as appropriate.  
  - Undergo thorough auditing and legal review before real‑world use.[10][4]

***

## Development & Testing

- Solidity version: `^0.8.19` or compatible.  
- Typical toolchains:
  - Hardhat or Foundry for compilation and testing.  
  - Scripts to:
    - Deploy the contract.
    - Configure minters.
    - Mint sample tokens and simulate retirements with different `projectRef` values.
Contract Adress 0x2b9C91f10a87c161ea845E4E78F8d6ffd067519B
<img width="1919" height="928" alt="image (1)" src="https://github.com/user-attachments/assets/37653ace-0246-4f6d-89c1-359f4d2e4a04" />

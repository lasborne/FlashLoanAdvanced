# Aave FlashLoan/Compound DeFi Contract

This Project simply borrows funds via FlashLoan on Aave, supply and withdraw from Compound and pay back the funds to Aave, all in one transaction. This is a more complex variant of the Aave FlashLoan implemented by FlashLoaning USDbC tokens on Base mainnet,supplying the Borrowed funds to Compound comet, withdrawing said borrow amount and returning back the FlashLoan to the Aave pool (Note that this is done by approving the Aave pool to spend said funds and having the said amount + 0.05% premium, Aave POOL has the built-in mechanism to automatically withdraw the said). The project contains Javascript code that deploys the contract and contains functions for flashLoan (with lend, withdraw, and few other logic contained beneath). The approval amount must be set to type(uint256).max, else, the approve transaction fails. (Not that claiming rewards function works successfully but does not accrue any COMP rewards; i.e. accruedRewards is 0, therefore nothing is realistically claimed; This is subject to further testing by the ADMIN of this project).

usdbcMainAddress = '0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA', cometMainAddress (on Base mainnet) = '0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf' DeFiInteractionAddress (created) = '0xA921C59E2505186aCFd36425b151FC41468Cb3a7', AavePoolAddressesProvider = '0xe20fCBdBfFC4Dd138cE8b2E6FBb6CB49777ad64D'

Try editing the flashLoan.js script and deploy first by (if deploying is necessary).

npx hardhat run scripts/flashLoan.js --network base

Try running some of the following tasks:

npx hardhat help 
npx hardhat node 
npx hardhat run scripts/flashLoan.js --network base

Special credits to Compound V3 docs = 'https://docs.compound.finance'.
Special credits to Aave V3 docs = 'https://aave.com/docs/resources/addresses'.
Credits to DAPP University and a host of other online useful resourses.

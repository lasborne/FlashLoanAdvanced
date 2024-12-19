const { ethers } = require('hardhat');

// Aave Base Addresses
const usdbcAddress = '0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA'
const poolAddressProvider = '0xe20fCBdBfFC4Dd138cE8b2E6FBb6CB49777ad64D'
// Compound V3
const cometAddress = '0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf'
const compAddress = '0x9e1028F5F1D5eDE59748FFceE5532509976840E0'
const cometRewards = '0x123964802e6ABabBE1Bc9547D72Ef1B69B00A6b1'

//deployedFlashLoanContractAddr = '0x2c1cFaC977A00d607c37508486A9b1374A6B6939'

let FlashLoanContractDeploy = {

    /** 
     * @dev Deploy the Flash loan contract.
     * This is the Flash loan contract and must be implemented first. 
     * Simply deploys the flash loan contract from Aave v3.
     * 
     * Requirements:
     * 
     */
    deploy: async function deployFlashLoanContract() {
        let deployer, flashLoanContract
        [deployer] = await ethers.getSigners()

        let FlashLoanContract = await ethers.getContractFactory(
            'FlashLoan', deployer
        )
        
        flashLoanContract = await FlashLoanContract.deploy(
            poolAddressProvider, usdbcAddress, cometAddress,
            cometRewards, compAddress
        )
        await flashLoanContract.deployed()
        console.log(flashLoanContract.address)
        return flashLoanContract
    }
}

let FlashLoan = {

    /** 
     * @dev Execute FlashLoan. 
     * Execute the flash loan on Aave V3 on Fantom mainnet to borrow 10 DAI.
     * 
     * Requirements:
     * Should pay back within the same transaction.
     * 
     */
    flashLoan: async function flashLoanFunction(flashLoanContractAddress) {
        let deployer_, flashLoanContract
        [deployer_] = await ethers.getSigners()
        let amount = ethers.utils.parseEther('10')
        let amount_ = ethers.utils.parseUnits('10000000', 'wei')
        let premium = ethers.utils.parseEther('0.005')

        let FlashLoanContract = await ethers.getContractFactory('FlashLoan')
        
        flashLoanContract = FlashLoanContract.attach(flashLoanContractAddress)
        await flashLoanContract.connect(deployer_).functions.flashLoan(
            amount_, {
                gasLimit: 800000,
                gasPrice: Number(ethers.utils.parseUnits('0.04', 'gwei'))
            }
        )
        console.log(deployer_.address)
    },

    withdraw: async function withdrawAllBorrowedFunds(flashLoanContractAddress) {
        let deployer_, flashLoanContract
        [deployer_] = await ethers.getSigners()

        let FlashLoanContract = await ethers.getContractFactory('FlashLoan')
        
        flashLoanContract = FlashLoanContract.attach(flashLoanContractAddress)
        await flashLoanContract.connect(deployer_).functions.withdrawFunds()
    }
}

Main = async() => {
    // Deploy FlashLoan Contract.
    //await FlashLoanContractDeploy.deploy()

    // Perform the actual Flash Loan on Aave v3 Fantom using DAI as loaned token
    await FlashLoan.flashLoan('0xA921C59E2505186aCFd36425b151FC41468Cb3a7')
    //await FlashLoan.withdraw('0xA921C59E2505186aCFd36425b151FC41468Cb3a7')
    // YieldFarmAddr = 0x79D819e7A1f50cF12B3703025dd9Ae8d799C70a5
}

Main()
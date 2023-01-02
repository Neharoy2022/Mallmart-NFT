const hre = require("hardhat")

async function main() {
    const Lock = hre.ethers.getContractFactory("Lock")
    const lock = await Lock.deploy()
    await lock.deployed()

    console.log(`Lock with 1 Eth and unlock timestamp ${unlockTime} deployed to ${lock.address}`)
}

main().catch((error) => {
    console.error(error)
    process.exitcode = 1
})

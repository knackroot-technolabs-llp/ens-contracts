const { ethers } = require("hardhat");

const ZERO_HASH = '0x0000000000000000000000000000000000000000000000000000000000000000';

module.exports = async ({getNamedAccounts, deployments, network}) => {
    const {deploy} = deployments;
    const {deployer, owner} = await getNamedAccounts();

    // TODO: do not use it for priduction. Use actual oracle instead
    const dummyOracleEthPrice = 3200; // USD  // price mul 1e8

    const dummyPracle = await deploy('DummyOracle', {
        from: deployer,
        args: [dummyOracleEthPrice],
        log: true
    });

    console.log(`### DummyOracle deployed at ${dummyPracle.address}`);
    // TODO: set actual price. can be changed later on
    const prices = [500000, 120000, 4000]; // price mul 1e8 e.g. 5000 * 1e2

    const stablePriceOracle = await deploy('StablePriceOracle', {
        from: deployer,
        args: [dummyPracle.address, prices],
        log: true
    });

    console.log(`### StablePriceOracle deployed at ${stablePriceOracle.address}`);

    return true;
};
module.exports.tags = ['StablePriceOracle'];
module.exports.id = "StablePriceOracle";
